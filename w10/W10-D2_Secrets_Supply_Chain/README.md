# W10-D2 - Secrets Rotation va Supply Chain Security

## Muc Tieu

Sau ngay nay ban can hieu cach bao ve secret va artifact truoc khi chung vao cluster:

- Khong commit secret plaintext vao Git.
- Dung AWS Secrets Manager lam external secret store.
- Dung External Secrets Operator de sync secret vao Kubernetes.
- Hieu `refreshInterval` va secret rotation.
- Scan image bang Trivy trong CI.
- Ky image bang Cosign.
- Verify image signature o admission layer.
- Viet exception policy cho CVE co ly do va thoi han.

## Van De Can Giai Quyet

Neu chi dung Kubernetes Secret thuong va tu apply YAML:

- Secret co the bi commit vao Git.
- Secret rotate roi nhung pod van dung gia tri cu.
- CI co the release image co CVE nghiem trong.
- Cluster co the keo image chua duoc ky hoac khong ro nguon goc.
- Exception security khong co owner, khong co expiry.

D2 dua security vao supply chain: secret den tu source quan ly rieng, image phai scan va ky, admission chi chap nhan artifact tin cay.

## Secrets Manager Va ESO

AWS Secrets Manager luu secret ben ngoai cluster. External Secrets Operator (ESO) doc secret tu provider va tao/cap nhat Kubernetes Secret.

Luong tong quat:

```text
AWS Secrets Manager -> External Secrets Operator -> Kubernetes Secret -> Pod
```

Loi ich:

- Git chi chua reference, khong chua gia tri secret.
- Co the rotate secret tai source.
- ESO tu refresh theo `refreshInterval`.
- Quyen doc secret co the gioi han bang IAM/IRSA.

## Thanh Phan ESO

| Thanh phan | Y nghia |
|---|---|
| SecretStore | Cau hinh provider trong mot namespace |
| ClusterSecretStore | Cau hinh provider dung chung toan cluster |
| ExternalSecret | Mapping tu remote secret sang Kubernetes Secret |
| refreshInterval | Tan suat ESO kiem tra va sync gia tri moi |

File mau:

```text
w10/W10-D2_Secrets_Supply_Chain/eso/secret-store.yaml
w10/W10-D2_Secrets_Supply_Chain/eso/external-secret.yaml
```

## Rotation

Rotation nghia la thay gia tri secret theo chu ky hoac khi co su co. Muc tieu W10:

```text
Secret rotate tai external store -> Kubernetes Secret update < 60s -> workload doc duoc gia tri moi
```

Can luu y:

- Neu app doc secret tu env var, pod thuong can restart de nhan gia tri moi.
- Neu app doc secret tu mounted volume, kubelet co the cap nhat file sau mot khoang tre.
- Mot so app can co reload logic rieng.

## Trivy Image Scan

Trivy scan image de tim CVE va misconfiguration. Trong CI, policy hay dung:

- Fail neu co `CRITICAL`.
- Fail neu co `HIGH` ma khong co exception duoc approve.
- Xuat SARIF hoac table de reviewer xem.

File mau:

```text
w10/W10-D2_Secrets_Supply_Chain/ci-trivy/github-actions-trivy.yml
```

## Cosign Va Image Signing

Cosign dung de ky container image. Co hai cach hay gap:

| Cach | Y nghia | Khi dung |
|---|---|---|
| Keyless OIDC | CI identity ky image, khong can quan ly private key dai han | GitHub Actions, GitLab CI |
| Key-based | Dung private/public key ro rang | Moi truong can key custody rieng |

Lenh y tuong:

```powershell
cosign sign --key cosign.key ghcr.io/org/app:v1
cosign verify --key cosign.pub ghcr.io/org/app:v1
```

## Verify Signature O Admission Layer

Scan va sign trong CI la can thiet, nhung admission verify giup cluster tu bao ve minh:

- Image khong co signature hop le bi reject.
- Image ky boi identity khong duoc tin cay bi reject.
- Namespace test co the co exception, production thi enforce.

File mau dung Kyverno verifyImages:

```text
w10/W10-D2_Secrets_Supply_Chain/signing/kyverno-verify-images.yaml
```

## Exception Policy

Exception phai co:

- CVE hoac control duoc exception.
- Owner chiu trach nhiem.
- Ly do business/technical.
- Expiry date.
- Cach giam rui ro tam thoi.

Khong nen co exception vo thoi han.

## Lenh Chay Local

Cai ESO bang Helm:

```powershell
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace
kubectl get pods -n external-secrets
```

Apply ESO manifest:

```powershell
kubectl apply -f eso/
kubectl get externalsecret -n mini-platform
kubectl get secret app-config -n mini-platform
```

Chay Trivy local:

```powershell
trivy image --severity HIGH,CRITICAL --exit-code 1 nginx:1.27
```

Verify Cosign:

```powershell
cosign verify --key cosign.pub <image>
```

## Loi Hay Gap

| Loi | Nguyen nhan | Cach xu ly |
|---|---|---|
| ESO khong sync secret | Sai SecretStore/provider/permission | Kiem tra `kubectl describe externalsecret` |
| Secret da update nhung app chua nhan | App doc env var | Restart pod hoac them reload mechanism |
| Trivy fail qua nhieu | Base image cu | Update image hoac tao exception co expiry |
| Cosign verify fail | Sai key/identity/image digest | Verify dung digest va trust policy |
| Admission reject image dung | Policy qua chat hoac chua ky image | Ky image, thu hep scope, them exception tam thoi |

## Checklist Minh Chung

- [ ] Output `kubectl get externalsecret -n mini-platform`.
- [ ] Minh chung secret update sau rotation.
- [ ] GitHub Actions hoac log Trivy scan.
- [ ] Output `cosign verify`.
- [ ] Admission reject image chua ky.
- [ ] Exception ADR ngan cho mot CVE gia dinh co expiry.

## Cau Hoi Tu On

- Vi sao Kubernetes Secret khong nen duoc commit vao Git?
- `SecretStore` khac `ClusterSecretStore` nhu the nao?
- Vi sao app doc secret qua env var thuong can restart khi secret rotate?
- Trivy scan trong CI giam rui ro nao?
- Verify signature o admission layer giam rui ro nao?
- Exception security can co nhung truong nao?
