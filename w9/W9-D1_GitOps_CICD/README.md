# W9-D1 - GitOps & CI/CD

## Mục Tiêu

Hiểu và chuẩn bị luồng delivery bằng GitOps cho platform Kubernetes ở W8:

- Git là nguồn lưu desired state.
- CI validate manifests trước khi merge.
- ArgoCD sync thay đổi đã merge vào cluster.
- Rollback ưu tiên làm từ Git; `kubectl rollout undo` chỉ dùng khi khẩn cấp.

## Khái Niệm Chính

| Topic | Notes |
|---|---|
| GitOps | Desired state được khai báo trong Git và được controller reconcile. |
| ArgoCD | Controller dạng pull-based, sync trạng thái cluster từ manifests trong repo. |
| Flux | Công cụ GitOps thay thế ArgoCD, cũng dùng mô hình pull-based. |
| App of Apps | Một ArgoCD Application cha quản lý nhiều Application con. |
| Sync Waves | Cơ chế sắp thứ tự apply, ví dụ namespace trước workload. |
| CI/CD | CI check trên PR, CD do GitOps thực hiện sau khi merge. |

## Lệnh Chạy Local

```powershell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd
kubectl apply -f argocd/app-of-apps.yaml
kubectl get applications -n argocd
```

## Cách Chọn Rollback

- Rollback ưu tiên: `git revert <bad_commit>` rồi để ArgoCD sync desired state đã sửa.
- Rollback khẩn cấp: `kubectl rollout undo deployment/<name> -n <namespace>` trong lúc chuẩn bị Git revert.

## Checklist Minh Chứng

- [ ] Screenshot GitHub Actions PR check.
- [ ] Output `kubectl get applications -n argocd`.
- [ ] Screenshot ArgoCD UI có trạng thái Synced và Healthy.
- [ ] Ghi chú ngắn so sánh ArgoCD và Flux.
