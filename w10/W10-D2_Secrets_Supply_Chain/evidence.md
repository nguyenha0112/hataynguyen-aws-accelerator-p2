# W10-D2 Evidence

## External Secrets Operator

```powershell
kubectl get externalsecret -n mini-platform
kubectl describe externalsecret app-config -n mini-platform
kubectl get secret app-config -n mini-platform
```

## Trivy

```powershell
trivy image --severity HIGH,CRITICAL --exit-code 1 nginx:1.27
```

## Cosign

```powershell
cosign verify --key cosign.pub <image>
```

## Admission Verify

```powershell
kubectl apply -f signing/kyverno-verify-images.yaml
kubectl apply -f samples/unsigned-image-pod.yaml
```

## Ghi Chu

- Secret rotation result:
- Trivy finding:
- Signature verify result:
- Exception ADR:
