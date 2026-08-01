# Google Cloud release checks

Use for Cloud Run, GKE, GCE, App Engine, Cloud Functions, IAM, Secret Manager, load balancers, or Google Cloud networking.

## Verify

- Exact organization or project, region, environment, service, revision, artifact, and service account
- IAM bindings, secret access, ingress, egress, VPC, load balancer, and downstream permissions
- Startup, health, timeout, concurrency, memory, autoscaling, and burst behavior
- Canary, gradual, blue/green, or revision traffic movement with health gates
- Data and configuration compatibility during partial rollout and reversal

Treat missing project, region, identity, control-plane, or live-runtime evidence as `INDETERMINATE`.
