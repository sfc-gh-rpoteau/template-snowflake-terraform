# Template: Snowflake Infrastructure Management with Terraform

## New Project Setup

To get started we'll need to set up some resources in Snowflake and your development environment to allow Terraform to communicate with your Snowflake instance. Additionally, we'll need to set up some resources in a cloud provider so we can have remote state tracking and locking.

### Snowflake Users and Roles Setup for Local Development

In this section we'll create 2 *users* and 2 *roles* to provide to Terraform. This same process can be used for other users and roles you want to use in Terraform. We want to maintain a seperations of duties and the principle of least privileges. So we'll create a user/role for the duties of the `SECURITYADMIN` role. We'll also create a user and role for the Terraform admin user, which will be given the minimum permissions to manage the infrastructure.


1. Create two keys for connecting to Snowflake programmatically, 1) for the Terraform admin user and 2) for the Terraform security admin user. Use the following command to generate the keys:

```bash
# generate encrypted private key
openssl genrsa 2048 | openssl pkcs8 -topk8 -v2 des3 -inform PEM -out ~/.ssh/rsa_key.p8
# OR
# generate unencrypted private key (useful for auth-agnostic providers)
openssl genrsa 2048 | openssl pkcs8 -nocrypt -topk8 -inform PEM -out ~/.ssh/rsa_key.p8

# generate public key
openssl rsa -in ~/.ssh/rsa_key.p8 -pubout -out ~/.ssh/rsa_key.pub
```

We'll need the public keys for the next step, in particular when we create the users.

2. Next use the script `scripts/snowflake/setup_terraform.sql` to create the Terraform users and roles and set the public keys to the users. You'll want to replace placeholders in the script with the public keys you generated in the previous step.

3. Optionally, if you want to verify the key-pair authentication is working, you can run the following command:
```bash
openssl rsa -pubin -in tf_admin_key.pub -outform DER | openssl dgst -sha256 -binary | openssl enc -base64
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

### Pre-commit Hooks (Recommended)

This project uses [pre-commit](https://pre-commit.com/) to automatically run formatting, linting, and security checks before each commit. The hooks configured are:

| Hook | Tool | Required? |
|------|------|-----------|
| `terraform_fmt` | `terraform fmt` | Yes (Terraform must be installed) |
| `terraform_tflint` | `tflint` | Optional — skipped if not installed |
| `checkov` | `checkov` | Optional — skipped if not installed |

**One-time setup:**

```bash
# Install pre-commit (pick one)
brew install pre-commit   # macOS
pip install pre-commit    # pip

# Install the git hooks
pre-commit install
```

**Optional tools:**

```bash
brew install tflint       # Terraform linter
pip install checkov       # Security/compliance scanner
```

From this point on, every `git commit` will automatically run the configured checks. If any check fails, the commit is blocked and the failure reason is printed. You can also run the hooks manually at any time:

```bash
pre-commit run --all-files
```

### Working with Terraform

To create a new module or deployment you can use the script `scripts/setup/new_module.py` to create the necessary files and directories. If you have a AI tool like Cursor, it does a pretty good job as well.

Once your setup, travel to one of the deployment directories in the `environments/<env>` directory. Initialize the Terraform deployment by running the following command:
```bash
terraform init -backend-config=backend.hcl
```

Generate an execution plan to see what changes will be applied:
```bash
terraform validate
terraform plan
```

Optionally, if you want to format, lint or run security scans manually (outside of pre-commit), you can run the following commands:
```bash
terraform fmt
tflint # requires installation
checkov # requires installation
```

Apply the changes to the infrastructure:
```bash
terraform apply
```

Destroy the infrastructure:
```bash
terraform destroy
```

> **NOTE:** In the dev environment, add variables for the `private_key` and `private_key_passphrase` for the Terraform admin and security admin users, where appropriate. For staging and production, we will use the OIDC authentication between Snowflake and Github Actions. Also, don't forget to edit you backend.hcl file to point to the correct state bucket.

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

We use a single workflow (`terraform-plan-apply`) that handles all three stages through dynamic branch resolution:

| Branch | Environment | Directory |
|--------|-------------|-----------|
| `dev` | `development` | `environments/development/` |
| `staging` | `staging` | `environments/staging/` |
| `main` | `production` | `environments/production/` |

- **On pull request** -- detect, lint, plan (speculative), and post a PR comment with the plan summary.
- **On merge (push)** -- detect, lint, plan, then wait for **reviewer approval** via GitHub Environment protection rules before applying.

Each stage uses two GitHub Environments: `{env}-plan` (secrets, no approval) for planning, and `{env}` (secrets + required reviewers) for applying.

For full details on the workflow architecture, authentication, environment setup, and change detection, see the [GitHub Actions CI/CD documentation](.github/README.md).


### Rollback Strategy

### Dealing with infrastructure drift:
- Importing resources
- comparing the current state with instance state
- updating the states to match







Addtional best practices:
- Usingg the lifecycle policy to prevent destructive changes:
- `.terraform-version` to lock the version of Terraform
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
