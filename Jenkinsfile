pipeline {
    agent any

    environment {
        TOKEN = credentials("sonar-token")
        MAVEN_OPTS = "-Dmaven.repo.local=/opt/maven/.m2/repository"
        AWS_REGION = "us-east-1"
        ECR_REPO_NAME = "spring"
        ECR_ACCOUNT_ID = "837553127105"
        // TARGET_REPO_JAR = 'my-local-repo'
       // MAVEN_OPTS = "Xmx2gb"
        GIT_USER = "Harishvanka73"
    }

    tools { 
        maven "maven-3.9.6"
    }
    
    stages {
        stage('Cleanws') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout git') {
            steps {
              git branch: 'main', url:'https://github.com/Harishvanka73/DevOps_MasterPiece-CI-with-Jenkins.git'  
            }
        }
        stage('verify') {
            steps {
             sh "mvn clean package"
            }
        }     
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-server') {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'TOKEN')]) {
                        sh '''mvn sonar:sonar \
                              -Dsonar.projectKey='gitops-with-argocd' \
                              -Dsonar.projectName='gitops-with-argocd' \
                              -Dsonar.login=${TOKEN}
                           '''
                    }
                }
            }
        }  
        stage("Quality Gate") {
            steps {
                script {
                    waitForQualityGate abortPipeline: true, credentialsId: 'sonar-token'
                }
            }
        }
        stage("archive artifacts") {
            steps {
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }   
        stage('Docker  Build') {
            steps {   
                 def ecrUrl = "${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
                 def version = "1.0.${env.BUILD_NUMBER}"
                 def imageTag = "v${version}"
                 env.IMAGE_NAME = "${ecrUrl}:${imageTag}"
      	         sh "docker build -t ${env.IMAGE_NAME} ."        
            }
        }

        stage('Scan Image - Trivy') {
            steps {
                script {
                     sh "trivy image --severity HIGH,CRITICAL ${env.IMAGE_NAME}"
                }
            }
        }
        stage('Push Docker Image to ECR') {
            steps {
                script {
                    sh """
                         aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrUrl}
                         docker push ${env.IMAGE_NAME}
                       """
                }
            }
        }
        stage('Update Deployment Manifests') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    sh '''
                        # Clone the repo
                        git clone --branch manifest https://$GIT_USER:$GIT_PASS@github.com/Harishvanka73/DevOps_MasterPiece-CI-with-Jenkins.git 
                        cd DevOps_MasterPiece-CI-with-Jenkins

                        # Configure Git
                        git config user.name "$GIT_USER"
                        git config user.email "harishvanka73@gmail.com"

                        # Update the deployment.yaml file
                        sed -i "s|image:.*|image: ${ECR_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${ECR_REPO_NAME}:${VERSION}|g" manifests/deployment.yaml

                        # Commit and push changes
                        git add manifests/deployment.yaml
                        git commit -m "Update deployment image to ${version} [ci skip]"
                        git push origin manifest
                
                   '''
                }

            }
        }
    }    
}
    

