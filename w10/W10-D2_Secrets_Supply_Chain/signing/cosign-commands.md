# Cosign Commands

## Keyless Signing In CI

```powershell
cosign sign ghcr.io/example-org/app:v1
cosign verify ghcr.io/example-org/app:v1
```

## Key-Based Signing For Local Practice

```powershell
cosign generate-key-pair
cosign sign --key cosign.key ghcr.io/example-org/app:v1
cosign verify --key cosign.pub ghcr.io/example-org/app:v1
```

## Verify By Digest

```powershell
cosign verify --key cosign.pub ghcr.io/example-org/app@sha256:<digest>
```
