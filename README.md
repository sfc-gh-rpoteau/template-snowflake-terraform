# Template: Snowflake Infrastructure Management with Terraform

## New Project Setup

To get started we'll need to set up some resources in Snowflake and your development environment to allow Terraform to communicate with your Snowflake instance. Additionally, we'll need to set up some resources in a cloud provider so we can have remote state tracking and locking.

### Snowflake Users and Roles Setup

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


# References

[[1] Snowflake Documentation: Key-pair authentication and key-pair rotation](https://docs.snowflake.com/en/user-guide/key-pair-auth)
