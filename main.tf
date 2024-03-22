# main.tf

provider "aws" {
  region = "us-east-1"  # Change to your desired region
}

# EC2 Instance for Jenkins
resource "aws_instance" "jenkins_instance" {
  ami           = var.ami_id
  instance_type = "m4.xlarge"
  key_name      = var.ssh_key_name
  security_groups = [aws_security_group.jenkins_security_group.id]

  root_block_device {
    volume_size = 120
    volume_type = "gp3"
    encrypted   = true
    delete_on_termination = false
  }

  ebs_block_device {
    device_name = "/dev/sdh"
    volume_size = 320
    volume_type = "gp3"
    encrypted   = true
    delete_on_termination = false
  }

  tags = {
    Name = "Jenkins-Instance"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.ssh_private_key_path)
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install java-17-openjdk-devel -y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
      "sudo yum install jenkins -y",
      "sudo systemctl start jenkins && sudo systemctl enable jenkins"
    ]
  }
}

# Security Group for Jenkins EC2 Instance
resource "aws_security_group" "jenkins_security_group" {
  name        = "jenkins-security-group"
  description = "Security group for Jenkins EC2 instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH access from anywhere (for demo purposes)
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP access from anywhere (for demo purposes)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-security-group"
  }
}

# ACM Certificate for HTTPS
resource "aws_acm_certificate" "jenkins_certificate" {
  domain_name       = var.domain_name
  validation_method = "DNS"
}

# ELBv2 for SSL Offloading
resource "aws_lb" "jenkins_lb" {
  name               = "jenkins-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.jenkins_security_group.id]
  subnets            = var.subnet_ids

  tags = {
    Name = "jenkins-lb"
  }
}

resource "aws_lb_listener" "jenkins_lb_listener" {
  load_balancer_arn = aws_lb.jenkins_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  certificate_arn = aws_acm_certificate.jenkins_certificate.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins_target_group.arn
  }
}

resource "aws_lb_target_group" "jenkins_target_group" {
  name     = "jenkins-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "jenkins_listener_rule" {
  listener_arn = aws_lb_listener.jenkins_lb_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

#Zip it n ship it
resource "null_resource" "generate_lambda_zip" {
  provisioner "local-exec" {
    command = "zip -r lambda_function.zip ./lambda_function"
    working_dir = "${path.module}/lambda_function"
  }
}

# Lambda Function for ACM Certificate Auto-Renewal
resource "aws_lambda_function" "acm_certificate_renewal" {
  filename         = "${path.cwd}/lambda_function.zip"
  function_name    = "acm-certificate-renewal"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-acm-certificate-renewal-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "lambda-role-policy"
    policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": "logs:CreateLogGroup",
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource": "arn:aws:logs:*:*:*"
        }
      ]
    })
  }
}

resource "aws_lambda_permission" "allow_lambda_to_call_acm" {
  statement_id  = "AllowExecutionFromACM"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.acm_certificate_renewal.function_name
  principal     = "acm.amazonaws.com"
  source_arn    = aws_acm_certificate.jenkins_certificate.arn
}

output "load_balancer_dns_name" {
  value = aws_lb.jenkins_lb.dns_name
}

output "ssl_certificate_arn" {
  value = aws_acm_certificate.jenkins_certificate.arn
}

output "jenkins_instance_id" {
  description = "The ID of the newly created Jenkins EC2 instance"
  value       = aws_instance.jenkins_instance.id
}

output "jenkins_instance_internal_ip" {
  description = "The internal IP address of the newly created Jenkins EC2 instance"
  value       = aws_instance.jenkins_instance.private_ip
}

output "jenkins_instance_internal_dns" {
  description = "The internal DNS name of the newly created Jenkins EC2 instance"
  value       = aws_instance.jenkins_instance.private_dns
}

output "elb_internal_dns" {
  description = "The internal DNS name of the Elastic Load Balancer"
  value       = aws_lb.jenkins_lb.dns_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function for SSL certificate auto-update"
  value       = aws_lambda_function.acm_certificate_renewal.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function for SSL certificate auto-update"
  value       = aws_lambda_function.acm_certificate_renewal.function_name
}

