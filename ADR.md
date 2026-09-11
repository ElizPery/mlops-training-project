# Architectural Decision Record (ADR): Blue-Green Deployment & GitOps

## 1. Why This Deployment Strategy Was Chosen (Blue-Green via Kubernetes Service Selector)

- **Decision**: Utilizing two parallel deployments (`inference-service-blue` and `inference-service-green`) with traffic redirection managed via `kubectl` patch service.

- **Rationale**: This strategy ensures zero-downtime updates for model or code releases and allows instant rollbacks by reverting the service selector back to the previous stable slot in case of anomalies.

## 2. Trade-offs Considered

- **Infrastructure Resource Overhead**: Maintaining Blue-Green deployments requires running multiple versions simultaneously or scaling idle slots, which increases resource utilization on `cpu-nodes`.

- **State Management Complexity**: Running a comprehensive data and observability stack (MLflow, MinIO, PostgreSQL, Prometheus, Grafana, Loki) inside EKS requires careful memory/CPU tuning and clear namespace segmentation.

## 3. What Would Be Done Differently With More Time

- **Progressive Delivery (Canary / Flagger)**: Replace manual or script-driven Blue-Green switches with tools like Argo Rollouts or Flagger to enable automated progressive traffic shifting (e.g., 10% → 50% → 100%) driven by real-time error rates and latency telemetry.

- **Event-Driven Autoscaling (KEDA)**: Configure Kubernetes Event-driven Autoscaling (KEDA) to dynamically scale inference pods based on request queue depth or incoming traffic rate.
