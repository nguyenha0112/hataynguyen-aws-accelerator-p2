# W10-D1 Evidence

## RBAC

```powershell
kubectl get role,rolebinding -n mini-platform
kubectl auth can-i get pods -n mini-platform --as=system:serviceaccount:mini-platform:developer
kubectl auth can-i delete secrets -n mini-platform --as=system:serviceaccount:mini-platform:developer
kubectl auth can-i create deployments -n mini-platform --as=system:serviceaccount:mini-platform:viewer
```

## Gatekeeper

```powershell
kubectl get constrainttemplates
kubectl get constraints
kubectl apply -f samples/bad-privileged-pod.yaml
kubectl apply -f samples/bad-missing-labels.yaml
```

## Ghi Chu

- Policy da enforce:
- Policy nen audit truoc:
- Loi gap phai va cach sua:
