output "alb_controller_name" {
  description = "Name of the AWS Load Balancer Controller Helm release"
  value       = helm_release.aws_load_balancer_controller.name
}

output "flux_name" {
  description = "Name of the Flux Helm release"
  value       = helm_release.flux.name
}