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
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                        ]) {
                            sh """
                            cd ${config.terraform_base_path}/
                            terraform init
                            terraform validate
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
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                        ]) {
                            sh """
                            cd ${config.terraform_base_path}/
                            terraform plan -out tf-plan.out
                            terraform show -out tf-plan.out --no-color
                            """
                    }
                }
            }

            stage('Terraform Apply') {
                when {
                    branch 'main'
                }
                steps {
                    
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                        ]) {
                            sh """
                            cd ${terraformBasePath}/
                    
                            terraform plan -out tf-plan.out
                            terraform show -out tf-plan.out --no-color
                            terraform apply -out tf-plan.out
                            """
                    }
                }
            }
        }
    }
}