#Print the ARN after apply(for documentation file)
output "data_engineer_role_arn" {
  value = module.data_engineer_role.role_arn
}
