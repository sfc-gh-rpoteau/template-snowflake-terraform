USE ROLE SECURITYADMIN;

/***
Create Terraform admin role and user.
***/

CREATE ROLE IF NOT EXISTS TF_ADMIN_ROLE
    COMMENT = 'Role to exclusively for Terraform admin user';

CREATE USER IF NOT EXISTS TF_ADMIN_USER
    PASSWORD = NULL
    COMMENT = 'User for Terraform automation'
    DEFAULT_ROLE = TF_ADMIN_ROLE
    MUST_CHANGE_PASSWORD = false;

GRANT ROLE TF_ADMIN_ROLE TO USER TF_ADMIN_USER;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE TF_ADMIN_ROLE;

/***
Create Terraform security admin user.
***/

CREATE ROLE IF NOT EXISTS TF_SECURITYADMIN_ROLE
    COMMENT = 'Role to exclusively for Terraform security admin user';

CREATE USER IF NOT EXISTS TF_SECURITYADMIN_USER
    PASSWORD = NULL
    COMMENT = 'User for Terraform automation'
    DEFAULT_ROLE = TF_SECURITYADMIN_ROLE
    MUST_CHANGE_PASSWORD = false;

GRANT ROLE TF_SECURITYADMIN_ROLE TO USER TF_SECURITYADMIN_USER;
GRANT MANAGE GRANTS ON ACCOUNT TO ROLE TF_SECURITYADMIN_ROLE;

/***
Set up key-pair auth for the Terraform admin and security admin users
***/

ALTER USER TF_ADMIN_USER
  SET RSA_PUBLIC_KEY='<RSA_PUBLIC_KEY from rsa_key_tf_admin.pub>';

-- Copy output for comparision (OPTIONAL)
DESC USER TF_ADMIN_USER
  ->> SELECT SUBSTR(
        (SELECT "value" FROM $1
           WHERE "property" = 'RSA_PUBLIC_KEY_FP'),
        LEN('SHA256:') + 1) AS key;

ALTER USER TF_SECURITYADMIN_USER
  SET RSA_PUBLIC_KEY='<RSA_PUBLIC_KEY from rsa_key_tf_securityadmin.pub>';

-- Copy output for comparision (OPTIONAL)
DESC USER TF_SECURITYADMIN_USER
  ->> SELECT SUBSTR(
        (SELECT "value" FROM $1
           WHERE "property" = 'RSA_PUBLIC_KEY_FP'),
        LEN('SHA256:') + 1) AS key;

GRANT CREATE DATABASE ON ACCOUNT TO ROLE TF_ADMIN_ROLE;