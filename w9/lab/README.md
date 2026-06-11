# W9 Lab - GitOps-ify W8 Platform + Observability + Canary

## Muc Tieu

Lab nay noi ca 3 ngay cua W9 vao mot luong thuc hanh:

- Tao platform namespace va manifest co ban.
- De ArgoCD quan ly platform theo GitOps.
- Cai OpenTelemetry Collector va SLO alert rule.
- Chay Argo Rollouts canary cho web workload.
- Kiem tra rollout, analysis, abort/rollback.

Ket qua mong muon: ban co the giai thich duoc tu commit trong Git den thay doi trong cluster, cach quan sat service, va cach canary quyet dinh promote/abort.

## Kien Truc Lab

```text
Git repo
  -> ArgoCD Applications
      -> manifests/ namespace, config, service
      -> rollout/ Rollout va AnalysisTemplate
  -> Observability
      -> OTel Collector
      -> PrometheusRule SLO burn-rate
  -> Argo Rollouts
      -> Canary rollout cho web
```

## Thu Muc

| Path | Vai tro |
|---|---|
| `manifests/` | Namespace, ConfigMap, Service nen tang |
| `argocd/` | ArgoCD Applications tro ve cac path trong repo |
| `rollout/` | Rollout va AnalysisTemplate cho canary |
| `../W9-D2_Observability_SLO_OTel/otel/` | OpenTelemetry Collector |
| `../W9-D2_Observability_SLO_OTel/alert-rules/` | Burn-rate alert rule |

## Dieu Kien Truoc Khi Chay

Can co:

- Docker Desktop hoac container runtime cho minikube.
- `kubectl`.
- `minikube`.
- ArgoCD controller neu muon dung GitOps sync.
- Argo Rollouts controller neu muon dung `Rollout`.
- Monitoring stack neu muon apply `PrometheusRule` that su.

Luu y: mot so manifest co the can sua `CHANGE_ME` repo URL truoc khi ArgoCD clone duoc repo cua ban.

## Buoc 1 - Start Minikube

```powershell
minikube start
kubectl cluster-info
kubectl get nodes
```

Can thay node o trang thai `Ready`.

## Buoc 2 - Apply Platform Manifest Co Ban

```powershell
kubectl apply -f manifests/
kubectl get all -n mini-platform
```

Neu service chua co endpoint, kiem tra selector cua Service co khop label cua workload khong.

## Buoc 3 - Cai ArgoCD

Neu chua cai:

```powershell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd
```

Cho den khi cac pod ArgoCD `Running`.

## Buoc 4 - Apply ArgoCD Applications

Truoc khi apply, mo file trong `argocd/` va sua repo URL neu dang la placeholder.

```powershell
kubectl apply -f argocd/
kubectl get applications -n argocd
```

Kiem tra chi tiet:

```powershell
kubectl describe application platform-app -n argocd
kubectl describe application rollout-app -n argocd
```

Trang thai tot:

- `Synced`.
- `Healthy`.

Neu `OutOfSync`, xem message va source path.

## Buoc 5 - Cai Observability Resources

```powershell
kubectl create namespace observability
kubectl apply -f ../W9-D2_Observability_SLO_OTel/otel/
kubectl apply -f ../W9-D2_Observability_SLO_OTel/alert-rules/
kubectl get pods -n observability
```

Neu gap loi `no matches for kind PrometheusRule`, nghia la cluster chua co Prometheus Operator CRD. Khi do:

- Cai kube-prometheus-stack, hoac
- Tam thoi bo qua alert rule va chi hoc file YAML, hoac
- Chuyen rule sang format Prometheus native tuy monitoring stack.

## Buoc 6 - Cai Argo Rollouts

```powershell
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
kubectl get pods -n argo-rollouts
```

Can thay controller running.

## Buoc 7 - Apply Canary Rollout

```powershell
kubectl apply -f rollout/
kubectl get rollout -n mini-platform
kubectl get analysisrun -n mini-platform
```

Neu co plugin:

```powershell
kubectl argo rollouts get rollout web -n mini-platform --watch
```

## Buoc 8 - Quan Sat Web Service

Port-forward service:

```powershell
kubectl port-forward svc/web -n mini-platform 8080:80
```

Kiem tra:

```powershell
curl.exe http://localhost:8080
```

Neu service khong tra loi:

```powershell
kubectl get pods -n mini-platform
kubectl describe svc web -n mini-platform
kubectl get endpoints -n mini-platform
```

## Buoc 9 - Tao Canary Fail De Hoc Abort

Chon mot cach an toan trong moi truong local:

- Sua image sang tag khong ton tai.
- Sua threshold analysis thanh dieu kien chac chan fail.
- Sua app/config de tra ve loi neu app ho tro.

Sau do apply lai:

```powershell
kubectl apply -f rollout/
kubectl get analysisrun -n mini-platform
kubectl describe rollout web -n mini-platform
```

Neu co plugin:

```powershell
kubectl argo rollouts get rollout web -n mini-platform
kubectl argo rollouts abort web -n mini-platform
```

Ghi lai bang chung rollout bi abort.

## Buoc 10 - Rollback Theo GitOps

Neu thay doi xau den tu commit:

```powershell
git revert <bad_commit>
git push
```

Sau do de ArgoCD sync lai. Neu dang chay local chua co remote Git dung, ban co the sua lai manifest ve version tot va apply lai de hieu co che.

## Lenh Kiem Tra Tong Hop

```powershell
kubectl get all -n mini-platform
kubectl get applications -n argocd
kubectl get pods -n observability
kubectl get rollout -n mini-platform
kubectl get analysisrun -n mini-platform
kubectl get events -n mini-platform --sort-by=.lastTimestamp
```

## Checklist Minh Chung

- [x] ArgoCD root/platform app o trang thai `Synced` va `Healthy`.
- [x] Web service phan hoi qua port-forward.
- [x] Prometheus rule da ton tai hoac ghi chu vi sao local stack chua ho tro.
- [x] Canary rollout dat trang thai healthy.
- [x] Bad canary bi abort boi analysis.
- [x] Ghi lai lenh rollback va giai thich vi sao rollback bang Git la uu tien.

Evidence hien tai duoc ghi trong `evidence.md`. Local cluster da cai CRD `PrometheusRule`, da co `AnalysisRun` pass, va da co bad canary abort evidence.

## Bao Cao Ngan De Nop

Ban co the viet theo mau:

```markdown
## W9 Lab Evidence

### GitOps
- ArgoCD application status:
- Screenshot/file evidence:

### Observability
- Metrics/logs/traces da kiem tra:
- SLO/SLI da dinh nghia:
- Alert rule status:

### Canary
- Rollout steps:
- AnalysisRun result:
- Abort/rollback evidence:

### Reflection
- Dieu hoc duoc:
- Loi gap phai:
- Cach sua:
```

## Loi Hay Gap

| Loi | Nguyen nhan | Cach xu ly |
|---|---|---|
| ArgoCD Application khong sync | Sai repo URL/path hoac private repo thieu credential | Sua `repoURL`, `path`, credential |
| Resource OutOfSync lien tuc | Sua tay trong cluster hoac Git khac live state | Xem diff, sync/revert |
| PrometheusRule apply fail | Chua co CRD | Cai Prometheus Operator |
| Rollout kind khong ton tai | Chua cai Argo Rollouts CRD | Cai controller |
| Analysis fail vi khong co metric | Prometheus query khong co series | Kiem tra metric name va target |
| Service khong co endpoint | Selector khong khop pod label | Sua label/selector |
