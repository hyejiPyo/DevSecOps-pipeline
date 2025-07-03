data "aws_ssm_parameter" "amazon_linux_2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# jenkins 기존 인스턴스가 있을 경우 참조
locals {
  use_existing = !var.create_jenkins_instance
}

# Jenkins EC2 in Public Subnet
resource "aws_instance" "jenkins" {
    count = var.create_jenkins_instance ? 0 : 1
    ami = data.aws_ssm_parameter.amazon_linux_2.value
    instance_type = var.instance_type
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
    associate_public_ip_address = true
    key_name = var.key_name

    tags = {
        Name = "Jenkins-CI-Server"
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