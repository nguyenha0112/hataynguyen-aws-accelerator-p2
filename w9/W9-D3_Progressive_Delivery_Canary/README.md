# W9-D3 - Progressive Delivery: Canary

## Mục Tiêu

Dùng canary delivery để version mới chỉ nhận một phần nhỏ traffic trước, sau đó tự động promote hoặc abort dựa trên metrics.

## Chiến Lược Canary

| Step | Traffic | Check |
|---|---:|---|
| Bắt đầu | 20% | Error rate phải dưới 5%. |
| Tiếp tục | 50% | Error rate phải dưới 5%. |
| Promote | 100% | Rollout hoàn tất nếu analysis pass. |
| Abort | Version stable trước đó | Rollout dừng nếu Prometheus analysis fail. |

## Lệnh Chạy Local

```powershell
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
kubectl apply -f rollout/analysis-template.yaml
kubectl apply -f rollout/web-rollout.yaml
kubectl argo rollouts get rollout web -n mini-platform --watch
```

## Checklist Minh Chứng

- [ ] Trạng thái rollout ở mức 20% và 50% traffic.
- [ ] Kết quả Prometheus AnalysisRun.
- [ ] Minh chứng abort từ metric xấu hoặc image lỗi cố ý.
- [ ] Giải thích ngắn vì sao canary an toàn hơn deploy thẳng.
