data "aws_ssm_parameter" "amazon_linux_2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# jenkins 기존 인스턴스가 있을 경우 참조
locals {
  use_existing = !var.create_jenkins_instance
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
              yum install -y java-11-openjdk docker wget

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
data "aws_instance" "jenkins_existing" {
  count = local.use_existing ? 1 : 0

  filter {
    name = "tag:Name"
    values = ["running","pending","stopped"]
  }

  most_recent = true
}

# 기존 VPC 참조
data "aws_vpc" "selected" {
  id = "vpc-01042fc1142ff87a9"
}