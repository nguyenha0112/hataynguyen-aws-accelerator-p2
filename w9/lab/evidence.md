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

Kết quả ban đầu nếu chưa có CRD:

```text
no matches for kind "PrometheusRule" in version "monitoring.coreos.com/v1"
ensure CRDs are installed first
```

Sau đó đã cài CRD `PrometheusRule` từ Prometheus Operator và apply rule thành công.

Lệnh đã chạy:

```powershell
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
kubectl apply -f cloud\w9\W9-D2_Observability_SLO_OTel\alert-rules\slo-burn-rate.yaml
kubectl get prometheusrule -n observability
```

Kết quả đạt:

```text
NAME                AGE
web-slo-burn-rate   ...
```

Kết luận:

- File SLO rule đã có trong repo.
- Local cluster đã có CRD `prometheusrules.monitoring.coreos.com`.
- `PrometheusRule` đã tồn tại trong namespace `observability`.

Lưu ý: lab local dùng CRD và rule manifest để chứng minh phần SLO alert. Để evaluate alert giống production, cần Prometheus/Alertmanager đầy đủ.

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

AnalysisRun pass đã được tạo khi rollout đổi revision sang `nginx:1.28`.

Lệnh kiểm tra:

```powershell
kubectl get analysisrun -n mini-platform
```

Kết quả có các run thành công:

```text
web-bf89c9c96-2-2   Successful
web-bf89c9c96-2-5   Successful
```

## 8. Bad Canary Abort

Để tạo bad canary có kiểm soát trong local lab:

- Fake Prometheus service `prometheus-operated` được cấu hình trả error-rate `1`.
- `AnalysisTemplate` dùng `successCondition: result[0] < 0.05`.
- Rollout được đổi revision để bắt đầu canary mới.

Kết quả:

```powershell
kubectl get analysisrun -n mini-platform
```

Có AnalysisRun fail:

```text
web-58564bfd85-5-2   Failed
```

Rollout detail:

```powershell
kubectl describe rollout web -n mini-platform
```

Evidence abort:

```text
Abort: true
Phase: Degraded
RolloutAborted: Rollout aborted update to revision 5
Metric "error-rate" assessed Failed due to failed (1) > failureLimit (0)
```

Sau khi ghi evidence, repo được restore về fake Prometheus trả `0` và image stable `nginx:1.28`. Trạng thái cuối:

```text
w9-mini-platform   Synced   Healthy
w9-rollout         Synced   Healthy
```

## 9. Checklist Kết Luận

| Yêu cầu | Trạng thái | Ghi chú |
|---|---|---|
| ArgoCD app Synced/Healthy | Đạt | `w9-mini-platform`, `w9-rollout` đều xanh |
| Web service phản hồi | Đạt | `curl localhost:8081` trả nginx page |
| OTel Collector | Đạt | Pod `otel-collector` Running |
| PrometheusRule/SLO | Đạt | CRD đã cài, `web-slo-burn-rate` tồn tại |
| Argo Rollouts controller | Đạt | Pod `argo-rollouts` Running |
| Canary Rollout healthy | Đạt | Rollout `web` Healthy/Completed |
| AnalysisTemplate tồn tại | Đạt | `web-error-rate` tồn tại |
| AnalysisRun pass | Đạt | Có AnalysisRun `Successful` |
| Bad canary abort | Đạt | Có AnalysisRun `Failed`, rollout từng `Abort: true` |

## 10. Kết Luận Ngắn

Lab 1-7 đã đạt đầy đủ:

- GitOps qua ArgoCD hoạt động.
- Platform app sync từ Git về cluster.
- Argo Rollouts đã quản lý workload canary.
- Observability collector đã chạy.
- PrometheusRule đã apply được sau khi cài CRD.
- AnalysisRun pass đã có.
- Bad canary abort đã được chứng minh.
- Trạng thái cuối đã restore về `Synced/Healthy`.
