variable "aws_region" {
    default = "ap-northeast-2"
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
}

variable "public_subnet_cidr"{
    default = "10.0.1.0/24"
}

variable "private_subnet_test_cidr" {
    default = "10.0.2.0/24"
}
variable "private_subnet_prod_cidr" {
    default = "10.0.3.0/24"
}

variable "availability_zone" {
    default = "ap-northeast-2c"
}

variable "create_jenkins_instance" {
    description = "jenkins EC2 인스턴스 생성 여부"
    type = bool
    default = false
}

variable "instance_type" {
    default = "t3.medium"
}

variable "key_name" {
    description = "EC2 Key Pair Name"
    default = "cppm-test"
}