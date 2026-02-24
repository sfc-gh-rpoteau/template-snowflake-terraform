# Setup Scripts

## new_module.py

Creates an empty Terraform module with template files.

### Usage

```bash
python3 new_module.py [OPTIONS] directory
```

### Arguments

| Argument | Description |
|----------|-------------|
| `directory` | Target directory path for the new module |

### Options

| Option | Description |
|--------|-------------|
| `-p, --parents` | Create parent directories if they don't exist |
| `-o, --with-outputs` | Include an `outputs.tf` file |

### Examples

```bash
# Create module in existing directory
python3 new_module.py modules/my_module

# Create module with parent directories
python3 new_module.py -p modules/nested/my_module

# Create module with outputs.tf
python3 new_module.py -o modules/my_module

# Full example
python3 new_module.py -p -o modules/new_feature
```

### Generated Files

- `main.tf` - Module resources (empty template)
- `variables.tf` - Input variables (empty template)
- `versions.tf` - Terraform and provider version requirements
- `outputs.tf` - Output values (only with `-o` flag)

The script auto-detects your installed Terraform version for `versions.tf`. If Terraform is not installed, it defaults to `1.14.4`.

---

## new_deployment.py

Creates a new Terraform deployment under `environments/<env>/<name>/` with template files.

### Usage

```bash
python3 new_deployment.py [OPTIONS] -e <env> <name>
```

### Arguments

| Argument | Description |
|----------|-------------|
| `name` | Deployment name (e.g., `governance_db`) |

### Options

| Option | Description |
|--------|-------------|
| `-e, --env` | **(required)** Environment name (e.g., `dev`, `tst`, `prd`) |
| `-p, --parents` | Create parent directories if they don't exist |
| `-o, --with-outputs` | Include an `output.tf` file |

### Examples

```bash
# Create deployment in dev environment
python3 new_deployment.py -e dev my_deployment

# Create deployment with parent directories
python3 new_deployment.py -e prd -p my_deployment

# Create deployment with output.tf
python3 new_deployment.py -e dev -o my_deployment

# Full example
python3 new_deployment.py -e tst -p -o my_deployment
```

### Generated Files

- `versions.tf` - Terraform, provider, and backend configuration with Snowflake provider block
- `variables.tf` - Snowflake connection variables (`account_name`, `organization_name`, `tf_admin_role`, `tf_admin_user`)
- `backend.hcl` - Local backend path with commented-out S3 backend placeholders
- `main.tf` - Empty template with a note to add a module
- `output.tf` - Output values (only with `-o` flag)

The script auto-detects your installed Terraform version for `versions.tf`. If Terraform is not installed, it defaults to `1.14.4`.
