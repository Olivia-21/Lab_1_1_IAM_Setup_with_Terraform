provider "aws" {
    region = var.aws_region

    default_tags {
      tags = {
        lab = "CDEM1"
        ManagedBy = "Terraform"
      }
    }
}

module "data_engineer_role" {
  source = "../modules/iam/DataEngineerRole"
  role_name = "DataEngineerRole"
  Environment = "dev"
}

module "glue_service_role" {
  source = "../modules/iam/GlueServiceRole"
  role_name = "GlueServiceRole"
}

module "lambda_service_role" {
  source = "../modules/iam/LambdaExecutionRole"
  role_name = "LambdaExecutionRole"
}

module "redshift_role" {
  source = "../modules/iam/ReadshiftIAMRole"
  role_name = "RedshiftIAMRole"
}

module "analyst_role" {
  source = "../modules/iam/AnalystReadOnlyRole"
  role_name = "AnalystReadOnlyRole"
}



