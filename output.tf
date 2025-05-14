output "app_server_public_ip" {
  description = "IP público da instância EC2 para ser usado no Ansible"
  value       = aws_instance.app_server.public_ip
}
