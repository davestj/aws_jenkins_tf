pipeline {
    agent any
    
    environment {
        SLACK_CHANNEL = env.SLACK_CHANNEL_ID
    }
    
    stages {
        stage('Zip Lambda Function') {
            steps {
                sh 'zip -r lambda_function.zip ./lambda_function'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'lambda_function.zip', onlyIfSuccessful: true
                }
            }
        }
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }
        stage('Terraform Test') {
            steps {
                sh 'terraform validate'
                sh 'terraform fmt -check'
            }
        }
        stage('Terraform Plan') {
            steps {
                script {
                    def tfPlan = sh(script: 'terraform plan -out=tfplan', returnStdout: true)
                    writeFile file: 'terraform_plan.txt', text: tfPlan
                }
            }
        }
        stage('Save Terraform Plan Artifact') {
            steps {
                archiveArtifacts artifacts: 'terraform_plan.txt', onlyIfSuccessful: true
            }
        }
    }
    
    post {
        always {
            slackSend(channel: env.SLACK_CHANNEL, color: 'good', message: "Terraform plan generated successfully!")
        }
        success {
            slackSend(channel: env.SLACK_CHANNEL, color: 'good', message: "Pipeline succeeded!")
        }
        failure {
            slackSend(channel: env.SLACK_CHANNEL, color: 'danger', message: "Pipeline failed!")
        }
    }
}

