# Supabase release checks

Use for Postgres migrations, RLS, authentication, Edge Functions, storage policies, secrets, or client/server contract changes.

## Verify

- Exact organization, project, environment, database revision, migration set, function artifact, and configuration
- Expand-contract migration safety, old-client compatibility, backups, destructive DDL boundary, and recovery limits
- RLS coverage across anon, authenticated, service-role, tenant, and administrative paths
- Auth provider, redirect, token, storage policy, signed URL, function secret, and local-versus-hosted parity
- Logs, database health, function telemetry, feature kill switch, and migration stop conditions

Treat missing project, schema, policy, function, control-plane, or live-runtime evidence as `INDETERMINATE`.
