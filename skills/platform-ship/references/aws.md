# AWS release checks

Use for Lambda, ECS, EKS, App Runner, API Gateway, CloudFront, IAM, Secrets Manager, SSM, networking, or AWS data-plane changes.

## Verify

- Exact account, region, environment, service, artifact, role, policy, secret or parameter path, and configuration revision
- VPC, subnet, security group, ingress, egress, DNS, event source, and downstream permissions
- Startup, health, timeout, memory, concurrency, autoscaling, queue, and retry behavior
- Canary, weighted, blue/green, or other traffic progression with health gates
- Migration, consumer, and configuration compatibility during partial rollout

Treat missing account, region, control-plane, identity, or live-runtime evidence as `INDETERMINATE`.
