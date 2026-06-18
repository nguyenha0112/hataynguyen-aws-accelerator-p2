# W10 - Secure & Operate: RBAC, Secrets, Supply Chain

## Muc Tieu Tuan

Tuan 10 chuyen platform tu "deploy duoc" sang "deploy co kiem soat va co guardrail":

- Phan quyen Kubernetes bang RBAC thay vi dung quyen admin cho moi nguoi.
- Kiem tra quyen bang `kubectl auth can-i`.
- Chan cau hinh nguy hiem o admission layer bang OPA Gatekeeper.
- Quan ly secret qua External Secrets Operator thay vi commit secret plaintext.
- Scan image trong CI bang Trivy.
- Ky image bang Cosign va verify signature truoc khi deploy.
- Noi lai W8 foundation va W9 delivery thanh mini platform san sang cho capstone.

## Ban Do Kien Thuc

| Ngay | Chu de | Ban can nam |
|---|---|---|
| D1 | RBAC va Admission Policy | Role, RoleBinding, ServiceAccount, `can-i`, Gatekeeper ConstraintTemplate/Constraint |
| D2 | Secrets Rotation va Supply Chain | AWS Secrets Manager, ESO, Trivy, Cosign, image signature policy |
| D3 | Platform Integration | ResourceQuota, LimitRange, runbook, cost guard, chaos test |
| Lab | Cluster cleanup | Tim va sua 6 risk, enforce policy o cluster level |

## Thu Muc Theo Ngay

- `W10-D1_RBAC_Admission_Policy/`: RBAC, ServiceAccount, Gatekeeper policy.
- `W10-D2_Secrets_Supply_Chain/`: External Secrets Operator, Trivy CI, Cosign signing.
- `W10-D3_Platform_Integration/`: ResourceQuota, LimitRange, runbook, chaos test.

## Ket Qua Can Dat

- Co 3 role ro rang: `developer`, `sre`, `viewer`.
- Co it nhat 4 admission policy enforce hoac audit.
- Secret duoc sync tu external secret store va co refresh interval.
- CI scan image va fail khi co HIGH/CRITICAL CVE theo policy.
- Image release co signature va co admission policy verify signature.

## Cau Hoi Tu On

- Vi sao khong nen cap `cluster-admin` cho developer?
- `Role` khac `ClusterRole` nhu the nao?
- Admission policy chan loi o thoi diem nao trong Kubernetes API flow?
- Secret rotation khac gi voi viec sua Secret thu cong?
- Scan image trong CI va verify image o admission layer bo sung cho nhau ra sao?
