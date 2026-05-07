# Lab 1.1 — IAM Setup for Data Engineering

## Overview
This module provisions all IAM roles and policies required for the data platform.
It implements the **Principle of Least Privilege** — every role has only the permissions
it needs to function.

---

## Architecture

```
Infrastructure/
└── modules/
    └── iam/
        ├── DataEngineerRole/
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── GlueServiceRole/
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── LambdaExecutionRole/
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── RedshiftIAMRole/
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── AnalystReadOnlyRole/
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        └── DataLakeBucketAccessPolicy/
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
```

---

## Roles Created

### DataEngineerRole
**Purpose:** Main role for data engineers building and managing data pipelines.

**Trust Policy:** EC2 service (can also be assumed by humans and other services)

**Permissions:**
| Policy | Reason |
|--------|--------|
| AmazonS3FullAccess | Read/write raw, processed, curated data zones |
| AWSGlueConsoleFullAccess | Create and manage Glue crawlers and ETL jobs |
| AmazonRedshiftFullAccess | Create clusters, run queries, load data |
| AmazonEMRFullAccessPolicy_v2 | Run Spark jobs for large-scale processing |
| AmazonKinesisFullAccess | Manage real-time data streams |
| AWSLambda_FullAccess | Create and invoke serverless functions |
| CloudWatchLogsFullAccess | Monitor and debug all pipeline jobs |

---

### GlueServiceRole
**Purpose:** Service role assumed by AWS Glue when running ETL jobs. Not used by humans.

**Trust Policy:** `glue.amazonaws.com`

**Permissions:**
| Policy | Reason |
|--------|--------|
| AWSGlueServiceRole | Basic Glue service operations |
| AmazonS3FullAccess | Read source data, write processed output |
| CloudWatchLogsFullAccess | Write job execution logs |
| SecretsManagerReadWrite | Retrieve database credentials securely |



---

### LambdaExecutionRole
**Purpose:** Execution role assumed by Lambda functions. Not used by humans.

**Trust Policy:** `lambda.amazonaws.com`

**Permissions:**
| Policy | Reason |
|--------|--------|
| AWSLambdaBasicExecutionRole | Write logs to CloudWatch (minimum required) |
| AmazonS3FullAccess | Read/write S3 for data processing |
| AmazonDynamoDBFullAccess | Read/write NoSQL for real-time analytics |
| AmazonKinesisFullAccess | Process real-time data streams |
| SecretsManagerReadWrite | Retrieve database credentials securely |

---

### RedshiftIAMRole
**Purpose:** Service role assumed by Redshift for COPY commands from S3.

**Trust Policy:** `redshift.amazonaws.com`

**Permissions:**
| Policy | Reason |
|--------|--------|
| AmazonS3FullAccess | Read data files for COPY INTO commands |
| CloudWatchLogsFullAccess | Write query and cluster logs |

> **Why read/write and not read-only?**
> Redshift UNLOAD commands also write back to S3 (query exports).

---

### AnalystReadOnlyRole
**Purpose:** Read-only role for data analysts and BI teams. Cannot modify or delete anything.

**Trust Policy:** EC2 service

**Permissions:**
| Policy | Reason |
|--------|--------|
| AmazonAthenaFullAccess | Run SQL queries against S3 data |
| AmazonRedshiftReadOnlyAccess | Query warehouse, cannot modify schemas |
| AmazonS3ReadOnlyAccess | Read data files, cannot write or delete |

> **Note:** QuickSight access is managed inside QuickSight itself (Reader role),
> not through IAM policies. No IAM attachment needed.

---

### DataLakeBucketAccessPolicy (Custom Policy)
**Purpose:** Restricts S3 access to `data-lake-*` buckets only and enforces encryption.

**Statements:**
| Sid | Effect | What it does |
|-----|--------|-------------|
| ListDataLakeBucket | Allow | List and get info on `data-lake-*` buckets |
| ReadWriteDataLakeObjects | Allow | Read/write/delete objects in `data-lake-*` |
| DenyUnencryptedUploads | Deny | Block any upload without AES256 header |

> **Why a custom policy?**
> AWS managed policies like `AmazonS3FullAccess` grant access to ALL buckets.
> This policy restricts to only `data-lake-*` buckets — better least privilege.

---

## Usage

```hcl
module "data_engineer_role" {
  source      = "../modules/iam/DataEngineerRole"
  role_name   = "DataEngineerRole"
  environment = "dev"
}

module "glue_role" {
  source    = "../modules/iam/GlueServiceRole"
  role_name = "GlueServiceRole"
}
```

---

## Outputs

| Output | Description |
|--------|-------------|
| `role_arn` | ARN of the created role — used in bucket policies and Lake Formation |
| `role_name` | Name of the role — used in policy attachments |

---

## Security Decisions

### Why not one admin role for everyone?
```
Bad:  Everyone → AdminRole → can do anything → one mistake = disaster
Good: Engineers → DataEngineerRole → specific permissions only
      Services  → ServiceRoles     → only what they need to run
      Analysts  → ReadOnlyRole     → can read, cannot break anything
```

### Why do services have their own roles?
```
If a Glue job is hacked:
  Without separate role: attacker gets DataEngineerRole → full access
  With GlueServiceRole:  attacker gets S3 + CloudWatch only → contained
```

---

## Prerequisites
- AWS account with admin or PowerUser access
- Terraform >= 1.0
- AWS CLI configured with appropriate credentials

## Deployment

```bash
cd Infrastructure/terraform
terraform init
terraform plan
terraform apply
```

## Cost
All IAM roles and policies are **free**. IAM has no hourly or storage charges.
