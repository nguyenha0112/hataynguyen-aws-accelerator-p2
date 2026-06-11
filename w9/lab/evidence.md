# W9 Lab Evidence

## Scope

Evidence này ghi lại trạng thái lab sau khi chạy local trên minikube.

## 1. Minikube Và Kubernetes

Node minikube đã chạy và dùng được với `kubectl`.

Lệnh kiểm tra:

```powershell
minikube status
kubectl get nodes
```

Kỳ vọng:

```text
minikube Ready
```

## 2. ArgoCD

ArgoCD đã được cài trong namespace `argocd`.

Lệnh kiểm tra:

```powershell
kubectl get pods -n argocd
```

Kết quả đạt:

```text
argocd-application-controller   1/1 Running
argocd-applicationset-controller 1/1 Running
argocd-dex-server               1/1 Running
argocd-notifications-controller 1/1 Running
argocd-redis                    1/1 Running
argocd-repo-server              1/1 Running
argocd-server                   1/1 Running
```

ArgoCD UI:

```text
https://localhost:8080
```

## 3. GitOps Applications

Hai ArgoCD Application đã được tạo:

```powershell
kubectl get applications -n argocd
```

Kết quả đạt:

```text
NAME               SYNC STATUS   HEALTH STATUS
w9-mini-platform   Synced        Healthy
w9-rollout         Synced        Healthy
```

Ý nghĩa:

- `w9-mini-platform` quản lý namespace/config/service.
- `w9-rollout` quản lý Argo Rollouts canary resource.

## 4. Platform Resources

Lệnh kiểm tra:

```powershell
kubectl get all -n mini-platform
```

Kết quả đạt:

- Pod web đang `Running`.
- Service `web-stable` đã có.
- Service `web-canary` đã có.
- Service có endpoints.

Test HTTP:

```powershell
kubectl port-forward svc/web-stable -n mini-platform 8081:80
curl.exe http://localhost:8081
```

Kết quả đạt:

```text
Welcome to nginx!
```

## 5. Observability

OpenTelemetry Collector đã được apply trong namespace `observability`.

Lệnh đã chạy:

```powershell
kubectl create namespace observability
kubectl apply -f cloud\w9\W9-D2_Observability_SLO_OTel\otel\collector.yaml
kubectl -n observability rollout status deploy/otel-collector --timeout=180s
```

Kết quả đạt:

```text
deployment "otel-collector" successfully rolled out
```

Lệnh kiểm tra:

```powershell
kubectl get pods -n observability
```

Kết quả đạt:

```text
otel-collector-...   1/1   Running
```

## 6. SLO Alert Rule

Lệnh apply PrometheusRule:

```powershell
kubectl apply -f cloud\w9\W9-D2_Observability_SLO_OTel\alert-rules\slo-burn-rate.yaml
```

Kết quả local:

```text
no matches for kind "PrometheusRule" in version "monitoring.coreos.com/v1"
ensure CRDs are installed first
```

Kết luận:

- File SLO rule đã có trong repo.
- Local cluster chưa cài Prometheus Operator nên chưa có CRD `prometheusrules.monitoring.coreos.com`.
- Theo checklist lab, phần này được ghi chú là local stack chưa hỗ trợ PrometheusRule.

Muốn chạy đầy đủ alert rule thật, cần cài kube-prometheus-stack hoặc Prometheus Operator trước.

## 7. Argo Rollouts Canary

Argo Rollouts controller đã được cài trong namespace `argo-rollouts`.

Lệnh đã chạy:

```powershell
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
kubectl get pods -n argo-rollouts
```

Kết quả đạt:

```text
argo-rollouts-...   1/1   Running
```

Rollout resource:

```powershell
kubectl get rollout -n mini-platform
```

Kết quả đạt:

```text
NAME   DESIRED   CURRENT   UP-TO-DATE   AVAILABLE
web    3         3         3            3
```

Rollout detail:

```powershell
kubectl describe rollout web -n mini-platform
```

Kết quả đạt:

```text
Phase: Healthy
Message: RolloutCompleted
Reason: RolloutHealthy
```

AnalysisTemplate:

```powershell
kubectl get analysistemplate -n mini-platform
```

Kết quả đạt:

```text
web-error-rate
```

Lưu ý:

- Rollout hiện tại là initial deploy nên chưa có `AnalysisRun`.
- Để sinh `AnalysisRun`, cần tạo một revision mới, ví dụ đổi image tag rồi để rollout đi qua các bước analysis.
- Vì local chưa có Prometheus backend thật, analysis Prometheus có thể fail nếu chưa cài monitoring stack.

## 8. Checklist Kết Luận

| Yêu cầu | Trạng thái | Ghi chú |
|---|---|---|
| ArgoCD app Synced/Healthy | Đạt | `w9-mini-platform`, `w9-rollout` đều xanh |
| Web service phản hồi | Đạt | `curl localhost:8081` trả nginx page |
| OTel Collector | Đạt | Pod `otel-collector` Running |
| PrometheusRule/SLO | Ghi chú hợp lệ | Thiếu Prometheus Operator CRD trong local |
| Argo Rollouts controller | Đạt | Pod `argo-rollouts` Running |
| Canary Rollout healthy | Đạt | Rollout `web` Healthy/Completed |
| AnalysisTemplate tồn tại | Đạt | `web-error-rate` tồn tại |
| Bad canary abort | Chưa chạy | Cần monitoring backend hoặc test cố ý fail |

## 9. Kết Luận Ngắn

Lab 1-7 đã đạt phần chạy chính:

- GitOps qua ArgoCD hoạt động.
- Platform app sync từ Git về cluster.
- Argo Rollouts đã quản lý workload canary.
- Observability collector đã chạy.

Phần chưa chạy sâu là PrometheusRule evaluation và bad canary abort, vì local cluster chưa có Prometheus Operator/Prometheus backend.
