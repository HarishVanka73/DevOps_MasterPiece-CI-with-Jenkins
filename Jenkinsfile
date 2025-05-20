pipeline {
    agent any

    environment {
        NAME = "spring-app"
        VERSION = "${env.BUILD_ID}"
        // GIT_COMMIT = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
       // GIT_REPO_NAME = "DevOps_MasterPiece-CD-with-argocd"
        // GIT_USER_NAME = "praveensirvi1212"
        AWS_REGION = 'us-east-1'
        ECR_REPO_NAME = 'myapp'
        ECR_ACCOUNT_ID = '123456789012'
       
    }

    tools { 
        maven 'maven-3.8.6' 
    }
    stages {
        stage('Checkout git') {
            steps {
              git branch: 'main', url:'https://github.com/Harishvanka73/DevOps_MasterPiece-CI-with-Jenkins.git'
            }
        }
        
        stage('Build & JUnit Test') {
            steps {
                sh 'mvn clean install' 
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-server') {
                        sh '''mvn clean verify sonar:sonar \
                        -Dsonar.projectKey=gitops-with-argocd \
                        -Dsonar.projectName='gitops-with-argocd' \
                        -Dsonar.host.url=$sonarurl \
                        -Dsonar.login=$sonarlogin'''
                }
            }
        }

        stage("Quality Gate") {
            steps {
              timeout(time: 1, unit: 'HOURS') {
                waitForQualityGate abortPipeline: true
              }
            }
        }
        
        stage('Deploy to Artifactory') {
            environment {
                // Define the target repository in Artifactory
                TARGET_REPO = 'my-local-repo'
            }
            
            steps {
                script {
                    try {
                        def server = Artifactory.newServer url: 'http://13.232.95.58:8082/artifactory', credentialsId: 'jfrog-cred'
                        def uploadSpec = """{
                            "files": [
                                {
                                    "pattern": "target/*.jar",
                                    "target": "${TARGET_REPO}/"
                                }
                            ]
                        }"""
                        
                        server.upload(uploadSpec)
                    } catch (Exception e) {
                        error("Failed to deploy artifacts to Artifactory: ${e.message}")
                    }
                }
            }
        }

         stage('Download from Artifactory') {
            steps {
                script {
                    def server = Artifactory.newServer(
                        url: "${ARTIFACTORY_URL}",
                        credentialsId: "${ARTIFACTORY_CREDENTIALS}"
                    )

                    def downloadSpec = """{
                        "files": [
                            {
                                "pattern": "${TARGET_REPO}/*.jar",
                                "target": "downloaded/"
                            }
                        ]
                    }"""

                    server.download(downloadSpec)
                }
            }
        }
        
        stage('Docker  Build') {
            steps {
               
      	         sh 'docker build -t ${NAME}:${VERSION} .'
                
            }
        }

        stage('Docker Image Scan') {
            steps {
      	        sh ' trivy image --format template --template "@/usr/local/share/trivy/templates/html.tpl" -o report.html ${NAME}:${VERSION} '
            }
        }    
        
        stage('Upload Scan report to AWS S3') {
              steps {
                  
                //  sh 'aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"  && aws configure set aws_secret_access_key "$AWS_ACCESS_KEY_SECRET"  && aws configure set region ap-south-1  && aws configure set output "json"' 
                  sh 'aws s3 cp report.html s3://devops-mastepiece/'
              }
        }
        stage('Push Docker Image to ECR') {
    
             steps {
                script {
                    def ecrUrl = "${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

                    sh """
                         aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrUrl}
                         docker tag myapp:${VERSION} ${ecrUrl}:${VERSION}
                         docker push ${ecrUrl}:${VERSION}
                       """
        }
    }
}

    }

    
}





