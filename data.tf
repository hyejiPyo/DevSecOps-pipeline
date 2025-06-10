data "aws_ssm_parameter" "amazon_linux_2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# jenkins 기존 인스턴스가 있을 경우 참조
data "aws_instance" "jenkins" {
  count = var.create_jenkins_instance ? 0 : 1

  filter {
    name = "tag:Name"
    values = ["Jenkins-CI-Server"]
  }

  filter {
    name = "instance-state-name"
    values = ["running", "pening"]
  }

}

# 기존 VPC 참조
data "aws_vpc" "selected" {
  filter {
    name = "tag:Name"
    values = [""]
  }
}