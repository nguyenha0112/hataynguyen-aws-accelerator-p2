# W10-D1 - RBAC va Admission Policy

## Muc Tieu

Sau ngay nay ban can hieu cach hardening Kubernetes o cluster level:

- Dung RBAC de gioi han ai duoc lam gi.
- Tao `ServiceAccount`, `Role`, `RoleBinding`, `ClusterRole`.
- Kiem tra quyen bang `kubectl auth can-i`.
- Hieu admission controller nam o dau trong Kubernetes API flow.
- Viet policy bang OPA Gatekeeper de chan workload cau hinh nguy hiem.
- Phan biet audit mode va enforce mode.

## Van De Can Giai Quyet

O W8 va W9, ban co the da thao tac cluster bang kubeconfig co quyen cao. Cach nay nhanh de hoc, nhung nguy hiem khi lam team:

- Developer co the xoa resource ngoai namespace cua minh.
- Pod co the chay privileged hoac root user.
- Container co the dung image tag `latest`.
- Resource khong co request/limit lam cluster bi tranh chap tai nguyen.
- Policy phu thuoc vao "developer nho lam dung" thay vi cluster tu chan sai.

W10 D1 dua guardrail vao cluster: dung RBAC de gioi han hanh dong, dung admission policy de chan object khong dat chuan.

## RBAC La Gi?

RBAC la Role-Based Access Control. Kubernetes dung RBAC de tra loi cau hoi:

```text
Subject nao duoc verb nao tren resource nao trong scope nao?
```

| Thanh phan | Y nghia | Vi du |
|---|---|---|
| Subject | Ai dang thuc hien hanh dong | User, Group, ServiceAccount |
| Verb | Hanh dong | get, list, watch, create, update, delete |
| Resource | Doi tuong Kubernetes | pods, deployments, services, secrets |
| Scope | Pham vi | namespace hoac cluster |

## Role Va ClusterRole

| Loai | Scope | Khi dung |
|---|---|---|
| Role | Trong mot namespace | Developer chi thao tac namespace cua team |
| ClusterRole | Toan cluster hoac resource cluster-scoped | Viewer doc nhieu namespace, SRE doc node |

`RoleBinding` gan `Role` hoac `ClusterRole` vao subject trong mot namespace. `ClusterRoleBinding` gan `ClusterRole` tren toan cluster, can dung rat can than.

## Model Role De Xuat

| Role | Quyen nen co | Quyen khong nen co |
|---|---|---|
| viewer | get/list/watch resource | create/update/delete |
| developer | deploy app trong namespace rieng | sua RBAC, doc secret nhay cam, xoa namespace |
| sre | quan sat va sua su co platform | cap admin dai han khong audit |

File mau:

```text
w10/W10-D1_RBAC_Admission_Policy/rbac/namespace.yaml
w10/W10-D1_RBAC_Admission_Policy/rbac/serviceaccounts.yaml
w10/W10-D1_RBAC_Admission_Policy/rbac/roles.yaml
w10/W10-D1_RBAC_Admission_Policy/rbac/bindings.yaml
```

## Kiem Tra Quyen

Dung `kubectl auth can-i` de test quyen truoc khi giao cho user hoac service account:

```powershell
kubectl auth can-i get pods -n mini-platform --as=system:serviceaccount:mini-platform:developer
kubectl auth can-i delete secrets -n mini-platform --as=system:serviceaccount:mini-platform:developer
kubectl auth can-i get pods -A --as=system:serviceaccount:mini-platform:viewer
```

Ket qua mong doi:

- `developer` co the tao/sua workload trong `mini-platform`.
- `developer` khong duoc xoa secret hoac sua RBAC.
- `viewer` chi doc, khong sua.
- `sre` co quyen van hanh rong hon nhung van nen audit.

## Admission Policy La Gi?

Khi ban gui request tao/sua resource vao Kubernetes API, request di qua nhieu lop:

```text
kubectl -> authentication -> authorization/RBAC -> admission -> persist vao etcd
```

RBAC tra loi "ai co duoc lam hanh dong nay khong". Admission policy tra loi "object nay co dat chuan khong".

Vi du:

- RBAC cho phep developer tao Deployment.
- Admission policy van reject Deployment neu container chay privileged.

## OPA Gatekeeper

Gatekeeper la admission controller dung OPA/Rego de validate Kubernetes object.

Hai khai niem quan trong:

| Thanh phan | Y nghia |
|---|---|
| ConstraintTemplate | Dinh nghia logic policy bang Rego |
| Constraint | Ap policy vao resource nao, namespace nao, tham so nao |

File mau:

```text
w10/W10-D1_RBAC_Admission_Policy/policies/required-labels-template.yaml
w10/W10-D1_RBAC_Admission_Policy/policies/required-labels-constraint.yaml
w10/W10-D1_RBAC_Admission_Policy/policies/no-privileged-template.yaml
w10/W10-D1_RBAC_Admission_Policy/policies/no-privileged-constraint.yaml
```

## Audit Mode Va Enforce Mode

| Mode | Y nghia | Khi dung |
|---|---|---|
| dryrun/audit | Ghi nhan vi pham nhung khong chan | Khi moi rollout policy |
| deny/enforce | Reject request vi pham | Khi policy da on dinh |

Nen bat dau bang audit de xem workload hien tai co vi pham khong. Sau khi sua xong false positive, chuyen sang enforce.

## Lenh Chay Local

Cai Gatekeeper:

```powershell
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.16/deploy/gatekeeper.yaml
kubectl get pods -n gatekeeper-system
```

Apply RBAC:

```powershell
kubectl apply -f rbac/
kubectl get role,rolebinding -n mini-platform
kubectl get serviceaccount -n mini-platform
```

Apply policy:

```powershell
kubectl apply -f policies/
kubectl get constrainttemplates
kubectl get constraints
```

Test workload bi reject:

```powershell
kubectl apply -f samples/bad-privileged-pod.yaml
kubectl apply -f samples/bad-missing-labels.yaml
```

## Loi Hay Gap

| Loi | Nguyen nhan | Cach xu ly |
|---|---|---|
| `forbidden` khi apply | RBAC thieu quyen | Kiem tra `kubectl auth can-i` |
| Constraint khong hoat dong | Gatekeeper chua ready hoac template loi | Kiem tra pod/log o `gatekeeper-system` |
| Resource cu van ton tai | Admission chi chan create/update moi | Sua hoac recreate resource |
| Policy qua chat | Chua chay audit truoc | Dung dryrun, thu hep scope, them exception co ly do |

## Checklist Minh Chung

- [ ] Output `kubectl get role,rolebinding -n mini-platform`.
- [ ] Output `kubectl auth can-i` cho developer/viewer/sre.
- [ ] Screenshot hoac log Gatekeeper reject pod privileged.
- [ ] Screenshot hoac log Gatekeeper reject workload thieu label bat buoc.
- [ ] Ghi chu ngan ve policy nao nen audit truoc khi enforce.

## Cau Hoi Tu On

- RBAC khac admission policy nhu the nao?
- Khi nao dung `RoleBinding` voi `ClusterRole`?
- Vi sao `ClusterRoleBinding` nguy hiem hon `RoleBinding`?
- `ConstraintTemplate` khac `Constraint` nhu the nao?
- Vi sao nen rollout policy bang audit mode truoc?
