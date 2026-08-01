# Azure release checks

Use for App Service, Functions, Container Apps, AKS, deployment slots, managed identity, Key Vault, ingress, or scaling changes.

## Verify

- Exact tenant, subscription, resource group, region, environment, resource, revision, and artifact
- Managed identity, Key Vault references, app and slot settings, ingress, authentication, and network access
- Startup, health probes, triggers, background work, scaling, timeout, and dependency-failure behavior
- Slot, revision, canary, or staged traffic progression and reversal
- Schema and configuration compatibility across old and new revisions

Treat missing subscription, resource, slot, identity, control-plane, or live-runtime evidence as `INDETERMINATE`.
