output "jenkins_public_ips" {
    value = [ for instance in aws_instance.jenkins : instance.public_ip ]
}