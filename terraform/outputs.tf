output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.devops_server.public_ip
}

output "instance_id" {
  description = "Instance ID of the EC2 server"
  value       = aws_instance.devops_server.id
}