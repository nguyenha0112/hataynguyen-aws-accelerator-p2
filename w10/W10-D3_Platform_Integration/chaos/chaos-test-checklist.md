# Chaos Test Checklist

## Nguyen Tac

- Chi test trong namespace `mini-platform`.
- Bao dam co cach rollback truoc khi test.
- Moi test can co expected result va actual result.
- Ghi lai evidence ngan trong `evidence.md`.

## Test 1 - Delete Pod

Muc tieu: kiem tra controller tao pod moi.

```powershell
kubectl get pods -n mini-platform
kubectl delete pod <pod-name> -n mini-platform
kubectl get pods -n mini-platform --watch
```

Expected:

- Pod cu mat di.
- ReplicaSet/Rollout tao pod moi.
- Service van co endpoint sau khi pod moi ready.

## Test 2 - Workload Vuot Quota

Muc tieu: kiem tra namespace khong vuot tai nguyen da cap.

```powershell
kubectl apply -f samples/too-large-workload.yaml
kubectl get events -n mini-platform --sort-by=.lastTimestamp
```

Expected:

- Deployment hoac ReplicaSet bi chan do vuot quota.
- Event noi ro resource nao vuot gioi han.

## Test 3 - Admission Reject Thieu Label

Muc tieu: kiem tra required label policy van enforce.

```powershell
kubectl apply -f ../W10-D1_RBAC_Admission_Policy/samples/bad-missing-labels.yaml
```

Expected:

- API server reject resource.
- Message chi ra label bat buoc dang thieu.

## Test 4 - Secret Sync Debug

Muc tieu: tap doc status cua ExternalSecret.

```powershell
kubectl get externalsecret -n mini-platform
kubectl describe externalsecret app-config -n mini-platform
```

Expected:

- Biet trang thai Ready/NotReady.
- Biet loi nam o provider, permission, remote key hay template.

## Test 5 - Bad Image Rollout

Muc tieu: tap phat hien va rollback image loi.

```powershell
kubectl set image rollout/web web=nginx:not-a-real-tag -n mini-platform
kubectl get pods -n mini-platform
kubectl get events -n mini-platform --sort-by=.lastTimestamp
```

Expected:

- Pod moi vao `ImagePullBackOff`.
- Rollout khong promote thanh cong.
- Team revert Git hoac set lai image dung.

## Ket Qua

| Test | Pass/Fail | Evidence | Ghi chu |
|---|---|---|---|
| Delete pod |  |  |  |
| Vuot quota |  |  |  |
| Admission reject |  |  |  |
| Secret sync debug |  |  |  |
| Bad image rollout |  |  |  |
