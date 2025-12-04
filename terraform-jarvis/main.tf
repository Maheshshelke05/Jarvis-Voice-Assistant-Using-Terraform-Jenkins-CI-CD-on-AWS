terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Generate SSH Key Automatically
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key" {
  key_name   = "devops-key"
  public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "key" {
  filename = "devops.pem"
  content  = tls_private_key.key.private_key_pem
}

# Jarvis Security Group
resource "aws_security_group" "jarvis_sg" {
  name = "jarvis-sg"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Jenkins Security Group
resource "aws_security_group" "jenkins_sg" {
  name = "jenkins-sg"

  # SSH
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins 8080
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Jarvis App Server
resource "aws_instance" "jarvis" {
  ami = "ami-02b8269d5e85954ef"
  instance_type = "t2.micro"
  key_name = aws_key_pair.key.key_name
  vpc_security_group_ids = [aws_security_group.jarvis_sg.id]

  user_data = file("user-data.sh")

  tags = {
    Name = "Jarvis-Server"
  }
}

# Jenkins Server
resource "aws_instance" "jenkins" {
  ami = "ami-02b8269d5e85954ef"
  instance_type = "t2.micro"
  key_name = aws_key_pair.key.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo hostnamectl set-hostname jenkins
    sudo hostname jenkins
    sudo apt update -y

    sudo apt install -y wget gnupg openjdk-17-jdk

    sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/" | \
    sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

    sudo apt update -y
    sudo apt install -y jenkins
    sudo apt update -y
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
  EOF

  tags = {
    Name = "Jenkins-Server"
  }
}

# OUTPUTS
output "jarvis_ip" {
  value = aws_instance.jarvis.public_ip
}

output "jenkins_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}
