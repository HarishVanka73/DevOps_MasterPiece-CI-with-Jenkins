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
        MAVEN_OPTS = "Xmx2gb"
        GIT_COMMITTER_NAME = "Harishvanka73"
        GIT_COMMITER_EMAIL = "harishvanka73@gmail.com"
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
                    sh '''
                       git clone https://github.com/Harishvanka73/DevOps_MasterPiece-CI-with-Jenkins.git
                       cd DevOps_MasterPiece-CI-with-Jenkins
                       git config user.email "${GIT_COMMITTER_EMAIL}"
                       git config user.name "${GIT_COMMITTER_NAME}"
                       sed -i "s/image:.*/${ecrUrl}:${VERSION}/g" manifests/deployment.yaml
                       git add manifests/deployment.yaml
                       git commit -m "Update deployment image to version ${BUILD_ID}" || echo "No changes to commit"
                       git push 
                    '''
                }
            }
        }

    
    }
    
}
