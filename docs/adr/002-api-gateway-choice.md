## ADR 002: Kong as the API Gateway

**Status**: Accepted

**Decision**:
Use Kong Ingress Controller — managed via declarative configuration using K8s Ingress resources, eliminating the need for the Kong Admin API in production.

Plugins to be used: rate-limiting, jwt, request-transformer.