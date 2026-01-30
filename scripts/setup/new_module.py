#!/usr/bin/env python3
"""
Terraform Module Scaffolding Script

Creates an empty Terraform module directory with template files
following the project's existing conventions.
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path

DEFAULT_TERRAFORM_VERSION = "1.14.4"


# =============================================================================
# Helper Functions
# =============================================================================

def get_terraform_version() -> str:
    """
    Get the installed Terraform version by running `terraform --version`.

    Returns:
        The Terraform version string (e.g., "1.14.4"), or DEFAULT_TERRAFORM_VERSION
        if Terraform is not installed or version cannot be determined.
    """
    try:
        result = subprocess.run(
            ["terraform", "--version"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0:
            # Parse version from output like "Terraform v1.14.4\n..."
            match = re.search(r"Terraform v(\d+\.\d+\.\d+)", result.stdout)
            if match:
                return match.group(1)
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass

    return DEFAULT_TERRAFORM_VERSION


# =============================================================================
# File Templates
# =============================================================================

MAIN_TF_TEMPLATE = """\
# ============================================================================
# Module: {module_name}
# ============================================================================
# Description: [Add module description here]
# ============================================================================

# Add your Terraform resources here
"""

VARIABLES_TF_TEMPLATE = """\
# ============================================================================
# Module Variables
# ============================================================================

# Add your input variables here
"""

OUTPUTS_TF_TEMPLATE = """\
# ============================================================================
# Module Outputs
# ============================================================================

# Add your output values here
"""

VERSIONS_TF_TEMPLATE = """\
terraform {{
  required_version = "= {terraform_version}"

  required_providers {{
    snowflake = {{
      source  = "snowflakedb/snowflake"
      version = "= 2.12.0"
    }}
  }}
}}
"""


# =============================================================================
# Main Logic
# =============================================================================

def create_module(directory: Path, parents: bool, with_outputs: bool) -> list[str]:
    """
    Create a new Terraform module directory with template files.

    Args:
        directory: Target directory path for the new module
        parents: Create parent directories if they don't exist
        with_outputs: Include an outputs.tf file

    Returns:
        List of created file paths

    Raises:
        FileExistsError: If directory already contains .tf files
        FileNotFoundError: If parent directories don't exist and --parents not set
    """
    # Resolve to absolute path
    directory = directory.resolve()

    # Check if directory exists and contains .tf files
    if directory.exists():
        existing_tf_files = list(directory.glob("*.tf"))
        if existing_tf_files:
            raise FileExistsError(
                f"Directory '{directory}' already contains Terraform files: "
                f"{[f.name for f in existing_tf_files]}"
            )
    else:
        # Create directory
        if parents:
            directory.mkdir(parents=True, exist_ok=True)
        else:
            # Check if parent exists
            if not directory.parent.exists():
                raise FileNotFoundError(
                    f"Parent directory '{directory.parent}' does not exist. "
                    "Use --parents / -p to create parent directories."
                )
            directory.mkdir(exist_ok=True)

    # Get module name from directory name
    module_name = directory.name

    # Get Terraform version
    terraform_version = get_terraform_version()

    # Define files to create
    files_to_create = {
        "main.tf": MAIN_TF_TEMPLATE.format(module_name=module_name),
        "variables.tf": VARIABLES_TF_TEMPLATE,
        "versions.tf": VERSIONS_TF_TEMPLATE.format(terraform_version=terraform_version),
    }

    if with_outputs:
        files_to_create["outputs.tf"] = OUTPUTS_TF_TEMPLATE

    # Create files
    created_files = []
    for filename, content in files_to_create.items():
        file_path = directory / filename
        file_path.write_text(content)
        created_files.append(str(file_path))

    return created_files


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Create an empty Terraform module with template files.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""\
Examples:
  %(prog)s modules/my_new_module
  %(prog)s -p modules/nested/deep/module
  %(prog)s -o modules/module_with_outputs
  %(prog)s -p -o modules/full_module
""",
    )

    parser.add_argument(
        "directory",
        type=Path,
        help="Target directory path for the new module",
    )

    parser.add_argument(
        "-p",
        "--parents",
        action="store_true",
        help="Create parent directories if they don't exist (like mkdir -p)",
    )

    parser.add_argument(
        "-o",
        "--with-outputs",
        action="store_true",
        help="Include an outputs.tf file in the module",
    )

    args = parser.parse_args()

    try:
        created_files = create_module(
            directory=args.directory,
            parents=args.parents,
            with_outputs=args.with_outputs,
        )

        print(f"Created Terraform module at: {args.directory.resolve()}")
        print("Files created:")
        for file_path in created_files:
            print(f"  - {Path(file_path).name}")

        return 0

    except FileExistsError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    except OSError as e:
        print(f"Error creating module: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
