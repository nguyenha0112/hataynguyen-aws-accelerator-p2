# W8 Ngày 2 - Kubernetes Foundation

Ngày: 02/06/2026

## Chủ đề

- Tổng quan về Container và orchestration.
- Pod, Deployment, Service.
- Liveness và readiness probes.
- ConfigMap và Secret.
- Khái niệm cơ bản về NetworkPolicy.
- Chuẩn bị môi trường: Docker Desktop, kubectl, và minikube.

## Các lệnh thực hành

```powershell
docker version
kubectl version --client
minikube version
minikube start
kubectl get nodes
```

## Ghi chú quan trọng

- **Pod** là đơn vị triển khai nhỏ nhất trong Kubernetes.
- **Deployment** quản lý số lượng bản sao (replica count) và cập nhật xoay vòng (rolling updates).
- **Service** cung cấp một điểm truy cập ổn định cho các Pod thường xuyên thay đổi.
- **ConfigMap** dùng để lưu trữ các cấu hình không nhạy cảm (non-sensitive config).
- **Secret** dùng để lưu trữ cấu hình nhạy cảm, nhưng vẫn cần được xử lý cẩn thận.
- **Readiness probe** quyết định xem một Pod đã sẵn sàng nhận traffic hay chưa.
- **Liveness probe** quyết định xem một container có cần được khởi động lại (restart) hay không.

## Danh sách minh chứng (Evidence Checklist)

- [ ] Cài đặt thành công và đang chạy Docker Desktop.
- [ ] Kết quả chạy lệnh `kubectl version --client`.
- [ ] Kết quả chạy lệnh `minikube version`.
- [ ] Kết quả chạy lệnh `kubectl get nodes` sau khi khởi động minikube.
