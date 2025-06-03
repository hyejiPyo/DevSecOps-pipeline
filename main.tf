provider "aws" {
    region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
}

# public subnet
resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidr
    availability_zone = var.availability_zone
    map_public_ip_on_launch = true
}

# Private Subnet
resource "aws_subnet" "private" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidr
    availability_zone = var.availability_zone
}

# IGW
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
}

# Public Route Table
# aws_route_table은 리소스, public은 리소스의 식별자
# 다른 리소스에서 aws_route_table.public으로 참조 가능
# aws_internet_gateway.igw 는 인터넷 게이트웨이 리소스 전체
# .id는 그 리소스의 고유 ID 값 (예. igw-0abc123def)
# gateway_id에는 게이트웨이의 ID 문자열이 필요하기 때문에 .id를 꼭 붙여야함.
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

# Associate Public Subnet with Route Table
resource "aws_route_table_association" "public_assoc" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}

# Security Group for Jenkins EC2
resource "aws_security_group" "jenkins_sg" {
    name = "jenkins-sg"
    description = "Allow SSH and HTTP"
    vpc_id = aws_vpc.main.id

    ingress { 
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

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


# Jenkins EC2 in Public Subnet
resource "aws_instance" "jenkins" {
    ami = data.aws_ssm_parameter.amazon_linux_2.value
    instance_type = var.instance_type
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
    associate_public_ip_address = true
    key_name = var.key_name

    tags = {
        Name = "Jenkins-CI-Server"
    }

    user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -aG docker ec2-user
              amazon-linux-extras install epel -y
              yum install -y java-11-openjdk
              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
              yum install -y jenkins
              systemctl enable jenkins
              systemctl start jenkins
              EOF
}