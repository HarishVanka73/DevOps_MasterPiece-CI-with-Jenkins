pipeline {
    agent { label 'sample-1' }

    environment {
        NAME = "spring"
        COMMIT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        VERSION = "${BUILD_ID}-${COMMIT}"
        TOKEN = credentials("sonar-token")
        GIT_REPO_NAME = "DevOps-CD-argocd"
        GIT_USER_NAME = "Harishvanka73"
        AWS_REGION = "us-east-1"
        ECR_REPO_NAME = "spring"
        ECR_ACCOUNT_ID = "837553127105"
        // TARGET_REPO_JAR = 'my-local-repo'
        MAVEN_OPTS = "Xmx2gb"
       
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
                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
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
                     sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${imageName}"
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
        stage('Update Deployment File') {
            steps {
                withCredentials([string(credentialsId: 'github', variable: 'GITHUB_TOKEN')]) {
                    sh '''
                       rm -rf java-app
                       git clone https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME}.git
                       cd ${GIT_REPO_NAME}
                       git config user.email "kishgi1234@gmail.com"
                       git config user.name "kishgi"
                       sed -i "s/replaceImageTag/${BUILD_NUMBER}/g" manifests/deployment.yaml
                       git add manifests/deployment.yaml
                       git commit -m "Update deployment image to version ${BUILD_NUMBER}" || echo "No changes to commit"
                       git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME}.git HEAD:main
                    '''
                }
            }
        }

    
    }
    
}
