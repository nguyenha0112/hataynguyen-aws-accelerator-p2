# W9-D1 - GitOps va CI/CD

## Muc Tieu

Sau ngay nay ban can hieu cach delivery Kubernetes bang GitOps:

- Git la source of truth cho desired state.
- CI chay tren pull request de validate manifest.
- ArgoCD sync thay doi da merge vao cluster.
- Rollback uu tien bang Git revert thay vi sua tay trong cluster.

## Van De Can Giai Quyet

O W8, ban co the da apply manifest bang lenh:

```powershell
kubectl apply -f manifests/
```

Cach nay tot de hoc Kubernetes, nhung khi lam team se co nhieu van de:

- Khong ro ai da apply thay doi nao.
- Laptop cua moi nguoi co the apply khac nhau.
- Cluster co the bi sua tay va lech voi repo.
- Rollback kho audit neu chi dung command history.
- PR co the merge manifest sai cu phap neu khong co CI.

GitOps giai quyet bang cach dat Git vao trung tam cua delivery.

## GitOps La Gi?

GitOps la mo hinh van hanh trong do toan bo desired state cua he thong duoc khai bao trong Git. Mot controller trong cluster se lien tuc doc repo va reconcile cluster ve dung trang thai do.

Cong thuc ngan gon:

```text
Git desired state + GitOps controller = Cluster live state
```

Neu muon thay doi he thong, ban tao commit. Neu muon rollback, ban revert commit. Git tro thanh audit log cua moi thay doi.

## Desired State Va Live State

| Khai niem | Y nghia | Vi du |
|---|---|---|
| Desired state | Trang thai mong muon trong Git | Deployment replicas = 3 |
| Live state | Trang thai dang ton tai trong cluster | Deployment replicas = 1 |
| Drift | Khi live state khac desired state | Ai do scale tay xuong 1 |
| Reconcile | Controller dua live state ve desired state | ArgoCD scale lai thanh 3 |

Tu duy nay rat quan trong: Kubernetes va GitOps deu la declarative. Ban khai bao "toi muon gi", controller tu tinh "can lam gi".

## ArgoCD

ArgoCD la GitOps controller pho bien cho Kubernetes. No chay trong cluster va theo doi Git repository.

### ArgoCD Lam Gi?

- Doc manifest tu Git.
- So sanh manifest voi resource dang co trong cluster.
- Bao trang thai `Synced` neu cluster khop Git.
- Bao `OutOfSync` neu cluster lech Git.
- Bao `Healthy` neu resource chay tot theo health check.
- Apply resource khi sync.
- Cho xem diff giua Git va cluster.

### Pull-Based Delivery

ArgoCD thuong dung mo hinh pull-based:

```text
Git repo -> ArgoCD trong cluster -> Kubernetes API
```

CI khong can giu kubeconfig production. Cluster tu pull desired state tu Git. Cach nay giam rui ro lo credential va de audit hon.

### Application

`Application` la custom resource cua ArgoCD, mo ta:

- Repo URL.
- Revision/branch/path can theo doi.
- Namespace dich.
- Chinh sach sync.

Vi du trong repo:

```text
cloud/w9/W9-D1_GitOps_CICD/argocd/app-of-apps.yaml
```

## App Of Apps

App of Apps la pattern trong ArgoCD: mot Application cha quan ly nhieu Application con.

Loi ich:

- Co mot root app de bootstrap toan bo platform.
- Tach tung component thanh app rieng.
- De bat/tat hoac sync tung phan.
- Phu hop khi platform co nhieu namespace, service, dashboard, rollout.

Vi du:

```text
root-app
  -> platform-app
  -> observability-app
  -> rollout-app
```

## Sync Policy

ArgoCD co hai cach sync chinh:

| Kieu sync | Y nghia | Khi dung |
|---|---|---|
| Manual sync | Nguoi van hanh bam sync hoac chay command | Moi truong can kiem soat chat |
| Automated sync | ArgoCD tu sync khi Git thay doi | Moi truong dev/staging, platform on dinh |

Automated sync co cac tuy chon hay gap:

- `prune`: xoa resource trong cluster neu resource da bi xoa khoi Git.
- `selfHeal`: sua lai drift neu ai do thay doi tay trong cluster.
- `allowEmpty`: cho phep app co path rong, can than khi dung.

## Sync Waves

Mot so resource phai tao truoc resource khac. Vi du namespace phai co truoc deployment. Sync waves cho phep sap thu tu apply bang annotation:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"
```

Thu tu hay dung:

| Wave | Resource |
|---:|---|
| 0 | Namespace, CRD |
| 1 | ConfigMap, Secret, ServiceAccount |
| 2 | Service |
| 3 | Deployment/Rollout |
| 4 | Ingress, monitoring rule |

## CI/CD Trong GitOps

Trong GitOps, CI va CD tach vai tro ro rang:

| Phan | Nhiem vu |
|---|---|
| CI | Test, lint, validate manifest, build image |
| CD | Dua desired state tu Git vao cluster |

CI khong nen apply truc tiep vao cluster neu dang theo GitOps. CI chi can dam bao code va manifest du dieu kien merge.

## CI Nen Kiem Tra Gi?

Cho Kubernetes manifest, CI nen kiem tra:

- YAML parse duoc.
- Kubernetes schema hop le.
- Kustomize/Helm render thanh cong neu co dung.
- Khong co image tag nguy hiem nhu `latest` trong moi truong nghiem tuc.
- Resource co namespace dung.
- Config khong chua secret plaintext.

File workflow trong repo:

```text
cloud/w9/W9-D1_GitOps_CICD/.github/workflows/w9-gitops-ci.yml
```

## Rollback

### Rollback Uu Tien: Git Revert

Neu commit A lam he thong loi:

```powershell
git revert <bad_commit>
git push
```

ArgoCD thay Git quay ve desired state tot va sync lai cluster.

Loi ich:

- Co audit trail.
- Ca team thay doi rollback trong Git.
- Cluster khong bi lech voi repo.

### Rollback Khan Cap: Kubectl

Khi su co dang anh huong nguoi dung va can giam thiet hai ngay:

```powershell
kubectl rollout undo deployment/<name> -n <namespace>
```

Nhung sau do van phai sua Git. Neu khong, ArgoCD co the sync lai version loi tu Git.

## ArgoCD Vs Flux

| Tieu chi | ArgoCD | Flux |
|---|---|---|
| UI | Manh, de demo va quan sat | Nhe hon, chu yeu CLI/YAML |
| Mo hinh | Application-centric | Toolkit nhieu controller |
| Bootstrapping | App of Apps pho bien | GitRepository/Kustomization |
| Trai nghiem hoc | De nhin diff, health, sync | Tot cho automation Git-native |

Ca hai deu la GitOps controller tot. Repo nay dung ArgoCD vi UI va Application model de hoc.

## Lenh Chay Local

```powershell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd
kubectl apply -f argocd/app-of-apps.yaml
kubectl get applications -n argocd
```

Mo UI local:

```powershell
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Lay password admin ban dau:

```powershell
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}"
```

Neu can decode tren PowerShell:

```powershell
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("<base64-password>"))
```

## Lenh Kiem Tra

```powershell
kubectl get applications -n argocd
kubectl describe application <app-name> -n argocd
kubectl get events -n argocd --sort-by=.lastTimestamp
```

Trang thai can thay:

- `Synced`: live state khop Git.
- `Healthy`: resource dang chay tot.
- `OutOfSync`: Git va cluster dang lech.
- `Degraded`: resource co van de.

## Loi Hay Gap

| Loi | Nguyen nhan | Cach xu ly |
|---|---|---|
| App OutOfSync | Cluster khac Git hoac chua sync | Xem diff, sync lai |
| App Degraded | Pod crash, service sai selector, image pull fail | Describe pod/deployment |
| Permission denied | ArgoCD thieu quyen tren namespace | Kiem tra RBAC |
| Path not found | Application tro sai repo path | Sua `source.path` |
| Repo URL sai | ArgoCD khong clone duoc repo | Sua `repoURL`, credential neu private |

## Checklist Minh Chung

- [ ] Screenshot GitHub Actions PR check.
- [ ] Output `kubectl get applications -n argocd`.
- [ ] Screenshot ArgoCD UI co trang thai `Synced` va `Healthy`.
- [ ] Ghi chu ngan so sanh ArgoCD va Flux.

## Cau Hoi Tu On

- Vi sao GitOps uu tien pull-based hon push-based?
- Drift la gi? Vi sao drift nguy hiem?
- Khi nao nen bat automated sync?
- `prune` va `selfHeal` khac nhau nhu the nao?
- Neu da chay `kubectl rollout undo`, vi sao van can `git revert`?
