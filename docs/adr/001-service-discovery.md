## ADR 001: K8s DNS instead of Eureka/Consul

**Status**: Accepted

**Context**:

* Requires service-to-service discovery within a microservices architecture.
* The Spring Cloud ecosystem typically uses Eureka.

**Decision**:
Use native K8s DNS. Every service is reachable via:
`http://{service-name}.{namespace}.svc.cluster.local`

**Consequences**:

* **No additional Eureka server needed:** Reduces infrastructure overhead by having one less service to maintain.
* **Cluster-bound discovery:** Service discovery only works within the cluster, which is acceptable since all services are hosted in K8s.
* **Local development adjustment:** When local development requires cross-service communication, developers must use `kubectl port-forward` or Telepresence.