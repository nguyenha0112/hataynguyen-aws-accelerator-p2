# W9-D3 - Progressive Delivery: Canary

## Muc Tieu

Sau ngay nay ban can hieu cach release version moi ma khong day rui ro cho 100% traffic ngay lap tuc:

- Progressive delivery la gi.
- Canary rollout hoat dong nhu the nao.
- Argo Rollouts khac Deployment thuong o diem nao.
- Analysis dung Prometheus metric de promote hoac abort.
- Rollback khi canary fail.

## Progressive Delivery La Gi?

Progressive delivery la cach dua thay doi ra production tung buoc, kem theo dieu kien kiem tra. Thay vi release tat ca mot lan, ban release theo tung muc:

- Mot nhom nho nguoi dung.
- Mot ti le traffic nho.
- Mot namespace/moi truong gioi han.
- Mot feature flag chi bat cho mot segment.

Muc tieu la phat hien loi som, giam blast radius va rollback nhanh.

## Cac Kieu Progressive Delivery

| Kieu | Cach lam | Diem manh |
|---|---|---|
| Rolling update | Thay pod cu bang pod moi dan dan | Don gian, san co trong Deployment |
| Blue/Green | Chay song song version blue va green, switch traffic | Rollback nhanh |
| Canary | Version moi nhan mot phan traffic, tang dan neu tot | Giam rui ro va co metric gate |
| Feature flag | Bat/tat tinh nang theo user/segment | Tach deploy khoi release |

Ngay nay tap trung vao canary.

## Canary La Gi?

Canary release dua version moi nhan mot phan nho traffic truoc. Neu metric tot, tang traffic. Neu metric xau, dung rollout va quay ve version on dinh.

Vi du chien luoc:

| Step | Traffic toi version moi | Dieu kien |
|---|---:|---|
| Start | 20% | Error rate < 5% |
| Continue | 50% | Error rate < 5% |
| Promote | 100% | Analysis pass |
| Abort | 0% | Analysis fail |

Canary can observability. Neu khong co metrics, ban khong biet nen promote hay abort.

## Argo Rollouts

Kubernetes Deployment mac dinh ho tro rolling update, nhung khong manh ve traffic shifting va metric analysis. Argo Rollouts them custom resource `Rollout`.

Argo Rollouts ho tro:

- Canary strategy.
- Blue/Green strategy.
- Pause giua cac buoc.
- AnalysisRun dua tren metric.
- Traffic routing voi service mesh/ingress neu cau hinh.
- CLI de xem rollout tree.

File trong repo:

```text
cloud/w9/W9-D3_Progressive_Delivery_Canary/rollout/web-rollout.yaml
cloud/w9/W9-D3_Progressive_Delivery_Canary/rollout/analysis-template.yaml
```

## Rollout Vs Deployment

| Deployment | Rollout |
|---|---|
| Rolling update co ban | Canary/BlueGreen nang cao |
| Khong co analysis metric native | Co AnalysisTemplate/AnalysisRun |
| Rollback bang rollout history | Abort/promote theo strategy |
| Phu hop workload don gian | Phu hop progressive delivery |

## Thanh Phan Chinh

### Rollout

`Rollout` thay the `Deployment` cho workload can progressive delivery. No dinh nghia:

- Replicas.
- Selector.
- Pod template.
- Strategy canary.
- Cac buoc setWeight/pause/analysis.

### AnalysisTemplate

`AnalysisTemplate` dinh nghia metric can kiem tra. Vi du:

- Query Prometheus error rate.
- Nguong pass/fail.
- So lan do.
- Khoang cach giua cac lan do.

### AnalysisRun

`AnalysisRun` la lan chay cu the cua `AnalysisTemplate` trong mot rollout. Neu AnalysisRun fail, rollout co the abort.

## Luong Canary

```text
Commit image moi vao Git
  -> ArgoCD sync Rollout
  -> Argo Rollouts tao ReplicaSet moi
  -> Chuyen 20% traffic sang version moi
  -> Chay AnalysisRun
  -> Pass: tang len 50%
  -> Pass: promote 100%
  -> Fail bat ky buoc nao: abort va giu version stable
```

## Traffic Weight

Trong canary, `setWeight: 20` nghia la version moi nhan 20% traffic. Tuy setup, weight co the duoc thuc hien bang:

- Replica ratio don gian.
- Ingress controller.
- Service mesh nhu Istio/Linkerd.
- Gateway API.

Neu khong cau hinh traffic router, Argo Rollouts co the dieu chinh so pod canary/stable de xap xi weight. Cach nay tot de hoc, nhung production thuong dung ingress/service mesh de chia traffic chinh xac hon.

## Metric Cho Canary

Canary nen dung metric gan voi nguoi dung:

- Error rate 5xx.
- p95 latency.
- Availability SLI.
- Business metric quan trong neu co.

Khong nen chi dung CPU/RAM de promote. CPU thap khong co nghia nguoi dung khong gap loi.

## Prometheus Analysis

AnalysisTemplate co the query Prometheus. Vi du y tuong:

```promql
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))
```

Neu ket qua nho hon `0.05`, error rate duoi 5%, analysis pass.

## Promote, Pause, Abort

| Hanh dong | Y nghia | Khi nao |
|---|---|---|
| Promote | Day canary len buoc tiep theo hoac 100% | Metric tot |
| Pause | Dung tam thoi de quan sat/approve | Can manual gate |
| Abort | Dung rollout moi va quay ve stable | Metric xau |
| Retry | Chay lai rollout/analysis | Loi tam thoi da duoc sua |

Lenh hay dung:

```powershell
kubectl argo rollouts get rollout web -n mini-platform
kubectl argo rollouts promote web -n mini-platform
kubectl argo rollouts abort web -n mini-platform
kubectl argo rollouts retry rollout web -n mini-platform
```

## Lenh Chay Local

```powershell
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
kubectl apply -f rollout/analysis-template.yaml
kubectl apply -f rollout/web-rollout.yaml
kubectl argo rollouts get rollout web -n mini-platform --watch
```

Neu chua cai plugin CLI:

```powershell
kubectl get rollout -n mini-platform
kubectl describe rollout web -n mini-platform
kubectl get analysisrun -n mini-platform
```

## Cach Tao Bad Canary De Hoc

Mot so cach co the lam canary fail trong lab:

- Doi image sang tag khong ton tai de tao `ImagePullBackOff`.
- Doi app config de tra ve 500.
- Doi Prometheus query/threshold thanh dieu kien chac chan fail.
- Tao load test request loi neu app co endpoint test.

Sau khi fail, kiem tra:

```powershell
kubectl get rollout web -n mini-platform
kubectl get analysisrun -n mini-platform
kubectl describe analysisrun <name> -n mini-platform
kubectl argo rollouts get rollout web -n mini-platform
```

## Rollback Trong GitOps

Neu rollout duoc quan ly boi ArgoCD, cach rollback ben vung van la sua Git:

```powershell
git revert <bad_commit>
git push
```

ArgoCD sync desired state tot. Argo Rollouts se dua cluster ve version on dinh.

Lenh abort chi dung de dung su co hien tai:

```powershell
kubectl argo rollouts abort web -n mini-platform
```

Sau abort, van can sua Git neu Git dang tro den version xau.

## Loi Hay Gap

| Loi | Nguyen nhan | Cach xu ly |
|---|---|---|
| `no matches for kind Rollout` | Chua cai Argo Rollouts CRD | Cai controller truoc |
| AnalysisRun fail lien tuc | Query Prometheus sai hoac metric xau that | Kiem tra PromQL trong Prometheus |
| Rollout khong chia traffic dung | Chua cau hinh traffic router | Dung replica-based de hoc hoac cau hinh ingress/service mesh |
| Pod moi ImagePullBackOff | Image tag sai/private registry thieu secret | Sua image hoac imagePullSecret |
| ArgoCD sync lai version xau | Git van chua rollback | `git revert` commit xau |

## Checklist Minh Chung

- [ ] Trang thai rollout o muc 20% va 50% traffic.
- [ ] Ket qua Prometheus AnalysisRun.
- [ ] Minh chung abort tu metric xau hoac image loi co y.
- [ ] Giai thich ngan vi sao canary an toan hon deploy thang.

## Cau Hoi Tu On

- Canary khac rolling update nhu the nao?
- Vi sao canary phai gan voi metric user-facing?
- AnalysisTemplate va AnalysisRun khac nhau nhu the nao?
- Khi nao nen pause manual trong canary?
- Neu abort rollout nhung khong revert Git thi dieu gi co the xay ra?
- Khi nao nen dung Blue/Green thay vi Canary?
