terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

###############################
# Geração da chave SSH
###############################
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "MeuWebServerKey" {
  key_name   = "MeuWebServerKey"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/keys/MeuWebServerKey.pem"
  file_permission = "0400"
}

###############################
# VPC padrão
###############################
data "aws_vpc" "default" {
  default = true
}

###############################
# Security Group
###############################
resource "aws_security_group" "MeuWebServerSG" {
  name        = "MeuWebServerSG"
  description = "Permitir SSH, HTTP e HTTPS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MeuWebServerSG"
  }
}

###############################
# Instância EC2
###############################
resource "aws_instance" "app_server" {
  ami                    = "ami-084568db4383264d4"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.MeuWebServerSG.id]
  key_name               = aws_key_pair.MeuWebServerKey.key_name

  tags = {
    Name = "My Web Server"
  }
}
