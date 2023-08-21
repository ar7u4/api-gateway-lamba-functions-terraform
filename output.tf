output "api_endpoint" {
  description = "The endpoint URL of the created API"
  value       = aws_api_gateway_deployment.example_deployment.invoke_url
}
