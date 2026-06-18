# Platform Incident Runbook

## Muc Dich

Runbook nay dung khi deployment, policy, secret, quota hoac rollout gap loi trong namespace `mini-platform`.

## Kiem Tra Nhanh

```powershell
kubectl get pods -n mini-platform
kubectl get events -n mini-platform --sort-by=.lastTimestamp
kubectl get rollout -n mini-platform
kubectl get externalsecret -n mini-platform
kubectl get resourcequota,limitrange -n mini-platform
```

## Deployment Hoac Rollout Fail

Trieu chung:

- Pod `ImagePullBackOff`, `CrashLoopBackOff`, hoac `Pending`.
- Argo Rollouts abort hoac AnalysisRun fail.

Lenh kiem tra:

```powershell
kubectl describe pod <pod-name> -n mini-platform
kubectl get analysisrun -n mini-platform
kubectl describe analysisrun <analysisrun-name> -n mini-platform
kubectl argo rollouts get rollout web -n mini-platform
```

Xu ly:

- Neu image sai, revert commit GitOps ve image tot gan nhat.
- Neu metric fail, abort rollout de dung traffic sang version loi.
- Neu pod pending, kiem tra quota va node capacity.

## Admission Policy Reject

Trieu chung:

- `kubectl apply` tra ve loi denied.
- ArgoCD sync fail vi resource bi policy chan.

Lenh kiem tra:

```powershell
kubectl get constraints
kubectl describe constrainttemplate
kubectl get events -n mini-platform --sort-by=.lastTimestamp
```

Xu ly:

- Doc message reject va sua manifest.
- Neu can exception, tao ADR co owner, ly do, expiry.
- Khong tat policy toan cluster neu chi mot workload can exception.

## Secret Khong Sync

Trieu chung:

- Pod thieu env/config.
- `ExternalSecret` status khong ready.

Lenh kiem tra:

```powershell
kubectl describe externalsecret app-config -n mini-platform
kubectl get secret app-config -n mini-platform
kubectl logs -n external-secrets deploy/external-secrets
```

Xu ly:

- Kiem tra SecretStore/provider/IAM permission.
- Kiem tra remote secret name va property.
- Neu app doc secret qua env var, restart pod sau khi secret update.

## Quota Hoac Limit Chan Workload

Trieu chung:

- Pod khong tao duoc.
- Deployment khong scale.
- Event bao exceeded quota hoac max limit.

Lenh kiem tra:

```powershell
kubectl describe resourcequota mini-platform-quota -n mini-platform
kubectl describe limitrange mini-platform-limits -n mini-platform
kubectl describe deployment <deployment-name> -n mini-platform
```

Xu ly:

- Giam request/limit neu dang set qua cao.
- Xoa workload khong con dung.
- Tang quota chi khi co owner va ly do ro rang.

## Escalate Khi Nao

- Anh huong production hoac user-facing service.
- Secret nghi bi lo.
- Image khong ro nguon goc da vao cluster.
- Quota can tang cho workload quan trong.
- Policy exception can keo dai qua expiry.

## Evidence Can Luu

- Thoi gian bat dau va ket thuc su co.
- Command output lien quan.
- Ten commit/image digest.
- Resource bi policy/quota reject.
- Hanh dong rollback hoac fix.
- Follow-up de ngan lap lai.
