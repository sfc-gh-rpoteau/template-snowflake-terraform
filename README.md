# Template: Snowflake Infrastructure Management with Terraform

## New Project Setup

To get started we'll need to set up some resources in Snowflake and your development environment to allow Terraform to communicate with your Snowflake instance. Additionally, we'll need to set up some resources in a cloud provider so we can have remote state tracking and locking.

### Snowflake Users and Roles Setup for Local Development

In this section we'll create two users and 1 role to provide to Terraform. We want to maintain a seperations of duties and the principle of least privileges. So we'll create a user for the `SECURITYADMIN` role for managing account-level roles. We'll also create a user and role for the Terraform admin user, which will be givne the minimum permissions to manage the infrastructure.

1. Create two keys for connecting to Snowflake programmatically, 1) for the Terraform admin user and 2) for the Terraform security admin user. Use the following command to generate the keys:

```bash
# generate encrypted private key
openssl genrsa 2048 | openssl pkcs8 -topk8 -v2 des3 -inform PEM -out ~/.ssh/rsa_key.p8

# generate public key
openssl rsa -in ~/.ssh/rsa_key.p8 -pubout -out ~/.ssh/rsa_key.pub
```

We'll need the public keys for the next step.

2. Next use the script `scripts/setup_terraform.sql` to create the Terraform admin user and role and set up key-pair authentication. You'll want to replace placeholders in the script with the public keys you generated in the previous step.

3. Optionally, if you want to verify the key-pair authentication is working, you can run the following command:
```bash
openssl rsa -pubin -in tf_rsa_key.pub -outform DER | openssl dgst -sha256 -binary | openssl enc -base64
```
and compare the output to the output of:

```SQL
DESC USER TF_ADMIN_USER
  ->> SELECT SUBSTR(
        (SELECT "value" FROM $1
           WHERE "property" = 'RSA_PUBLIC_KEY_FP'),
        LEN('SHA256:') + 1) AS key;
```

If they match, you're all set!

4. Optionally, if you wanted a new or dedicated virtual warehouse for the Terraform admin user, you can use the script `scripts/setup_warehouse.sql` to create it. 

### Remote State and Locking 

We'll be using AWS S3 to store the Terraform state and lock the state, but other cloud providers support remote state tracking and/or locking.

1. Create an S3 bucket with encryption enabled, versioning enabled, *and lockfile enabled*. A Terraform example is provided in the `scripts/aws/setup_s3_bucket.tf` file.
2. ~~Create a DynamoDB table with a primary key of `LockID` (case-sensitive)~~
3. Create an IAM policy to allow the user to access the S3 bucket ~~and DynamoDB table~~. A Terraform example is provided in the `scripts/aws/aws-terraform-state-bucket-role.json` file.

\* AWS S3 now supports lockfile functionality, so you can use that instead of DynamoDB (deprecated for this use case).

## Project Structures

The recommended structure for a project. Modules are reusable components that are used in the environments subfolders to construct the consistent infrastructure accross environments. Within `environments` will be a subfolder for each environment (dev, tst, prd). Each environment subfolder will contain subfolders for logical groups of resources centralized around a project, application, service, etc.

```
environments/
├── dev/
|   ├── app1/
|   |   ├── main.tf
|   |   ├── variables.tf
|   |   ├── outputs.tf
|   |   ├── versions.tf
|   |   ├── README.md
|   |   └── backend.hcl
|   └── app2/
├── staging/
|   ├── app1/
|   └── app2/
└── prod/
    ├── app1/
    └── app2/
modules
├── module1/
|   ├── main.tf           # Primary resource definitions
|   ├── variables.tf      # Input variables
|   ├── outputs.tf        # Output values
|   ├── versions.tf       # Version constraints
|   ├── README.md         # Module documentation
|   └── examples/         # Usage examples
└── module2/
```

### Remote modules

You can also construct remote modules that are stored in Github. It's little more complex and can potentially lead to some bloat in the number of Github repositories. It might be worthwhile if your infra team wants to make infrastructure more self-service with guardrails.

```terraform
module "database" {
  source = "github.com/snowflake-labs/terraform-snowflake-database?ref=v0.1.0"
  # remaining variables and configuration...
}
```

## Development Workflow

Initialize the Terraform project in one of the subfolders of the environments directory:
```bash
terraform init -backend-config=backend.hcl
```

Generate an execution plan to see what changes will be applied:
```bash
terraform validate
terraform plan
```

Apply the changes to the infrastructure:
```bash
terraform apply
```

Destroy the infrastructure:
```bash
terraform destroy
```

### Storing Secrets

By default, Terraform will store secrets in the state file. This is **NOT RECOMMENDED** and you should use a secrets manager like AWS Secrets Manager or Azure Key Vault. If you're using a secrets manager, like AWS Secrets Manager, you'll need to include a provider for the secrets manager in your Terraform configuration.

```terraform
provider "aws" {
  alias = "secrets_provider"
  # remaining provider configuration...
}
```

Then you can use the following example to get the secret from AWS Secrets Manager:

```hcl
data "aws_secretsmanager_secret" "secret" {
  provider = aws.secrets_provider
  name     = "secret-name"
  # or arn="arn:aws:secretsmanager:us-east-1:123456789012:secret:secret-name"
}

# How you would use the secret in your Terraform configuration
locals {
  secret_value = data.aws_secretsmanager_secret.secret.secret_string
}

```

\*Do NOT use Snowflake Secrets to store secrets for Terraform. Though with some workarounds and policies it could be safe in theory. In practice, it's not recommended. Those secrets can end up in the state file and exposed.

## Orchestration

We will consider general orchestration patterns for Terraform and an implementation example with Github Actions.

### General Orchestration Patterns

This section assumes that your terraform code is working from your local environment.

The elements of a good orchestration strategy are:
1. Standardize the code
2. Setup secure authentication to the remote state and locking
3. Setup a promotion strategy
4. Create policies and guardrails for permissible infrastructure
6. Deal with infrastructure drift
7. Observability and auditability
5. Setup a rollback strategy

Here's an example using Github Actions:

Before we push our changes to Github, we'll want to run the following commands to ensure our changes are syntactically valid/consistent and secure. This will help us **standardize the code**.

```bash
terraform fmt
terraform validate
tflint
checkov -d . --quiet
```

Next, we will set up Secure authentication between GitHub actions and AWS where we will have an S3 bucket for state tracking and locking. You haven't already first set up the S3 bucket with lockfile functionality, refer to [Remote State and Locking](#remote-state-and-locking) section for more details. Now, setup the OIDC connection between GitHub and AWS using the Github documentation [here](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws).

We will create a two part workflow, with the following jobs:
1. A pull request job to plan the changes and review the plan.
2. A deployment job to apply the changes and promote the changes to the next environment.

Check the `.github/workflow/terraform-apply-dev.yaml` file for a reference implementation.

The first job triggers when a pull request is created or updated. It will make sure the code is clean, secure, follows policies and will run the plan command to generate a plan and serve it up for review.


### Rollback Strategy

### Dealing with infrastructure drift:
- Importing resources
- comparing the current state with instance state
- updating the states to match







Addtional best practices:
- Usingg the lifecycle policy to prevent destructive changes:
- `.terraform.version` to lock the version of Terraform
- I wouldn't use terraform t

## FinOps Setup

### Tagging
Tag databases, schemas, users, roles, queries, warehouses.

### Consolidation

### Visualization


## Miscellaneous

### Pin down the version of Terraform
You can pin down the version of Terraform by adding the following to the `versions.tf` file:

```terraform
terraform {
  required_version = "= 1.14.3"
}
```

### Preview Features and `snowflake_execute` Resource

Modules for abstracting away preview features and the `snowflake_execute` resource, so that you only need when the feature is GA, the interface is the same.


# Example Modules

## `modules/e2e_ml_quickstart/`

This module creates the infrastructure for the E2E ML Quickstart. It creates a role, database, schema, warehouse, compute pool and notebook. After setting up the infrastructure you can finish the tutorial [here](https://www.snowflake.com/en/developers/guides/end-to-end-ml-workflow).

# References

[[1] Snowflake Documentation: Key-pair authentication and key-pair rotation](https://docs.snowflake.com/en/user-guide/key-pair-auth)
