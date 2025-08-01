pipeline {
    agent { label 'sample-1' }

    environment {
        NAME = "spring"
        COMMIT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        VERSION = "${BUILD_ID}-${COMMIT}"
        TOKEN = credentials('sonar-token')
       // GIT_REPO_NAME = "DevOps_MasterPiece-CD-with-argocd"
        // GIT_USER_NAME = "praveensirvi1212"
        AWS_REGION = 'us-east-1'
        ECR_REPO_NAME = 'spring'
        ECR_ACCOUNT_ID = '837553127105'
        // TARGET_REPO_JAR = 'my-local-repo'
        MAVEN_OPTS = "Xmx2gb"
       
    }

    tools { 
        maven 'maven-3.9.6' 
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

        // stage('Scan Image - Trivy') {
          //  steps {
            //    script {
              //      def imageName = "${NAME}:${VERSION}"
                //    sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${imageName}"
     //   }
 //   }
//}
        
       
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

       post {
          success {
             steps {
                sh "echo 'successfully passed the job ${BUILD_NUMBER}'"  
             }
          }
           failed {
             steps {
                 sh "echo 'failed the job ${BUILD_NUMBER}'"
             }
           }
  }
}
}
