/***
Create virtual warehouse for the Terraform user (OPTIONAL)
***/

CREATE WAREHOUSE TF_ADMIN_VW
WITH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60 -- Auto-suspends after 60 seconds of inactivity
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE -- Starts suspended to avoid immediate charges
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 1 -- No multi-cluster needed for DDL
  STATEMENT_TIMEOUT_IN_SECONDS = 3600 -- Recommended timeout for DDL operations
  COMMENT = 'Warehouse for Terraform Infrastructure as Code (IaC) operations.';
  

GRANT USAGE ON WAREHOUSE TF_ADMIN_VW TO ROLE TF_ADMIN_ROLE;
GRANT USAGE ON WAREHOUSE TF_ADMIN_VW TO ROLE TF_SECURITYADMIN_ROLE;