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
