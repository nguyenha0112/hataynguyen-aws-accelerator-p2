# W10-D3 - Platform Integration, Cost Guard va Runbook

## Muc Tieu

Sau ngay nay ban can noi cac guardrail cua D1/D2 thanh mot mini platform co the van hanh:

- Dat `ResourceQuota` de gioi han tai nguyen theo namespace.
- Dat `LimitRange` de workload co request/limit mac dinh.
- Hieu cost guard trong Kubernetes.
- Viet runbook xu ly su co theo trieu chung.
- Thuc hien chaos test nho de kiem tra kha nang phuc hoi.
- Tong hop RBAC, policy, secret, scan, signing thanh deployment flow an toan.

## Van De Can Giai Quyet

O D1 ban da co RBAC va admission policy. O D2 ban da co secret va supply chain guardrail. Nhung platform van co the gap rui ro van hanh:

- Mot namespace dung het CPU/RAM cua cluster.
- Pod khong co request/limit lam scheduler kho du doan.
- Team khong biet lam gi khi rollout fail, secret khong sync, hoac policy reject.
- Security control co nhung khong duoc noi vao quy trinh release.
- Su co nho chua tung duoc tap truoc, den luc that se cham.

D3 tap trung vao "operate safely": gioi han blast radius, co quy trinh xu ly, va test kha nang phuc hoi.

## Platform Guardrail Tong Hop

| Lop | Muc dich | Artifact |
|---|---|---|
| RBAC | Gioi han ai duoc lam gi | `Role`, `RoleBinding`, `ServiceAccount` |
| Admission policy | Chan object sai chuan | Gatekeeper/Kyverno policy |
| Secrets | Khong commit secret plaintext | ESO `SecretStore`, `ExternalSecret` |
| Supply chain | Chi deploy artifact tin cay | Trivy, Cosign, verify image |
| Cost guard | Gioi han tai nguyen namespace | `ResourceQuota`, `LimitRange` |
| Runbook | Xu ly su co co quy trinh | markdown checklist |
| Chaos test | Tap phuc hoi truoc khi co su co that | test scenario |

## ResourceQuota

`ResourceQuota` gioi han tong tai nguyen mot namespace co the dung. Vi du:

- Tong CPU request/limit.
- Tong memory request/limit.
- So luong pod, service, secret, configmap.
- So luong PVC hoac storage.

Neu khong co quota, mot workload loi co the tao qua nhieu pod hoac xin qua nhieu tai nguyen, lam anh huong team khac.

File mau:

```text
w10/W10-D3_Platform_Integration/policies/resource-quota.yaml
```

## LimitRange

`LimitRange` dat mac dinh va min/max cho container trong namespace.

No giup:

- Pod khong khai bao request/limit van co default.
- Chan container xin qua nhieu CPU/RAM.
- Giam rui ro workload "best effort" bi evict bat ngo.

File mau:

```text
w10/W10-D3_Platform_Integration/policies/limit-range.yaml
```

## Cost Guard Trong Kubernetes

Cost guard khong chi la tiet kiem tien. No la cach giu platform on dinh:

- Request qua cao lam cluster scale len khong can thiet.
- Limit qua thap lam app OOMKilled.
- Khong co quota lam mot namespace anh huong namespace khac.
- Khong co owner label lam kho truy vet chi phi.

Nen ket hop:

- Required labels: `app`, `owner`, `env`, `cost-center`.
- ResourceQuota theo namespace/team.
- LimitRange default request/limit.
- Dashboard theo namespace va workload.

## Deployment Flow An Toan

```text
Developer commit code
  -> CI build image
  -> Trivy scan
  -> Cosign sign image
  -> GitOps update manifest
  -> ArgoCD sync
  -> RBAC authorize action
  -> Admission verify labels/security/signature
  -> ESO sync secret
  -> ResourceQuota/LimitRange bound resource
  -> Observability + runbook guide operation
```

## Runbook La Gi?

Runbook la tai lieu thao tac khi co su co. Runbook tot can ngan, ro, co lenh kiem tra, va co tieu chi escalate.

Runbook nen co:

- Trieu chung.
- Anh huong nguoi dung.
- Lenh kiem tra nhanh.
- Nguyen nhan kha nang cao.
- Cach khac phuc tam thoi.
- Cach khac phuc ben vung.
- Khi nao escalate.
- Minh chung can luu lai.

File mau:

```text
w10/W10-D3_Platform_Integration/runbooks/platform-incident-runbook.md
```

## Chaos Test Nho

Chaos test khong phai pha he thong vo toi va. Muc tieu la tao loi co kiem soat de hoc cach phuc hoi.

Scenario nen tap:

| Scenario | Dieu muon kiem tra |
|---|---|
| Xoa mot pod | Deployment/Rollout co tao pod moi khong |
| Doi image sai | Rollout co fail ro rang khong |
| Lam secret sync loi | ESO co bao status de debug khong |
| Tao pod thieu label | Admission policy co reject khong |
| Tao workload vuot quota | Namespace co bi chan truoc khi anh huong cluster khong |

File checklist:

```text
w10/W10-D3_Platform_Integration/chaos/chaos-test-checklist.md
```

## Lenh Chay Local

Apply quota va limit:

```powershell
kubectl apply -f policies/
kubectl get resourcequota -n mini-platform
kubectl get limitrange -n mini-platform
```

Kiem tra quota:

```powershell
kubectl describe resourcequota mini-platform-quota -n mini-platform
kubectl describe limitrange mini-platform-limits -n mini-platform
```

Test workload vuot quota:

```powershell
kubectl apply -f samples/too-large-workload.yaml
```

Xem su kien:

```powershell
kubectl get events -n mini-platform --sort-by=.lastTimestamp
```

## Loi Hay Gap

| Loi | Nguyen nhan | Cach xu ly |
|---|---|---|
| Pod bi reject vi quota | Request/limit vuot namespace quota | Giam resource hoac tang quota co ly do |
| Pod Pending | Khong du node resource hoac quota da het | `kubectl describe pod`, xem events |
| Pod OOMKilled | Memory limit qua thap | Tang limit hoac sua memory leak |
| Policy reject workload dung | Thieu label/annotation bat buoc | Them metadata dung chuan |
| Secret khong update | ESO/provider/IAM loi | `kubectl describe externalsecret` |

## Checklist Minh Chung

- [ ] Output `kubectl get resourcequota,limitrange -n mini-platform`.
- [ ] Output `kubectl describe resourcequota mini-platform-quota -n mini-platform`.
- [ ] Minh chung workload vuot quota bi reject.
- [ ] Minh chung runbook co lenh xu ly rollout/secret/policy/quota.
- [ ] Ghi lai ket qua it nhat 2 chaos test nho.

## Cau Hoi Tu On

- `ResourceQuota` khac `LimitRange` nhu the nao?
- Vi sao request/limit lien quan den chi phi?
- Runbook nen viet theo trieu chung hay theo ten cong cu?
- Chaos test nho giup giam rui ro nhu the nao?
- Khi admission policy reject workload, nen debug theo thu tu nao?
- Neu quota chan deploy production, ai nen duoc approve tang quota?
