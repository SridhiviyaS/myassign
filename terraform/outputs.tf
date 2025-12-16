output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "jenkins_public_ip" {
  description = "Public IP of Jenkins server"
  value       = module.jenkins.jenkins_public_ip
}

output "jenkins_public_dns" {
  description = "Public DNS of Jenkins server"
  value       = module.jenkins.jenkins_public_dns
}

output "jenkins_url" {
  description = "URL to access Jenkins web interface"
  value       = module.jenkins.jenkins_url
}
