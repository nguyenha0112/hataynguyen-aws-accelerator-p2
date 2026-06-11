# W9 Reflection

## Da Lam

- Chuan bi cau truc GitOps cho platform W8 bang ArgoCD Application manifests.
- Them CI validation cho Kubernetes manifests.
- Them OpenTelemetry Collector, ban nhap SLO dashboard, va Prometheus burn-rate rules.
- Them Argo Rollouts canary manifests voi analysis dua tren Prometheus.
- Mo rong tai lieu hoc W9 thanh cac ghi chu day du ve GitOps, observability, SLO, va canary.

## Da Hoc Duoc

- GitOps giup delivery de audit vi repository la source of truth.
- ArgoCD reconcile live state cua cluster ve desired state trong Git.
- CI trong GitOps nen validate va test truoc khi merge, con CD nen do controller trong cluster thuc hien.
- Observability can metric gan voi trai nghiem nguoi dung, khong chi metric ha tang.
- SLI la chi so do duoc; SLO la muc tieu ro rang cho chi so do trong mot khoang thoi gian.
- Error budget giup can bang toc do release va do on dinh.
- Burn-rate alert canh bao khi service dot error budget qua nhanh.
- Canary release giam rui ro deploy bang cach kiem tra tin hieu gan thuc te truoc khi promote toan bo.

## Can Cai Thien Tiep

- Thay `CHANGE_ME` repo URL sau khi xac nhan thong tin remote repository.
- Cai Prometheus Operator hoac dieu chinh alert rules theo monitoring stack local da chon.
- Them k6 load test de tao metric success, latency, va failure cho canary analysis.
- Chup screenshot va luu command output sau khi chay lab local.

## Mau Tu Ghi Reflection Sau Khi Chay Lab

### GitOps

- Application nao da sync thanh cong?
- Co gap `OutOfSync` hoac `Degraded` khong?
- Neu co drift, ArgoCD bao nhu the nao?

### Observability

- Da xem duoc metric nao?
- Availability SLI cua web service duoc tinh bang query nao?
- Latency SLO dat nguong bao nhieu?
- Alert rule co apply duoc khong? Neu khong, thieu CRD hay sai stack?

### Canary

- Rollout da di qua nhung step nao?
- AnalysisRun pass hay fail?
- Khi tao bad canary, rollout abort nhu the nao?
- Sau abort, can sua Git ra sao de rollback dung GitOps?

### Bai Hoc Ca Nhan

- Dieu nao kho nhat trong W9?
- Lenh nao ban muon ghi nho?
- Neu dua len moi truong that, ban se them guardrail nao?
