# Arcus

A multi-tenant project & task management SaaS platform — Jira-lite with AI assistant,
built on a polyglot microservices architecture running on Kubernetes.

> Built as a portfolio project to demonstrate real-world distributed systems patterns:
> API Gateway, multi-tenancy, event-driven architecture, and AI integration.

---

## ✨ Features

- **Multi-tenant**: Tenant isolation via JWT claims — one platform, many teams
- **Project & Task Management**: Kanban board with drag-and-drop, priorities, due dates
- **AI Assistant**: Summarize tasks, suggest sub-tasks, chat with project context (Gemini)
- **Real-time Notifications**: Event-driven via Kafka + SSE push to client
- **Polyglot Stack**: TypeScript, Java, Python — each service in the right language
- **Production-grade Infra**: K8s-native, observable, horizontally scalable

---

## 🏗️ Architecture

```mermaid
graph TD
    %% Nodes
    Client[💻 TanStack Start Client]
    
    subgraph K8s_Cluster [SRE & Kubernetes Cluster Environment]
        Kong[🔀 Kong API Gateway<br><i>K8s Ingress Controller</i>]
        
        %% Services
        AuthSvc[🔐 Auth Service<br><i>Hono + Bun + better-auth</i>]
        UserSvc[👤 User Profile Service<br><i>Spring Boot + PostgreSQL</i>]
        TaskSvc[📋 Task/Project Service<br><i>Spring Boot + PostgreSQL</i>]
        AISvc[🤖 AI Assistant Service<br><i>Python FastAPI + Langchain</i>]
        NotiSvc[🔔 Notification Service<br><i>Spring Boot</i>]
        
        %% Event Broker
        Kafka[💽 Apache Kafka Event Broker<br><i>Strimzi K8s Operator</i>]
    end

    %% Flow Connections
    Client -->|HTTP / Stream| Kong
    
    Kong -->|/api/auth/*| AuthSvc
    Kong -->|/api/users/*| UserSvc
    Kong -->|/api/tasks/*| TaskSvc
    Kong -->|/api/ai/*| AISvc
    
    %% Internal Communication via K8s DNS
    UserSvc -->|Internal K8s DNS| AuthSvc
    
    %% Async Event-Driven Flow
    AuthSvc -.->|Publish Events| Kafka
    UserSvc -.->|Publish Events| Kafka
    TaskSvc -.->|Publish Events| Kafka
    
    Kafka -.->|Consume Events| NotiSvc

    %% Styling
    classDef client fill:#38bdf8,stroke:#0284c7,stroke-width:2px,color:#000;
    classDef gateway fill:#fb923c,stroke:#ea580c,stroke-width:2px,color:#000;
    classDef service fill:#f8fafc,stroke:#64748b,stroke-width:2px,color:#000;
    classDef async fill:#e9d5ff,stroke:#9333ea,stroke-width:2px,color:#000;
    
    class Client client;
    class Kong gateway;
    class AuthSvc,UserSvc,TaskSvc,AISvc service;
    class Kafka,NotiSvc async;
```

**Service Discovery**: Kubernetes DNS (`svc.cluster.local`) — no Eureka needed  
**Config Management**: K8s ConfigMaps + Secrets + Spring Cloud Kubernetes  
**Gateway**: Kong on K8s (declarative via `deck`)  
**Local Dev**: Kind cluster + Docker  
**Deploy**: Kind local → any cloud K8s (GKE / EKS / AKS)

---

## 🗂️ Monorepo Structure

```
arcus/
├── services/
│   ├── auth-service/           # Hono + Bun + better-auth
│   ├── user-profile-service/   # Spring Boot 3 + PostgreSQL
│   ├── task-service/           # Spring Boot 3 + PostgreSQL (core domain)
│   ├── ai-service/             # Python FastAPI + Gemini API
│   └── notification-service/   # Spring Boot 3 + Kafka consumer
├── client/                     # TanStack Start (React)
├── infra/
│   ├── k8s/
│   │   ├── base/               # Shared manifests (Namespace, ConfigMap)
│   │   ├── overlays/
│   │   │   ├── local/          # Kind — NodePort, local images
│   │   │   ├── gke/            # Google Kubernetes Engine
│   │   │   ├── eks/            # AWS EKS
│   │   │   └── aks/            # Azure AKS
│   │   ├── gateway/            # Kong Ingress + Plugin configs
│   │   └── services/           # Deployment + Service manifests
│   └── scripts/
│       ├── setup-local.sh      # Linux / macOS
│       └── setup-local.ps1     # Windows PowerShell
├── docs/
│   └── adr/                    # Architecture Decision Records
└── Makefile
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version | Install |
|---|---|---|
| Docker Desktop | Latest | [docker.com](https://www.docker.com/products/docker-desktop) |
| kind | ≥ 0.23 | `brew install kind` / `winget install sigs.kind` |
| kubectl | ≥ 1.30 | `brew install kubectl` |
| Helm | ≥ 3.15 | `brew install helm` |
| Bun | ≥ 1.1 | `curl -fsSL https://bun.sh/install \| bash` |
| Java | 21 | [Adoptium](https://adoptium.net) |

> **Windows users**: Enable WSL2 backend in Docker Desktop → Settings → General

---

### Local Setup

**1. Clone the repo**

```bash
git clone https://github.com/your-username/arcus.git
cd arcus
```

**2. Create the local cluster and install Kong**

```bash
# Linux / macOS
./infra/scripts/setup-local.sh

# Windows (PowerShell as Administrator)
.\infra\scripts\setup-local.ps1
```

Or manually:

```bash
kind create cluster --config infra/k8s/kind-config.yaml
helm repo add kong https://charts.konghq.com && helm repo update
helm install kong kong/ingress --namespace kong --create-namespace
```

**3. Set up secrets**

```bash
kubectl create secret generic arcus-secrets \
  --namespace arcus \
  --from-literal=JWT_SECRET="your-jwt-secret" \
  --from-literal=DB_URL="jdbc:postgresql://postgres.arcus.svc.cluster.local:5432/arcus" \
  --from-literal=DB_USER="arcus" \
  --from-literal=DB_PASSWORD="your-db-password" \
  --from-literal=AUTH_DB_URL="postgresql://arcus:password@postgres.arcus.svc.cluster.local:5432/arcus_auth" \
  --from-literal=GEMINI_API_KEY="your-gemini-key"
```

**4. Build and deploy**

```bash
make build    # Build all Docker images & load into Kind
make deploy   # Apply all K8s manifests
```

**5. Start the client dev server**

```bash
cd client
bun install
bun dev
```

Open [http://localhost:3001](http://localhost:3001) — API gateway is at [http://localhost:8080](http://localhost:8080).

---

### Makefile Reference

```bash
make up           # Create cluster + install Kong + deploy everything
make down         # Destroy local cluster
make build        # Build all images and load into Kind
make deploy       # Apply K8s manifests (base + local overlay + gateway)
make reload-auth  # Rebuild & hot-reload auth-service only
make reload-task  # Rebuild & hot-reload task-service only
make logs-auth    # Tail auth-service logs
make logs-task    # Tail task-service logs
```

---

## ☁️ Deploy to Cloud

The overlay structure means deploying to any cloud is a single command
after pointing `kubectl` at the target cluster.

```bash
# Google Kubernetes Engine
gcloud container clusters get-credentials arcus-cluster --region asia-southeast1
kubectl apply -k infra/k8s/overlays/gke/

# AWS EKS
aws eks update-kubeconfig --name arcus-cluster --region ap-southeast-1
kubectl apply -k infra/k8s/overlays/eks/

# Azure AKS
az aks get-credentials --resource-group arcus-rg --name arcus-cluster
kubectl apply -k infra/k8s/overlays/aks/
```

The only difference between environments is the overlay — `base/` manifests
are never modified.

---

## 📡 API Reference

All requests go through Kong at `/api/*`. Auth routes are public;
all others require a valid session cookie set by `better-auth`.

Kong automatically injects `X-User-Id`, `X-Tenant-Id`, and `X-User-Role`
headers from JWT claims before forwarding to downstream services.

| Method | Path | Service | Auth |
|---|---|---|---|
| POST | `/api/auth/sign-up` | auth-service | Public |
| POST | `/api/auth/sign-in` | auth-service | Public |
| POST | `/api/auth/sign-out` | auth-service | Public |
| GET | `/api/users/me` | user-profile-service | Required |
| PUT | `/api/users/me` | user-profile-service | Required |
| GET | `/api/tasks/projects` | task-service | Required |
| POST | `/api/tasks/projects` | task-service | Required |
| GET | `/api/tasks/projects/:id/tasks` | task-service | Required |
| POST | `/api/tasks/tasks` | task-service | Required |
| PUT | `/api/tasks/tasks/:id` | task-service | Required |
| DELETE | `/api/tasks/tasks/:id` | task-service | Required |
| POST | `/api/ai/summarize` | ai-service | Required |
| POST | `/api/ai/suggest` | ai-service | Required |
| POST | `/api/ai/chat` | ai-service | Required |

---

## 🗺️ Roadmap

| Phase | Focus | Status |
|---|---|---|
| **Phase 0** | K8s + Kong local foundation | ✅ Done |
| **Phase 1** | Auth, Projects, Tasks, Kanban UI | 🔨 In progress |
| **Phase 2** | Rate limiting, health checks, structured logging, mTLS | ⬜ Planned |
| **Phase 3** | Kafka, event-driven notifications, SSE | ⬜ Planned |
| **Phase 4** | AI assistant (Gemini, RAG, streaming) | ⬜ Planned |
| **Phase 5** | Prometheus, Grafana, OpenTelemetry, HPA | ⬜ Planned |

---

## 🧩 Architecture Decisions

All significant design choices are documented as ADRs in [`docs/adr/`](./docs/adr/).

| ADR | Decision |
|---|---|
| [ADR-001](docs/adr/001-api-gateway.md) | Kong over custom gateway |
| [ADR-002](docs/adr/002-service-discovery.md) | K8s DNS over Eureka |
| [ADR-003](docs/adr/003-auth.md) | better-auth + Hono over Spring Security |
| [ADR-004](docs/adr/004-multi-tenancy.md) | Tenant isolation via JWT claims + shared DB |
| [ADR-005](docs/adr/005-config.md) | K8s ConfigMap + Spring Cloud K8s over Config Server |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | TanStack Start, TanStack Query, React |
| **Auth Service** | Hono, Bun, better-auth |
| **Task Service** | Spring Boot 3, Spring Data JPA, Flyway |
| **User Service** | Spring Boot 3, Spring Data JPA |
| **AI Service** | Python, FastAPI, Gemini API |
| **Notification** | Spring Boot 3, Kafka consumer |
| **Database** | PostgreSQL 16 (one schema per service) |
| **Message Bus** | Apache Kafka (Strimzi on K8s) |
| **API Gateway** | Kong (K8s Ingress mode) |
| **Container** | Docker, Kind |
| **Orchestration** | Kubernetes, Kustomize, Helm |
| **Observability** | Prometheus, Grafana, OpenTelemetry, Tempo |

---

## 📄 License

MIT — see [LICENSE](./LICENSE) for details.
