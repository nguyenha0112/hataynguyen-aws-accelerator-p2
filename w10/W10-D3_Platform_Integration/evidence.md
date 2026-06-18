# W10-D3 Evidence

## ResourceQuota Va LimitRange

Lenh:

```powershell
kubectl get resourcequota,limitrange -n mini-platform
kubectl describe resourcequota mini-platform-quota -n mini-platform
kubectl describe limitrange mini-platform-limits -n mini-platform
```

Ket qua:

```text
Paste output tai day.
```

## Workload Vuot Quota Bi Chan

Lenh:

```powershell
kubectl apply -f samples/too-large-workload.yaml
kubectl get events -n mini-platform --sort-by=.lastTimestamp
```

Ket qua:

```text
Paste output tai day.
```

## Chaos Test

| Test | Ket qua | Evidence |
|---|---|---|
| Delete pod |  |  |
| Vuot quota |  |  |
| Admission reject |  |  |
| Secret sync debug |  |  |
| Bad image rollout |  |  |

## Runbook Note

- Su co da gia lap:
- Lenh da dung de debug:
- Cach rollback/fix:
- Bai hoc:
