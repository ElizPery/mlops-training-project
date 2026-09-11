# Operational Runbook

This document outlines standard operating procedures for maintaining the MLOps platform.

## 1. How to Roll Out a New Model Version

Models can be updated automatically through GitHub Actions (`train.yml` and `promote.yml`) or manually:

1. Run training: `python src/training/train.py`
2. Promote the model to production: `python src/training/promote.py`
3. Build and push the new inference container image:

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 851725342702.dkr.ecr.us-east-1.amazonaws.com
docker build --platform linux/amd64 -t inference-service:v1.0.0 ./src/inference
docker tag inference-service:v1.0.0 851725342702.dkr.ecr.us-east-1.amazonaws.com/inference-service:v1.0.0
docker push 851725342702.dkr.ecr.us-east-1.amazonaws.com/inference-service:v1.0.0
```

4. Check deployment:

```bash
kubectl port-forward svc/inference-service 8000:8000 -n production
curl -s -H "Connection: close" -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'
```

## 2. How to Perform a Rollback

For the production environment, a Blue-Green deployment strategy is implemented via Kubernetes Service selector updates. To switch traffic back (e.g., from `green` to `blue`):

```bash
kubectl patch service inference-service -n production \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

## 3. What to Do If Grafana Shows Latency > X

- **Diagnosis via Prometheus/Grafana Metrics**:
Check pod CPU utilization using the Grafana query:

```bash
sum(rate(container_cpu_usage_seconds_total{namespace="production", pod=~"inference-service-.*", container!=""}[5m])) by (pod)
```

- **Mitigation**:
1. Inspect resource limits (`requests`/`limits`) in deployment manifests (`deployment-blue.yaml` / `deployment-green.yaml`).
2. Scale up replica counts or investigate model internal bottlenecks.

## 4. What to Do If Evidently Shows Data Drift

The Evidently CronJob (`evidently-iris-drift-checker`) runs daily at 2:00 AM UTC to check data drift and push metrics to the Pushgateway.

- **Mitigation**:
1. Check pod logs or the Evidently output report.
2. If data drift is critical, trigger model retraining using `train.py`, then follow the model promotion workflow to roll out a new version.

## 5. How to Delete All Infrastructure

To prevent dependency errors, destroy cloud resources in strict reverse order (destroying EKS before VPC):

```bash
# 1. Destroy Argo CD and ECR
cd terraform/argocd && terraform destroy
cd ../ecr && terraform destroy

# 2. Destroy EKS Cluster
cd ../eks && terraform destroy

# 3. Destroy VPC Network
cd ../vpc && terraform destroy
```