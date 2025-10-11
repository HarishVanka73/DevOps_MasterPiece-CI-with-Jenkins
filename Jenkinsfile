pipeline {
    agent { label 'my-app' }

    environment {
        AWS_REGION = "us-east-1"
        IMAGE_REPO_NAME = "my-app"
        ECR_ACCOUNT_ID = "837553127105"
        GIT_USER = "Harishvanka73"
        VERSION = "1.0.${BUILD_NUMBER}"
    }

    tools { 
        maven "maven-3.9.6"
    }
    
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout Git') {
            steps {
                git branch: 'main', url:'https://github.com/Harishvanka73/DevOps_MasterPiece-CI-with-Jenkins.git'
            }
        }

        stage('Verify & Build JAR') {
            steps {
                sh "mvn clean install -Drevision=${VERSION}"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-server') {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'TOKEN')]) {
                        sh """ mvn sonar:sonar \
                               -Dsonar.projectKey='gitops-with-argocd' \
                               -Dsonar.projectName='gitops-with-argocd' \
                               -Dsonar.login=${TOKEN} """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: true, credentialsId: 'sonar-token'
                }
            }
        }

        stage('Trivy Filesystem Scan') {
            steps {
                sh 'trivy fs --scanners vuln --severity HIGH,CRITICAL .'
            }
        }

        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        stage('Docker Build') {
            steps {  
                script {
                    env.ecrUrl = "${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                    env.imageTag = "v${VERSION}"
                    env.IMAGE_NAME = "${IMAGE_REPO_NAME}:${env.imageTag}"
                    sh "docker build -t ${env.IMAGE_NAME} ."
                }
            }
        }

        stage('Trivy Docker Image Scan') {
            steps {
                sh "trivy image --severity HIGH,CRITICAL ${env.IMAGE_NAME}"
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${env.ecrUrl}
                        docker tag ${env.IMAGE_NAME} ${env.ecrUrl}/${IMAGE_REPO_NAME}:${env.imageTag}
                        docker push ${env.ecrUrl}/${IMAGE_REPO_NAME}:${env.imageTag}
                    """
                }
            }
        }

        stage('Checkpoint Before Deployment') {
            steps {
                checkpoint "Checkpoint: Ready to deploy ${env.IMAGE_NAME} to DEV?"
            }
        }

       // stage('Approval for Deployment') {
         //   steps {
            //    script {
              //      timeout(time: 15, unit: 'MINUTES') {
               //         input message: "Approve deployment to DEV EKS?", ok: "Approve"
              //      }
            //    }
         //   }
      //  }

        stage('Approval to Update Dev Manifests') {
            steps {
                input message: "Deploy ${env.IMAGE_NAME} to Dev?", ok: "Approve"
            } 
        }

        stage('Update Deployment Manifests') {
            steps {
                sh """
                    git clone --branch dev https://github.com/HarishVanka73/DevOps-CD-argocd.git
                    cd DevOps-CD-argocd

                    git config user.name "$GIT_USER"
                    git config user.email "harishvanka73@gmail.com"

                    sed -i "s|repository:.*|repository: ${env.ecrUrl}/${IMAGE_REPO_NAME}|g" dev/dev-values.yaml
                    sed -i "s|tag:.*|tag: ${env.imageTag}|g" dev/dev-values.yaml

                    git add dev/dev-values.yaml
                    git commit -m "Update deployment image to ${env.IMAGE_NAME} [ci skip]"
                    git push origin dev
                """
            }
        }

        stage('Integration Tests') {
            steps {
                sh """
                    # Example integration test commands
                    echo "Running integration tests on DEV cluster..."
                    # kubectl apply -f test-resources.yaml
                    # ./run_integration_tests.sh
                """
            }
        }
    }    
}
