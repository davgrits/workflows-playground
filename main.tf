terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 3.4.0"
    }
  }
  required_version = ">= 1.2.1"
}

provider "aws" {
  region = "us-east-1"
}

variable "key_name" {
  description = "SSH Key Name For Authentication"
  type        = string
  default     = "aws_key"
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.key.public_key_openssh
}

resource "local_sensitive_file" "ssh_private_key" {
  filename = "${aws_key_pair.key_pair.key_name}.pem"
  content  = tls_private_key.key.private_key_openssh
}

resource "local_sensitive_file" "ssh_public_key" {
  filename = "${aws_key_pair.key_pair.key_name}.pub"
  content  = tls_private_key.key.public_key_openssh
}

resource "aws_security_group" "aws_sg" {
  name = "SG for ServerInstance"

  ingress {
    description = "SSH from the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "80 from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "my_server" {
  ami                         = "ami-0bb84b8ffd87024d8"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.aws_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key_pair.key_name

  tags = {
    Name = "ServerInstance"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install docker -y",
      "sudo service docker start",
      "sudo usermod -aG docker ec2-user",
      "sudo chkconfig docker on",
      "sudo yum install -y git",
      "sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "docker-compose version",
      "mkdir app",
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.key.private_key_openssh
      host        = self.public_dns
    }
  }

  provisioner "file" {
    source      = "app"
    destination = "/home/ec2-user"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.key.private_key_openssh
      host        = self.public_dns
    }
  }

  provisioner "remote-exec" {
    inline = [
      "cd app",
      "docker-compose up -d --build",
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.key.private_key_openssh
      host        = self.public_dns
    }
  }

  depends_on = [
    aws_key_pair.key_pair
  ]
}

output "instance_ip" {
  value = aws_instance.my_server.public_ip
}
