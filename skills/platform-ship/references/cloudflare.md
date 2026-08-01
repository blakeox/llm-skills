# Cloudflare release checks

Use for Workers, Pages, routes, KV, R2, D1, Queues, Durable Objects, bindings, secrets, or edge configuration.

## Verify

- Exact account, project or Worker, environment, deployment version, routes, domains, and artifact
- Every binding name and target across preview and production
- Route blast radius, cache behavior, traffic cutover, and prior-version restoration
- KV consistency assumptions, D1 migration safety, Durable Object compatibility, and Queue retry or idempotency
- Logs, analytics, tail evidence, alarms, and route or feature kill switch

Treat missing account, route, binding, control-plane, or live-runtime evidence as `INDETERMINATE`.
