#!/usr/bin/env groovy

def call(Map config) {
    // Default values
    config.git_branch = config.git_branch ?: 'main'
    config.deploy_path = config.deploy_path ?: 'deployments'

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
                    gitleaks dir ${config.deploy_path}/${config.project_namespace}/${config.project_name} -v
                    """
                }
            }

            stage('K8s Deploy') {
                steps {
                    withCredentials([file(credentialsId: config.kubeconfig_credentials, variable: 'KUBECONFIG')]) {
                        sh """
                        echo $KUBECONFIG > ~/.kube/config

                        chmod +x /usr/local/bin/k8s-deploy.sh
                        k8s-deploy.sh --app=${config.project_name} --path=${config.deploy_path}/${config.project_namespace}/${config.project_name}
                        """
                    }
                }
            }
        }
    }
}