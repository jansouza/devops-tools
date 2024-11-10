#!/usr/bin/env groovy

def call(Map config) {

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
                    cd ${config.terraform_base_path}/
                    tflint --init
                    tflint --chdir=.
                    """
                }
            }
                
            stage('Terraform Init') {
                steps {
                    withCloudCredentials(config.cloud_provider, config.credentials) {
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
                    trivy config --ignorefile ${config.terraform_base_path}/.trivyignore --format table --exit-code 1 --severity CRITICAL,HIGH ${config.terraform_base_path}
                    """
                }
            }

            stage('Terraform Plan') {
                steps {
                    withCloudCredentials(config.cloud_provider, config.credentials) {
                        sh """
                        cd ${config.terraform_base_path}/
                        terraform plan -out=tfplan -no-color
                        terraform show -no-color tf-plan.out
                        """
                    }
                }
            }

            stage('Terraform Plan') {
                steps {
                    withCloudCredentials(config.cloud_provider, config.credentials) {
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
                    branch 'main'
                }
                steps {
                    
                    withCloudCredentials(config.cloud_provider, config.credentials) {
                        sh """
                        cd ${terraformBasePath}/
                    
                        terraform plan -out tf-plan.out
                        terraform show -no-color tf-plan.out
                        terraform apply -out tf-plan.out
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