# W8 Lab - Mini K8s Platform On Minikube

## Goal

Deploy a small local platform on minikube using Kubernetes manifests:

- Namespace
- ConfigMap
- Secret
- Deployment with probes
- Service
- NetworkPolicy

## Commands

```powershell
minikube start
kubectl apply -f manifests/
kubectl get all -n mini-platform
kubectl describe deploy web -n mini-platform
kubectl port-forward svc/web 8080:80 -n mini-platform
```

Open:

```text
http://localhost:8080
```

Cleanup:

```powershell
kubectl delete -f manifests/
```

## Evidence Checklist

- [ ] `kubectl get all -n mini-platform`
- [ ] Browser screenshot or curl output from localhost port-forward.
- [ ] Short explanation of Deployment, Service, ConfigMap, Secret, and NetworkPolicy.

