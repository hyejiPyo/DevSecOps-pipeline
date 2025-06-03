variable "aws_region" {
    default = "ap-northeast-2"
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
}

variable "public_subnet_cidr"{
    default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
    default = "10.0.2.0/24"
}

variable "availability_zone" {
    default = "ap-northeast-2c"
}

variable "instance_type" {
    default = "t3.medium"
}

variable "key_name" {
    description = "EC2 Key Pair Name"
    default = "cppm-test"
}