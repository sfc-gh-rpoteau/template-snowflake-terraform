-- ============================================================
-- GitHub Actions OIDC — Workload Identity Federation
-- ============================================================
-- Snowflake's Workload Identity Federation (WIF) lets GitHub Actions
-- authenticate with short-lived OIDC tokens. No passwords, key-pairs,
-- or secret rotation required.
--
-- Prerequisites:
--   - ACCOUNTADMIN (or SECURITYADMIN + OWNERSHIP on users)
--   - Roles from setup_terraform.sql already created
--   - A GitHub environment matching each SUBJECT claim
--
-- Placeholders to replace:
--   <YOUR_GITHUB_ORG>   — GitHub organization name  (case-sensitive)
--   <YOUR_GITHUB_REPO>  — repository name            (case-sensitive)
--
-- References:
--   https://docs.snowflake.com/en/user-guide/workload-identity-federation
--   https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect
-- ============================================================

USE ROLE SECURITYADMIN;

-- ============================================================
-- 1. Service user for Terraform (single user, multiple roles)
-- ============================================================
-- An OIDC token carries a single `sub` claim that maps to exactly
-- one Snowflake user. Duty separation is enforced through Snowflake
-- roles, not separate users — each Terraform provider alias connects
-- as this user but activates a different role.
--
-- The SUBJECT must exactly match the `sub` claim in the GitHub
-- OIDC token. Format: repo:<org>/<repo>:environment:<env_name>

CREATE USER IF NOT EXISTS TF_GITHUB_USER
  TYPE = SERVICE
  DEFAULT_ROLE = TF_ADMIN_ROLE
  COMMENT = 'GitHub Actions service user for Terraform (OIDC)'
  WORKLOAD_IDENTITY = (
    TYPE = OIDC
    ISSUER = 'https://token.actions.githubusercontent.com'
    SUBJECT = 'repo:<YOUR_GITHUB_ORG>/<YOUR_GITHUB_REPO>:environment:development'
  );

GRANT ROLE TF_ADMIN_ROLE TO USER TF_GITHUB_USER;
GRANT ROLE TF_SECURITYADMIN_ROLE TO USER TF_GITHUB_USER;

-- ============================================================
-- 2. (Optional) Additional environment users
-- ============================================================
-- For production, create a separate user pinned to the production
-- environment. A dev workflow can never assume a prod identity.
--
-- CREATE USER IF NOT EXISTS TF_GITHUB_USER_PROD
--   TYPE = SERVICE
--   DEFAULT_ROLE = TF_ADMIN_ROLE
--   COMMENT = 'GitHub Actions service user for Terraform (prod)'
--   WORKLOAD_IDENTITY = (
--     TYPE = OIDC
--     ISSUER = 'https://token.actions.githubusercontent.com'
--     SUBJECT = 'repo:<YOUR_GITHUB_ORG>/<YOUR_GITHUB_REPO>:environment:production'
--   );
--
-- GRANT ROLE TF_ADMIN_ROLE TO USER TF_GITHUB_USER_PROD;
-- GRANT ROLE TF_SECURITYADMIN_ROLE TO USER TF_GITHUB_USER_PROD;

-- ============================================================
-- 3. (Optional) Harden with an authentication policy
-- ============================================================
-- Restricts this service user to only authenticate via GitHub's
-- OIDC provider — blocks any other auth method.

-- USE ROLE ACCOUNTADMIN;
--
-- CREATE OR REPLACE AUTHENTICATION POLICY github_oidc_only
--   WORKLOAD_IDENTITY_POLICY = (
--     ALLOWED_PROVIDERS = (OIDC)
--     ALLOWED_OIDC_ISSUERS = ('https://token.actions.githubusercontent.com')
--   );
--
-- ALTER USER TF_GITHUB_USER
--   SET AUTHENTICATION POLICY = github_oidc_only;

-- ============================================================
-- Verification & troubleshooting
-- ============================================================

SHOW USER WORKLOAD IDENTITY AUTHENTICATION METHODS FOR USER TF_GITHUB_USER;
SHOW GRANTS TO USER TF_GITHUB_USER;

-- After a workflow run, check login history for OIDC sessions
-- SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
--   WHERE USER_NAME = 'TF_GITHUB_USER'
--   ORDER BY EVENT_TIMESTAMP DESC
--   LIMIT 20;
