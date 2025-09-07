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
        VERSION = "1.0.${BUILD_NUMBER}
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
             sh "mvn clean install -Drevision=${VERSION}"
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
                 def imageTag = "v${VERSION}"
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
                    sh '''
                         aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrUrl}
                         docker push ${env.IMAGE_NAME}
                       '''
                }
            }
        }
        stage('Approval to update Dev manifests') {
            steps {
                input message: "Deploy ${env.IMAGE_NAME} to Dev?", ok: "Approve"
            } 
        }    
        stage('Update Deployment Manifests') {
            steps {
                //withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    sh '''
                        # Clone the repo
                        git clone --branch dev https://github.com/HarishVanka73/DevOps-CD-argocd.git
                        cd DevOps-CD-argocd

                        # Configure Git
                        git config user.name "$GIT_USER"
                        git config user.email "harishvanka73@gmail.com"

                        # Update the deployment.yaml file
                        sed -i "s|image:.*|image: ${ecrUrl}:{imageTag}|g" dev/dev-values.yaml

                        # Commit and push changes
                        git add dev/dev-values.yaml
                        git commit -m "Update deployment image to ${env.IMAGE_NAME} [ci skip]"
                        git push origin dev
                
                   '''
                //}
            }
        }
    }    
}
    

