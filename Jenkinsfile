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
        ECR_ACCOUNT_ID = '992382420802'
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
            sh 'mvn clean verify'
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

        stage("package") {
            steps {
                sh 'mvn package'
            }
        }  

        stage("archive artifacts)" {
            steps {
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
        
       
        stage('Docker  Build') {
            steps {         
      	         sh 'docker build -t ${NAME}:${VERSION} .'
                
            }
        }

        stage('Docker Image Scan') {
            steps {
      	        sh ' trivy image --format json --output report.html ${NAME}:${VERSION} '
            }
        }    
        
        stage('Upload Scans report to AWS S3') {
              steps {
                  
                //  sh 'aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"  && aws configure set aws_secret_access_key "$AWS_ACCESS_KEY_SECRET"  && aws configure set region ap-south-1  && aws configure set output "json"' 
                  sh 'aws s3 cp report.html s3://devops-masterpiece/'
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

        
  }
}





