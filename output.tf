output "jenkins_public_ip" {
    value = var.create_jenkins_instance ?
        aws_instance.jenkins[0].public_ip :
        data.aws_instance.jenkins_existing[0].public_ip
}