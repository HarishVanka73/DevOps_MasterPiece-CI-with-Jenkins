pipeline {
    agent any

    environment {
        NAME = "spring"
        COMMIT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        VERSION = "${BUILD_ID}-${COMMIT}"
        TOKEN = credentials("sonar-token")
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
                script {
                  env.VERSION = "${BUILD_ID}-${COMMIT}"
                }  
            }
        }

        stage('verify') {
            steps {
             sh 'mvn clean install'
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
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
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
      	         sh 'docker build -t ${NAME}:${VERSION} .'         
            }
        }

        stage('Scan Image - Trivy') {
            steps {
                script {
                     def imageName = "${NAME}:${VERSION}"
                     sh "trivy image --severity HIGH,CRITICAL ${imageName}"
                }
            }
        }
        
       
        stage('Push Docker Image to ECR') {
            steps {
                script {
                    def ecrUrl = "${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

                    sh """
                         aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrUrl}
                         docker tag ${NAME}:${VERSION} ${ecrUrl}:${VERSION}
                         docker push ${ecrUrl}:${VERSION}
                       """
                }
            }
        }
        stage('Update Deployment Manifests') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    sh '''
                        # Clone the repo
                        git clone https://$GIT_USER:$GIT_PASS@github.com/Harishvanka73/DevOps_MasterPiece-CI-with-Jenkins.git /tmp/temp-repo
                        cd /tmp/temp-repo

                        # Configure Git
                        git config user.name "$GIT_USER"
                        git config user.email "harishvanka73@gmail.com"

                        # Update the deployment.yaml file
                        sed -i "s|image:.*|image: ${ECR_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${ECR_REPO_NAME}:${VERSION}|g" manifests/deployment.yaml

                        # Commit and push changes
                        git add manifests/deployment.yaml
                        git commit -m "Update deployment image to version"
                        git push origin main
                        rm -rf /tmp/temp-repo
                
                   '''
                }

            }
        }
    }    
}
    

