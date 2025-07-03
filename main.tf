provider "aws" {
    region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "cicd-vpc"
    }
}

# public subnet
resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidr
    availability_zone = var.availability_zone
    map_public_ip_on_launch = true
    tags = {
        Name = "Jenkins-CI-Public-Subnet"
    }
}

# Private Subnet
resource "aws_subnet" "private" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidr
    availability_zone = var.availability_zone
    tags = {
        Name = "Jenkins-CI-Private-Subnet"
    }
}

# IGW
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "Jenkins-CI-IGW"
    }
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
    tags = {
        Name = "Jenkins-CI-Public-Route"
    }
}

# Associate Public Subnet with Route Table
resource "aws_route_table_association" "public_assoc" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}

# Security Group for Jenkins EC2 (퍼블릭)
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

    # 빌드 에이전트가 연결 가능하도록 Jenkins agent 포트 허용
    ingress {
        from_port = 50000
        to_port = 50000
        protocol="tcp"
        cidr_blocks = [aws_subnet.private.cidr_block]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Security Group for Build Agent EC2 (private)
resource "aws_security_group" "build_agent_sg" {
    name = "build-agent-sg"
    description = "Allow SSH and Jenkins agent port from Jenkins server"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = [aws_security_group.jenkins_sg.id]  # Jenkins 서버에서 SSH 허용
    }

    ingress {
        from_port = 50000
        to_port = 50000
        protocol = "tcp"
        security_groups = [aws_security_group.jenkins_sg.id]  # Jenkins agent 통신 허용
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
    count = var.create_jenkins_instance ? 1 : 0
    ami = data.aws_ssm_parameter.amazon_linux_2.value
    instance_type = var.instance_type
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
    associate_public_ip_address = true
    key_name = var.key_name

    tags = {
        Name = "Jenkins-CI-Server"
    }
# user_data 양식 맞춰서 작성 필요
# 맞추지 않을 경우 jenkins가 설치 및 실행 안됨
    user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install epel -y
              yum install -y java docker wget

              systemctl enable docker
              systemctl start docker
              usermod -aG docker ec2-user

              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

              yum install -y jenkins
              systemctl daemon-reexec
              systemctl enable jenkins
              systemctl start jenkins
              EOF

}

# Build Agent EC2 instance (프라이빗 서브넷)
resource "aws_instance" "build_agent" {
    ami = data.aws_ssm_parameter.amazon_linux_2.value
    instance_type = var.instance_type
    subnet_id = aws_subnet.private.id
    vpc_security_group_ids = [aws_security_group.build_agent_sg.id]
    associate_public_ip_address = false
    key_name = var.key_name

    tags = {
        Name = "Jenkins-Build-Agent"
    }

    user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install epel -y
              yum install -y java docker

              systemctl enable docker
              systemctl start docker
              usermod -aG docker ec2-user

              # Jenkins agent 설치 및 설정 스크립트 작성 필요
              EOF
}

