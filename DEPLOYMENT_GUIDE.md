# Deployment guide

## Local development (works today)
Prereqs: Node 22+, pnpm 10, Docker.
```bash
cp .env.example .env
docker compose up -d            # Postgres 16 + Redis 7
pnpm install
pnpm db:migrate                 # applies packages/db/migrations
psql "$DATABASE_URL" -f packages/db/test/integrity.sql   # expect ALL PASS
pnpm --filter @quickcred/api build && pnpm --filter @quickcred/api start   # http://localhost:4000/v1/health, /docs
pnpm dev:web                    # http://localhost:3000
```

## Target production topology (Phase 6, not built)
- AWS **ap-south-1 (Mumbai)** primary, **ap-south-2 (Hyderabad)** DR: all data stays in India.
- ECS Fargate (api, workers, web) behind ALB + AWS WAF; CloudFront for static assets.
- RDS PostgreSQL 16 Multi-AZ, encrypted, PITR; ElastiCache Redis; S3 with SSE-KMS; KMS CMKs; Secrets Manager.
- GitHub Actions: CI on PR; deploy on tag via OIDC role (no long-lived AWS keys); migrations run as a one-off task before rollout.
- Observability: OpenTelemetry → collector, Sentry with PII scrubbing, CloudWatch logs retained ≥ 180 days.
- Environments: `local` (mock), `staging` (mock + vendor sandboxes), `production` (live only per lender authorization).
