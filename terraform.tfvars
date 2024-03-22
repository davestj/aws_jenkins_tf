# terraform.tfvars
# User 
# Change the default values here
ami_id              = "ami-0123456789abcdef0"
ssh_key_name        = "AWS_SSH_key_pair"
ssh_private_key_path= "~/.ssh/aws_ssh.pem"
domain_name         = "example.com"
subnet_ids          = ["subnet-12345678", "subnet-87654321"]
vpc_id              = "vpc-0123456789abcdef0"

