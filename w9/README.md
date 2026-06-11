# W9 - Deliver Smartly: GitOps, Observability, SLO, Canary

## Muc Tieu Tuan

Tuan 9 bien platform Kubernetes o W8 tu cach "apply tay va hy vong no chay" thanh mot luong delivery co kiem soat:

- Git la noi khai bao desired state cua he thong.
- CI kiem tra manifest truoc khi merge.
- ArgoCD tu dong reconcile trang thai cluster theo Git.
- Observability cho biet ung dung co dang tot voi nguoi dung hay khong.
- SLO/SLI bien "he thong on" thanh muc tieu do duoc.
- Canary rollout dua version moi len tung phan nho traffic va tu abort khi metric xau.

## Ban Do Kien Thuc

| Ngay | Chu de | Ban can nam |
|---|---|---|
| D1 | GitOps va CI/CD | Git la source of truth, ArgoCD reconcile, CI validate, rollback bang Git |
| D2 | Observability, SLO, OTel | Metrics, logs, traces, SLI, SLO, error budget, burn-rate alert |
| D3 | Progressive Delivery | Canary, analysis, promote, abort, rollback |
| Lab | Tong hop | GitOps-ify platform W8, gan observability, chay canary release |

## Tu Duy Xuyen Suot

### 1. Delivery khong chi la deploy

Deploy chi la dua code len moi truong. Delivery la ca chuoi dam bao version moi:

- Da duoc validate truoc khi vao main branch.
- Duoc apply vao cluster theo cach co audit trail.
- Co tin hieu de biet dang tot hay xau.
- Co cach rollback khi co su co.

Trong tuan nay, Git, CI, ArgoCD, Prometheus, Grafana, OpenTelemetry va Argo Rollouts ghep lai thanh mot delivery loop.

### 2. GitOps tach "mong muon" va "thuc te"

Git chua desired state: namespace, service, config, rollout, alert rule. Cluster chua live state. GitOps controller lien tuc so sanh hai ben:

- Neu live state thieu resource, controller tao them.
- Neu live state khac Git, controller dua ve dung Git.
- Neu ai sua tay trong cluster, drift se bi phat hien.

Day la ly do GitOps giup audit va rollback de hon: muon thay doi he thong thi thay doi Git.

### 3. Observability tra loi cau hoi van hanh

Monitoring truyen thong thuong hoi "CPU co cao khong?". Observability hoi sau hon:

- Nguoi dung co goi duoc request khong?
- Request co cham khong?
- Loi den tu service nao?
- Request di qua nhung component nao?
- Version moi co lam error rate tang khong?

Ba tin hieu chinh:

- Metrics: so lieu tong hop theo thoi gian, vi du request rate, error rate, p95 latency.
- Logs: su kien dang text/structured record, dung de dieu tra chi tiet.
- Traces: duong di cua mot request qua nhieu service, dung de tim nut that latency.

### 4. SLO bien cam giac thanh muc tieu

Khong nen noi "service phai luon on" vi 100% availability gan nhu khong thuc te. SLO dat muc tieu ro rang, vi du:

- 99.5% request thanh cong trong 30 ngay.
- 95% request nhanh hon 500 ms trong 30 ngay.

Phan duoc phep loi goi la error budget. Neu SLO 99.5%, error budget la 0.5%. Khi he thong dot error budget qua nhanh, burn-rate alert canh bao.

### 5. Canary giam rui ro release

Deploy thang 100% traffic khien loi anh huong tat ca nguoi dung. Canary chi dua version moi nhan mot phan nho traffic:

- 20% traffic, kiem tra metric.
- 50% traffic, kiem tra tiep.
- 100% traffic neu analysis pass.
- Abort neu error rate/latency vuot nguong.

Canary chi co y nghia khi co metric tot. Khong co observability thi canary chi la deploy cham hon.

## Thu Muc Theo Ngay

- `W9-D1_GitOps_CICD/`: GitOps, ArgoCD, CI validation, rollback.
- `W9-D2_Observability_SLO_OTel/`: Prometheus, Grafana, Loki, OpenTelemetry, SLO/SLI, burn-rate alert.
- `W9-D3_Progressive_Delivery_Canary/`: Argo Rollouts, canary strategy, analysis, promote/abort.
- `lab/`: Bai tong hop ap dung cho platform W8 tren minikube.

## Luong Hoc De Xuat

1. Doc README tong quan nay de nam mental model.
2. Hoc D1 va chay GitOps skeleton.
3. Hoc D2 va hieu cach do availability/latency.
4. Hoc D3 va hieu vi sao canary can metrics.
5. Chay `lab/` de noi ca 3 phan.
6. Cap nhat `reflection.md` bang ket qua that tren may.

## Minh Chung Can Bo Sung Sau Khi Chay Local

- GitHub Actions run the hien PR check va luong sau khi merge.
- Trang thai health va sync cua ArgoCD Application.
- Prometheus targets va ket qua evaluate alert rule.
- Screenshot Grafana dashboard cho availability va latency.
- Trang thai canary cua Argo Rollouts, ket qua analysis, va minh chung abort/rollback.

## Cau Hoi Tu On

- GitOps khac gi voi viec chay `kubectl apply` tu laptop?
- Vi sao CI nen validate manifest truoc khi merge?
- Drift la gi va ArgoCD phat hien drift nhu the nao?
- Metrics, logs, traces khac nhau o diem nao?
- SLI va SLO khac nhau nhu the nao?
- Error budget dung de quyet dinh dieu gi?
- Burn-rate alert tot hon alert theo ti le loi tai mot thoi diem nhu the nao?
- Canary can nhung metric nao de quyet dinh promote hay abort?
