
**IaC Project** 
Configuring Jenkins on EC2 with ELBv2 SSL Offloading, Lambda Auto-Update, and Terraform Automation

Are you ready to set up a robust CI/CD environment using Jenkins on Amazon Web Services (AWS)? In this comprehensive tutorial, we'll guide you through the process of deploying Jenkins on an EC2 instance, configuring an Elastic Load Balancer (ELBv2) for SSL offloading, automating SSL certificate updates using a Lambda function, and automating the infrastructure deployment using Terraform.

**Prerequisites:**
1. An AWS account with appropriate permissions to create EC2 instances, ELBv2, Lambda functions, IAM roles, and Terraform resources.
2. Basic familiarity with AWS services and concepts.
3. Dummy data for testing purposes.

**Manual Steps**
**Step 1: Launching an EC2 Instance for Jenkins:**
1. Navigate to the EC2 dashboard in the AWS Management Console.
2. Launch a new EC2 instance using an Amazon Linux 2 AMI.
3. Configure security groups to allow inbound traffic on ports 22 (SSH) and 8080 (Jenkins).
4. Connect to your EC2 instance via SSH.

**Step 2: Installing Jenkins on EC2:**
1. Update the package repository: `sudo yum update -y`.
2. Install Java Development Kit (JDK): `sudo yum install java-17-openjdk-* -y`.
3. Add the Jenkins repository to yum: `sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo`.
4. Import the Jenkins repository GPG key: `sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key`.
5. Install Jenkins: `sudo yum install jenkins -y`.
6. Start and enable the Jenkins service: `sudo systemctl start jenkins && sudo systemctl enable jenkins`.

**Step 3: Configuring ELBv2 for SSL Offloading:**
1. Navigate to the EC2 dashboard and select Load Balancers.
2. Create a new Application Load Balancer (ALB) with HTTP and HTTPS listeners.
3. Configure the HTTPS listener with a valid SSL certificate.
4. Configure the target group to route traffic to your Jenkins EC2 instance on port 8080.
5. Update security groups to allow inbound traffic on port 443 (HTTPS).

**Step 4: Setting Up Lambda for SSL Certificate Auto-Update:**
1. Navigate to the Lambda dashboard in the AWS Management Console.
2. Create a new Lambda function using the provided "Blank Function" blueprint.
3. Configure the function to trigger on a scheduled basis (e.g., once a day).
4. Write a Lambda function using Python to update SSL certificates for the ELBv2.
   ```python
   import boto3

   def lambda_handler(event, context):
       client = boto3.client('elbv2')
       response = client.modify_listener(
           ListenerArn='YOUR_LISTENER_ARN',
           Certificates=[
               {
                   'CertificateArn': 'NEW_CERTIFICATE_ARN',
               },
           ],
       )
       return response
   ```
5. Replace `'YOUR_LISTENER_ARN'` and `'NEW_CERTIFICATE_ARN'` with your actual ARNs.

**Automate Infrastructure Deployment with Terraform:**
1. Clone the Terraform configuration repository from GitHub.
   ```bash
   git clone https://github.com/davestj/aws_jenkins_tf.git
   ```

2. **Edit Terraform Variables:**
   - Navigate to the `aws_jenkins_tf` directory.
   - Open the `terraform.tfvars` file in a text editor.
   - Update the variables with your AWS account settings:
     - `ami_id`: The ID of the Amazon Machine Image (AMI) to use for the EC2 instance.
     - `ssh_key_name`: The name of your SSH key pair for accessing the EC2 instance.
     - `ssh_private_key_path`: The file path to the private key corresponding to your SSH key pair.
     - `domain_name`: The domain name for the SSL certificate (e.g., `example.com`).
     - `subnet_ids`: A list of subnet IDs where the ELBv2 will be deployed.
     - `vpc_id`: The ID of the VPC where the ELBv2 will be deployed.

3. **Initialize and Apply Terraform Changes:**
   - Open a terminal and navigate to the `aws_jenkins_tf` directory.
   - Run the following commands:
     ```bash
     terraform init
     terraform plan
     terraform apply
     ```

**Step 6: Testing the Setup:**
- Access Jenkins through the ELBv2 DNS name using HTTPS.
- Verify that Jenkins is accessible and the SSL certificate is valid.
- Wait for the Lambda function to execute and update the SSL certificate.
- Verify that the SSL certificate is updated automatically without interruption.

Congratulations! You've successfully configured Jenkins on an EC2 instance with ELBv2 SSL offloading, automated SSL certificate updates using Lambda, and automated infrastructure deployment using Terraform. You now have a robust CI/CD environment ready to streamline your development workflows with enhanced security and reliability. #Jenkins #AWS #DevOps 🛠️🔒

