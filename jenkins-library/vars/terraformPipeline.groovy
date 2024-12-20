#!/usr/bin/env groovy

def call(Map config) {
    // Default values
    config.git_branch = config.git_branch ?: 'main'
    config.cloud_provider = config.cloud_provider ?: 'aws'
    config.terraform_module = config.terraform_module ?: 'false'
    config.cache_path = config.cache_path ?: '/var/jenkins_home/cache'

    pipeline {
        agent {
            kubernetes {
                yaml '''
                  apiVersion: v1
                  kind: Pod
                  spec:
                    containers:
                    - name: devops-tools
                      image: jansouza/devops-tools:latest
                      alwaysPullImage: true
                      command: ["sleep", "infinity"]
                      volumeMounts:
                        - name: jenkins-cache
                          mountPath: ${config.cache_path}
                    volumes:
                    - name: jenkins-cache
                      persistentVolumeClaim:
                        claimName: jenkins-cache-pvc
                '''
                defaultContainer 'devops-tools'
            }
        }
        //options {
        //    ansiColor('xterm')
        //}

        stages {
            stage('Checkout Source') {
                steps {
                    git branch: config.git_branch,
                        credentialsId: config.git_repo_cred,
                        url: config.git_repo
                }
            }

            stage('GitLeaks Scan') {
                steps {
                    sh """
                    gitleaks dir ${config.terraform_base_path} -v
                    """
                }
            }

            stage('Terraform TFLint') {
                steps {
                    sh """
                    mkdir -p ${config.cache_path}/tflint
                    export TFLINT_PLUGIN_DIR=${config.cache_path}/tflint
                    cd ${config.terraform_base_path}/
                    tflint --init
                    tflint --chdir=.
                    """
                }
            }
                
            stage('Terraform Init') {
                when {
                    expression {
                        return (config.terraform_module == 'false')
                    }
                }
                steps {
                    withCloudCredentials(config.cloud_provider, config.cloud_credentials) {
                        sh """
                        cd ${config.terraform_base_path}/
                        terraform init
                        terraform validate -no-color
                        """
                    }
                }
            }

            stage('Trivy Scan') {
                steps {
                    sh """
                    mkdir -p ${config.cache_path}/trivy
                    trivy config --cache-dir ${config.cache_path}/trivy --ignorefile ${config.terraform_base_path}/.trivyignore --format table --exit-code 1 --severity CRITICAL,HIGH ${config.terraform_base_path}
                    """
                }
            }

            stage('SonarQube Scan') {
                when {
                    expression {
                        return config.sonar_project_key?.trim()
                    }
                }
                steps {
                    withCredentials([
                        string(credentialsId: config.sonar_credentials_id, variable: 'SONAR_TOKEN')
                    ]) {
                        sh """
                        sonar-scanner -Dsonar.projectKey=${config.sonar_project_key} -Dsonar.branchname=${config.git_branch} -Dsonar.sources=${config.terraform_base_path}/ -Dsonar.host.url=${config.sonar_url} -Dsonar.qualitygate.wait=true -Dsonar.qualitygate.timeout=300
                        """
                    }
                }
            }

            stage('Terraform Plan') {
                 when {
                    expression {
                        return (config.terraform_module == 'false')
                    }
                }
                steps {
                    withCloudCredentials(config.cloud_provider, config.cloud_credentials) {
                        sh """
                        cd ${config.terraform_base_path}/
                        terraform plan -out tf-plan.out
                        terraform show -no-color tf-plan.out
                        """
                    }
                }
            }

            stage('Terraform Apply') {
                when {
                    expression {
                        return (config.git_branch == 'main' && config.terraform_module == 'false')
                    }
                }

                steps {
                    withCloudCredentials(config.cloud_provider, config.cloud_credentials) {
                        sh """
                        cd ${config.terraform_base_path}/
                    
                        terraform plan -out tf-plan.out
                        terraform show -no-color tf-plan.out
                        terraform apply tf-plan.out
                        """
                    }
                }
            }
        }
    }
}

def withCloudCredentials(String cloudProvider, Map credentials, Closure body) {
    if (cloudProvider == 'aws') {
        withCredentials([
            string(credentialsId: credentials.aws_access_key_id, variable: 'AWS_ACCESS_KEY_ID'),
            string(credentialsId: credentials.aws_secret_access_key, variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
            body()
        }
    } else if (cloudProvider == 'gcp') {
        withCredentials([
            file(credentialsId: credentials.gcp_service_account, variable: 'GOOGLE_CREDENTIALS')
        ]) {
            withEnv(["GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_CREDENTIALS}"]) {
                body()
            }
        }
    } else {
        error "Unsupported cloud provider: ${cloudProvider}"
    }
}