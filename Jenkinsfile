pipeline {
    agent any

    environment {
        NAME = "spring"
        VERSION = "${env.BUILD_ID}"
        // GIT_COMMIT = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
       // GIT_REPO_NAME = "DevOps_MasterPiece-CD-with-argocd"
        // GIT_USER_NAME = "praveensirvi1212"
     //   AWS_REGION = 'us-east-1'
       // ECR_REPO_NAME = 'myapp'
       // ECR_ACCOUNT_ID = '353234380848'
        // TARGET_REPO_JAR = 'my-local-repo'
       
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
                           '''
                }
            }
        }

     //   stage("Quality Gate") {
       //     steps {
            //    script {
            //        waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
            //    }
         //   }
     //   }
        
       
        stage('Docker  Build') {
            steps {
               
      	         sh 'docker build -t ${NAME}:${VERSION} .'
                
            }
        }

     //   stage('Docker Image Scan') {
       //     steps {
      	 //       sh ' trivy image --format template --template "@/usr/local/share/trivy/templates/html.tpl" -o report.html ${NAME}:${VERSION} '
          //  }
    //    }    
        
      //  stage('Upload Scans report to AWS S3') {
         //     steps {
                  
                //  sh 'aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"  && aws configure set aws_secret_access_key "$AWS_ACCESS_KEY_SECRET"  && aws configure set region ap-south-1  && aws configure set output "json"' 
              //    sh 'aws s3 cp report.html s3://devops-masterpiece/'
         //     }
      //  }
    //    stage('Push Docker Image to ECR') {
    
        //     steps {
          //      script {
            //        def ecrUrl = "${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

             //       sh """
              //           aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrUrl}
               //          docker tag ${NAME}:${VERSION} ${ecrUrl}:${VERSION}
                //         docker push ${ecrUrl}:${VERSION}
                //       """
         //      }
       //     }
   //    }
  }
}





