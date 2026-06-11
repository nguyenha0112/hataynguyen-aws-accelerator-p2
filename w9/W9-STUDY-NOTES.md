# W9 Study Notes - GitOps, Observability, SLO, Canary

File này gom kiến thức tuần 9 vào một chỗ để bạn ngồi học. Trọng tâm của tuần là biến platform Kubernetes từ kiểu deploy thủ công sang một luồng delivery có kiểm soát, quan sát được và rollback được.

## 1. Tổng Quan Tuần 9

Ở W8, bạn đã học Kubernetes và Terraform: tạo namespace, pod, deployment, service, module, state. Nhưng khi hệ thống có nhiều thay đổi, việc chạy tay các lệnh như `kubectl apply -f ...` bắt đầu nguy hiểm.

Các vấn đề thường gặp:

- Không rõ ai đã apply thay đổi nào.
- Không chắc cluster đang chạy version nào.
- Dễ nhầm context giữa dev/staging/prod.
- Cluster có thể bị sửa tay và lệch với repo.
- Rollback khó vì không có lịch sử rõ ràng.
- Manifest sai vẫn có thể được apply nếu không có CI kiểm tra.
- Deploy version mới 100% traffic ngay lập tức có thể làm tất cả người dùng bị ảnh hưởng.

Tuần 9 giải quyết bằng 3 lớp:

- **GitOps và CI/CD**: Git là source of truth, ArgoCD sync cluster theo Git.
- **Observability và SLO**: đo xem service có thật sự tốt với người dùng không.
- **Progressive Delivery**: release bằng canary, tự promote hoặc abort dựa trên metric.

Luồng tổng quát:

```text
Git -> CI validate -> ArgoCD sync -> Kubernetes chạy app
                          |
                          v
                 Metrics / Logs / Traces
                          |
                          v
            Canary promote hoặc abort theo SLO
```

## 2. Vấn Đề Khi Deploy Tay

`kubectl apply` rất tiện khi học và debug nhanh. Nhưng nếu dùng làm cách vận hành chính, hệ thống dễ rối.

| Vấn đề | Giải thích | Ví dụ |
|---|---|---|
| Không ghi lại state | Developer apply từ laptop, không ai chắc cluster đang chạy gì | 3 ngày sau hỏi prod đang chạy image nào thì không nhớ |
| Nhầm context | Lệnh đúng nhưng chạy vào sai cluster | Tưởng đang ở dev nhưng context là prod |
| Rollback khó | Không biết "trạng thái hôm qua" là manifest nào | `kubectl rollout undo` chỉ có revision, không có ý nghĩa nghiệp vụ |
| Credential cũ còn tồn tại | Người đã nghỉ việc vẫn còn kubeconfig | Vẫn có thể apply vào cluster nếu credential chưa bị thu hồi |

Gốc rễ là không có **single source of truth**. Nếu cluster là nơi mọi người sửa tay, không có một bản ghi đáng tin về hệ thống.

GitOps đổi câu hỏi:

```text
Không hỏi: Ai vừa apply gì vào cluster?
Hãy hỏi: Commit nào đang là desired state của cluster?
```

## 3. GitOps Là Gì?

GitOps là mô hình vận hành trong đó **desired state** của hệ thống nằm trong Git. Cluster không còn là nơi bạn vào sửa tay tùy tiện. Thay vào đó, một GitOps controller như ArgoCD đọc repo và reconcile cluster về đúng trạng thái đã khai báo.

```text
Git desired state + GitOps controller = Cluster live state
```

Ví dụ desired state:

- Namespace `mini-platform` phải tồn tại.
- Deployment web dùng image version `v1`.
- Service web expose port 80.
- Rollout canary đi qua 20%, 50%, 100%.
- Alert rule cảnh báo khi burn rate cao.

**Live state** là trạng thái thật đang có trong cluster. Nếu live state khác desired state thì gọi là **drift**.

Ví dụ drift:

- Git khai báo `replicas: 3`.
- Ai đó chạy `kubectl scale deployment web --replicas=9`.
- Cluster bây giờ khác Git.
- ArgoCD phát hiện `OutOfSync`.
- Nếu bật self-heal, ArgoCD đưa replicas về 3.

Lợi ích của GitOps:

- Mọi thay đổi có commit, review và lịch sử.
- Rollback bằng `git revert`.
- Cluster ít phụ thuộc laptop cá nhân.
- CI có thể validate trước khi merge.
- Dễ phát hiện drift giữa Git và cluster.

## 4. Bốn Nguyên Tắc OpenGitOps

| Nguyên tắc | Ý nghĩa | Ví dụ |
|---|---|---|
| Declarative | Khai báo muốn gì, không viết từng bước làm thế nào | `replicas: 3` thay vì script tạo từng pod |
| Versioned | Mọi thay đổi lưu trong Git | `git log` biết ai đổi, lúc nào, đổi gì |
| Pulled | Agent trong cluster tự kéo thay đổi từ Git | ArgoCD poll repo, developer không cần kubeconfig prod |
| Reconciled | Controller liên tục so sánh Git với cluster | Git nói 3 replicas, ai scale tay lên 9 thì ArgoCD đưa về 3 |

Cách nhớ:

```text
Declarative: viết trạng thái mong muốn
Versioned: mọi thay đổi có lịch sử
Pulled: cluster tự kéo từ Git
Reconciled: lệch thì sửa về đúng Git
```

GitOps giống controller pattern của Kubernetes. ReplicaSet reconcile số pod thực tế với số pod mong muốn. ArgoCD reconcile cluster thực tế với manifest trong Git.

## 5. ArgoCD

ArgoCD là GitOps controller cho Kubernetes. Nó chạy trong cluster và theo dõi Git repository.

ArgoCD làm các việc chính:

- Clone hoặc đọc manifests từ Git.
- So sánh manifests với resource đang có trong cluster.
- Hiển thị diff giữa Git và cluster.
- Báo `Synced` nếu cluster khớp Git.
- Báo `OutOfSync` nếu cluster lệch Git.
- Báo `Healthy` nếu resource chạy tốt.
- Báo `Degraded` nếu resource có vấn đề.
- Sync thay đổi vào cluster.

Mô hình thường dùng là pull-based:

```text
Git repo -> ArgoCD trong cluster -> Kubernetes API
```

Điểm hay của pull-based là CI không cần giữ kubeconfig production. Cluster tự lấy desired state từ Git.

## 6. ArgoCD Application

`Application` là custom resource của ArgoCD. Nó nói cho ArgoCD biết:

- Repo URL nào cần theo dõi.
- Branch/revision nào.
- Path nào trong repo chứa manifest.
- Namespace đích là gì.
- Có auto sync không.

Trạng thái hay gặp:

| Trạng thái | Ý nghĩa |
|---|---|
| `Synced` | Cluster khớp Git |
| `OutOfSync` | Cluster khác Git |
| `Healthy` | Resource chạy tốt |
| `Degraded` | Resource có lỗi |
| `Missing` | Resource trong Git nhưng chưa có trên cluster |

Ví dụ Application:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/<ban>/gitops.git
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: demo
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Ý chính:

- Bạn không apply trực tiếp `k8s/web.yaml`.
- Bạn apply Application để ArgoCD biết phải quản lý path `k8s`.
- Sau đó ArgoCD tự tạo resource trong cluster.

## 7. Sync Policy, Prune Và Self-Heal

ArgoCD có sync thủ công và sync tự động.

| Kiểu sync | Ý nghĩa |
|---|---|
| Manual sync | Người vận hành bấm sync hoặc chạy command |
| Automated sync | ArgoCD tự sync khi Git thay đổi |

Tùy chọn quan trọng:

- `prune`: xóa resource trong cluster nếu resource đã bị xóa khỏi Git.
- `selfHeal`: sửa drift nếu ai đó sửa tay trong cluster.

Cẩn thận với `prune`, vì nếu repo/path sai có thể xóa resource ngoài ý muốn.

## 8. App Of Apps

App of Apps là pattern dùng một ArgoCD Application cha để quản lý nhiều Application con.

```text
root-app
  -> platform-app
  -> observability-app
  -> rollout-app
```

Lợi ích:

- Bootstrap toàn bộ platform từ một root app.
- Tách component theo folder.
- Thêm app mới bằng cách thả file Application vào folder app con rồi push.

Ví dụ root app:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/<ban>/gitops.git
    path: argocd/apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Sau khi apply root một lần, root sẽ quản lý các app con trong `argocd/apps`.

## 9. Sync Waves

Một số resource phải tạo theo thứ tự:

- Namespace phải có trước resource trong namespace đó.
- ConfigMap phải có trước Deployment nếu Deployment dùng `envFrom`.
- Service nên tạo sau khi labels/selectors đã rõ.

ArgoCD sync waves ép thứ tự apply bằng annotation:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"
```

Thứ tự mẫu:

```text
Namespace -1 -> ConfigMap 0 -> Deployment 1 -> Service 2
```

Nếu thiếu sync wave, Deployment có thể chạy trước ConfigMap và bị `CreateContainerConfigError`.

## 10. CI/CD Trong GitOps

Trong GitOps, CI và CD có vai trò khác nhau:

| Phần | Nhiệm vụ |
|---|---|
| CI | Test, lint, validate manifest, build image |
| CD | Đưa desired state từ Git vào cluster |

CI nên chạy trên pull request để chặn lỗi trước khi merge.

CI cho Kubernetes manifest nên kiểm tra:

- YAML parse được.
- Schema Kubernetes hợp lệ.
- Kustomize/Helm render được nếu có.
- Không có secret plaintext.
- Không dùng image tag `latest` cho môi trường nghiêm túc.
- Namespace đúng.
- Service selector khớp label pod.

Trong GitOps, CI không nên apply trực tiếp vào cluster production. CI chỉ đảm bảo thay đổi đủ tốt để merge; ArgoCD làm CD.

Ví dụ workflow validate bằng kubeconform:

```yaml
name: validate

on:
  pull_request:
    paths:
      - "k8s/**"

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          curl -sSLo kc.tgz https://github.com/yannh/kubeconform/releases/download/v0.6.7/kubeconform-linux-amd64.tar.gz
          tar -xzf kc.tgz
          sudo mv kubeconform /usr/local/bin/
      - run: kubeconform -strict -summary k8s/
```

Branch protection trên GitHub:

- Settings -> Branches -> Add rule cho `main`.
- Bật Require a pull request before merging.
- Bật Require status checks to pass.
- Chọn check `validate`.

Kết quả:

- PR manifest sai -> CI đỏ -> không merge được.
- PR chưa review -> không merge được nếu bật approval.
- Main branch trở thành nơi chứa desired state đã được kiểm tra.

## 11. Rollback Trong GitOps

Cách rollback ưu tiên là rollback bằng Git:

```powershell
git revert <bad_commit>
git push
```

Sau khi Git quay về desired state tốt, ArgoCD sync cluster về trạng thái tốt.

So sánh:

| Cách | Kết quả |
|---|---|
| `git revert` | Sửa source of truth, rollback có lịch sử |
| `kubectl rollout undo` | Chỉ sửa live state tạm thời, Git vẫn đang trỏ đến version mới |

Nếu ArgoCD đang bật self-heal, `kubectl rollout undo` có thể bị ArgoCD ghi đè lại theo Git. Vì vậy rollback thật trong GitOps phải là rollback Git.

## 12. Observability Là Gì?

Observability là khả năng hiểu hệ thống đang xảy ra gì dựa trên tín hiệu nó phát ra.

Monitoring có thể hỏi:

- CPU có cao không?
- Pod có running không?

Observability hỏi sâu hơn:

- Người dùng có request thành công không?
- Request có chậm không?
- Lỗi xảy ra sau deploy nào?
- Service nào làm request chậm?
- Version mới có làm error rate tăng không?

Ba tín hiệu chính:

- **Metrics**: số liệu tổng hợp theo thời gian.
- **Logs**: sự kiện chi tiết.
- **Traces**: đường đi của một request qua các service.

## 13. Metrics

Metrics là dữ liệu dạng số theo thời gian. Prometheus thu thập metrics bằng cách scrape endpoint, thường là `/metrics`.

| Loại | Ý nghĩa | Ví dụ |
|---|---|---|
| Counter | Chỉ tăng | Tổng request |
| Gauge | Tăng giảm được | Số pod ready |
| Histogram | Phân phối giá trị | Latency |
| Summary | Quantile tính ở client | p95 latency |

Metric HTTP quan trọng:

- Tổng request.
- Error rate.
- Request duration.
- p95/p99 latency.
- Request rate.

CPU/RAM vẫn hữu ích, nhưng không đủ để kết luận người dùng đang ổn. App có thể CPU thấp nhưng vẫn trả 500.

## 14. Prometheus Và Grafana

Prometheus:

- Scrape metrics từ targets.
- Lưu time-series data.
- Query bằng PromQL.
- Đánh giá alert rules.

Grafana:

- Vẽ dashboard từ Prometheus, Loki, Tempo, v.v.
- Giúp nhìn availability, latency, error rate, traffic.

Dashboard tốt nên trả lời:

- Service có đang up không?
- Error rate hiện tại bao nhiêu?
- p95 latency có tăng không?
- Deploy mới có liên quan đến lỗi không?
- SLO còn bao nhiêu error budget?

## 15. Logs

Logs dùng để điều tra sự kiện cụ thể. Log tốt nên có cấu trúc.

Ví dụ:

```json
{
  "level": "error",
  "service": "web",
  "request_id": "abc123",
  "status": 500,
  "message": "database timeout"
}
```

Log nên có:

- Timestamp.
- Level.
- Service name.
- Request ID hoặc correlation ID.
- Message ngắn gọn.
- Context cần thiết.

Không nên log secret, token, password hoặc thông tin nhạy cảm.

## 16. Traces

Trace cho thấy một request đi qua những service nào và mất bao lâu ở mỗi bước.

```text
Trace request /checkout
  gateway: 20 ms
  payment-api: 120 ms
  database: 400 ms
```

Trace hữu ích khi:

- Hệ thống có nhiều service.
- Latency cao nhưng không rõ chậm ở đâu.
- Cần nối logs của nhiều service bằng một request ID.

## 17. OpenTelemetry

OpenTelemetry là chuẩn và bộ công cụ để thu thập telemetry: metrics, logs, traces.

OpenTelemetry Collector nằm giữa app và backend quan sát:

```text
App -> OTel Collector -> Prometheus / Loki / Tempo / Jaeger
```

Collector có các phần:

| Thành phần | Ý nghĩa |
|---|---|
| Receiver | Nhận telemetry |
| Processor | Xử lý, batch, thêm metadata |
| Exporter | Gửi sang backend |
| Pipeline | Nối receiver, processor, exporter |

Ví dụ app gửi OTLP trace vào Collector, Collector export sang Jaeger hoặc Tempo.

## 18. SLI Và SLO

SLI là **Service Level Indicator**: chỉ số đo mức độ tốt của service.

SLO là **Service Level Objective**: mục tiêu cho SLI trong một khoảng thời gian.

| User Journey | SLI | SLO |
|---|---|---|
| Web request availability | Tỉ lệ request không phải 5xx | 99.5% trong 30 ngày |
| Web request latency | Tỉ lệ request dưới 500 ms | 95% trong 30 ngày |

SLI phải đo được. SLO phải có con số và time window rõ ràng.

Không nên đặt SLO 100% nếu không có lý do đặc biệt, vì 100% gần như không thực tế và làm team không còn error budget.

## 19. Error Budget

Error budget là phần lỗi được phép.

Nếu SLO là 99.5% availability:

```text
Error budget = 100% - 99.5% = 0.5%
```

Nếu có 100,000 request/tháng, error budget là 500 request lỗi.

Dùng error budget để quyết định:

- Còn nhiều budget: có thể release nhanh hơn.
- Sắp hết budget: giảm release, ưu tiên fix reliability.
- Đốt budget quá nhanh: alert, rollback, abort canary.

## 20. Burn Rate

Burn rate là tốc độ đốt error budget.

- Burn rate = 1: đốt đúng tốc độ cho phép.
- Burn rate = 10: đốt nhanh gấp 10 lần.

Alert theo burn rate tốt hơn alert theo error rate đơn lẻ vì nó gắn với SLO.

| Loại | Mục đích |
|---|---|
| Fast burn | Phát hiện sự cố nghiêm trọng nhanh |
| Slow burn | Phát hiện degradation kéo dài |

Fast burn có thể nhìn cửa sổ 5 phút và 1 giờ. Slow burn có thể nhìn 30 phút và 6 giờ.

## 21. PromQL Cần Nhớ

Error rate:

```promql
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))
```

Availability:

```promql
1 - (
  sum(rate(http_requests_total{status=~"5.."}[5m]))
  /
  sum(rate(http_requests_total[5m]))
)
```

Latency dưới 500 ms:

```promql
sum(rate(http_request_duration_seconds_bucket{le="0.5"}[5m]))
/
sum(rate(http_request_duration_seconds_count[5m]))
```

p95 latency:

```promql
histogram_quantile(
  0.95,
  sum by (le) (rate(http_request_duration_seconds_bucket[5m]))
)
```

## 22. Progressive Delivery

Progressive delivery là cách đưa thay đổi ra môi trường thật từng bước, kèm điều kiện kiểm tra.

Thay vì deploy 100% ngay lập tức, bạn có thể:

- Đưa cho 5% user.
- Đưa cho 20% traffic.
- Đưa vào một region.
- Bật feature flag cho một nhóm nhỏ.

Mục tiêu:

- Giảm blast radius.
- Phát hiện lỗi sớm.
- Rollback nhanh.
- Ra quyết định dựa trên metric.

## 23. Các Kiểu Release

| Kiểu | Cách làm | Điểm mạnh |
|---|---|---|
| Rolling update | Thay pod cũ bằng pod mới dần dần | Đơn giản, Kubernetes có sẵn |
| Blue/Green | Chạy song song blue và green rồi switch traffic | Rollback nhanh |
| Canary | Version mới nhận một phần traffic, tăng dần nếu tốt | Giảm rủi ro và có metric gate |
| Feature flag | Deploy code nhưng bật/tắt tính năng bằng config | Tách deploy khỏi release |

## 24. Canary Release

Canary đưa version mới nhận một phần nhỏ traffic trước.

```text
20% traffic -> check metric
50% traffic -> check metric
100% traffic -> promote
fail metric -> abort
```

Canary chỉ có ý nghĩa nếu có observability. Nếu không có metric, bạn không biết version mới tốt hay xấu.

Metric nên dùng cho canary:

- Error rate 5xx.
- p95 latency.
- Availability SLI.
- Business metric quan trọng nếu có.

Không nên promote canary chỉ dựa vào pod running. Pod running không đảm bảo app trả response đúng.

## 25. Argo Rollouts

Argo Rollouts là controller mở rộng Kubernetes để làm progressive delivery.

Nó cung cấp resource `Rollout`, thay thế `Deployment` khi cần:

- Canary.
- Blue/Green.
- Pause.
- Promote.
- Abort.
- Analysis dựa trên metric.

Thành phần chính:

| Thành phần | Ý nghĩa |
|---|---|
| Rollout | Workload và strategy release |
| AnalysisTemplate | Mẫu metric cần kiểm tra |
| AnalysisRun | Lần chạy analysis cụ thể |

Ví dụ steps:

```yaml
steps:
  - setWeight: 20
  - pause:
      duration: 1m
  - analysis:
      templates:
        - templateName: success-rate
  - setWeight: 50
  - pause:
      duration: 1m
```

## 26. Promote, Pause, Abort

| Hành động | Ý nghĩa | Khi dùng |
|---|---|---|
| Promote | Cho canary đi tiếp hoặc lên 100% | Metric tốt |
| Pause | Dừng tạm để quan sát hoặc approve | Cần manual gate |
| Abort | Dừng rollout mới và quay về stable | Metric xấu |
| Retry | Chạy lại rollout/analysis | Lỗi tạm thời đã được sửa |

Lệnh hay gặp:

```powershell
kubectl argo rollouts get rollout web -n mini-platform
kubectl argo rollouts promote web -n mini-platform
kubectl argo rollouts abort web -n mini-platform
kubectl argo rollouts retry rollout web -n mini-platform
```

Nếu không có plugin:

```powershell
kubectl get rollout -n mini-platform
kubectl describe rollout web -n mini-platform
kubectl get analysisrun -n mini-platform
```

## 27. Luồng Hoạt Động Tổng Hợp

```text
Developer tạo PR
  -> CI validate YAML/Kubernetes manifests
  -> PR merge vào main
  -> ArgoCD thấy Git thay đổi
  -> ArgoCD sync manifest vào cluster
  -> Argo Rollouts bắt đầu canary
  -> Prometheus cung cấp metric
  -> AnalysisRun đánh giá error rate/latency
  -> Metric tốt: promote
  -> Metric xấu: abort
  -> Nếu cần rollback lâu dài: git revert
```

## 28. Lab GitOps Buổi Sáng

### Lab 0 - Dựng Cluster Và Repo

```powershell
minikube start -p w9 --driver=docker
kubectl config use-context w9
kubectl get nodes
```

Tạo repo local:

```powershell
mkdir gitops
cd gitops
mkdir k8s
```

Tạo app đơn giản `k8s/web.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:1.27
```

Đẩy lên GitHub:

```powershell
git init
git add .
git commit -m "init"
git branch -M main
git remote add origin https://github.com/<ban>/gitops.git
git push -u origin main
```

Ý chính: chưa apply `k8s/web.yaml` vào cluster. Để ArgoCD làm việc đó.

### Lab 1 - Cài ArgoCD

```powershell
kubectl create ns argocd
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deploy/argocd-server
kubectl -n argocd get pods
```

Dùng `--server-side` để tránh lỗi annotation quá dài khi apply CRD lớn của ArgoCD.

Mở UI:

```powershell
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Lấy password ban đầu:

```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'
```

Decode trên PowerShell:

```powershell
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("<base64-password>"))
```

### Lab 2 - Tạo Application

Tạo `argocd/apps/web.yaml` như phần Application ở trên, rồi apply:

```powershell
kubectl apply -f argocd/apps/web.yaml
kubectl -n argocd get app web
kubectl -n demo get deploy,pod
```

Nếu namespace `demo` chưa tồn tại:

```powershell
kubectl create ns demo
```

Trong GitOps thật, namespace cũng nên nằm trong Git.

### Lab 3 - Đổi Qua Git Và Self-Heal

Sửa `replicas: 2` thành `replicas: 4`, commit và push:

```powershell
git add k8s/web.yaml
git commit -m "scale web to 4"
git push
```

ArgoCD sẽ tự pull và sync. Kiểm tra:

```powershell
kubectl -n demo get deploy web
kubectl -n demo get pods
```

Thử self-heal:

```powershell
kubectl -n demo scale deploy/web --replicas=9
kubectl -n demo get deploy web -w
```

Nếu `selfHeal: true`, ArgoCD sẽ đưa replicas về số trong Git.

### Lab 4 - Rollback Bằng Git Revert

```powershell
git revert HEAD --no-edit
git push
```

ArgoCD thấy Git đã quay về state trước và sync cluster.

### Lab 5 - App Of Apps

Tạo `argocd/root.yaml`, push lên Git, rồi apply root một lần:

```powershell
git add argocd/root.yaml
git commit -m "app of apps"
git push
kubectl apply -f argocd/root.yaml
kubectl -n argocd get applications
```

Từ lúc này, thêm app mới bằng cách thả file Application vào `argocd/apps/` và push.

### Lab 6 - Sync Waves

Thứ tự nên dùng:

```text
Namespace -1 -> ConfigMap 0 -> Deployment 1 -> Service 2
```

Annotation:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
```

### Lab 7 - CI Validate

CI validate manifest trên PR, không apply vào cluster.

Khi bật branch protection:

- PR sai schema -> CI đỏ -> không merge được.
- PR thiếu review -> không merge được nếu yêu cầu approval.
- Main branch chỉ nhận desired state đã được kiểm tra.

## 29. Lab Tổng Hợp W9

Thứ tự chạy lab:

```powershell
minikube start
kubectl apply -f manifests/
kubectl apply -f argocd/
kubectl apply -f ../W9-D2_Observability_SLO_OTel/otel/
kubectl apply -f ../W9-D2_Observability_SLO_OTel/alert-rules/
kubectl apply -f rollout/
```

Kiểm tra:

```powershell
kubectl get all -n mini-platform
kubectl get applications -n argocd
kubectl get pods -n observability
kubectl get rollout -n mini-platform
kubectl get analysisrun -n mini-platform
```

Port-forward web service:

```powershell
kubectl port-forward svc/web -n mini-platform 8080:80
curl.exe http://localhost:8080
```

## 30. Lỗi Hay Gặp

| Lỗi | Nguyên nhân | Cách xử lý |
|---|---|---|
| ArgoCD Application không sync | Sai repo URL/path hoặc repo private thiếu credential | Sửa `repoURL`, `path`, credential |
| `OutOfSync` | Cluster khác Git | Xem diff, sync/revert |
| `Degraded` | Pod crash, image pull fail, service selector sai | `describe` pod/deployment/service |
| `no matches for kind PrometheusRule` | Chưa có Prometheus Operator CRD | Cài kube-prometheus-stack hoặc đổi rule format |
| `no matches for kind Rollout` | Chưa cài Argo Rollouts CRD | Cài Argo Rollouts controller |
| Canary fail liên tục | Query Prometheus sai hoặc metric xấu thật | Kiểm tra PromQL và target |
| Service không có endpoint | Selector không khớp pod label | Sửa label/selector |

## 31. Bảng Tóm Tắt Để Nhớ Nhanh

| Khái niệm | Nói ngắn gọn |
|---|---|
| GitOps | Git là source of truth cho desired state |
| ArgoCD | Controller sync cluster theo Git |
| Drift | Live state khác desired state |
| CI | Validate trước khi merge |
| CD | ArgoCD sync sau khi merge |
| Metrics | Số liệu theo thời gian |
| Logs | Sự kiện chi tiết |
| Traces | Đường đi của request |
| SLI | Chỉ số đo service |
| SLO | Mục tiêu cho SLI |
| Error budget | Phần lỗi được phép |
| Burn rate | Tốc độ đốt error budget |
| Canary | Release version mới theo từng phần traffic |
| AnalysisRun | Lần kiểm tra metric của rollout |
| Abort | Dừng rollout khi metric xấu |
| Promote | Đẩy rollout lên bước tiếp theo |

## 32. Câu Hỏi Tự Ôn

1. GitOps khác gì với `kubectl apply` từ laptop?
2. Desired state và live state khác nhau như thế nào?
3. Drift nguy hiểm ở điểm nào?
4. Vì sao rollback bằng Git tốt hơn rollback tay?
5. CI nên làm gì trong GitOps?
6. ArgoCD `Synced` và `Healthy` khác nhau như thế nào?
7. Metrics, logs, traces mỗi loại dùng để trả lời câu hỏi nào?
8. Vì sao CPU/RAM không đủ để đánh giá user experience?
9. SLI và SLO khác nhau như thế nào?
10. Error budget dùng để quyết định release ra sao?
11. Burn-rate alert tốt hơn alert error rate đơn giản như thế nào?
12. Canary khác rolling update như thế nào?
13. Vì sao canary cần Prometheus metric?
14. AnalysisTemplate và AnalysisRun khác nhau như thế nào?
15. Nếu abort canary nhưng không revert Git thì có thể xảy ra gì?

## 33. Ghi Nhớ Nhanh

Nếu chỉ nhớ vài ý:

1. Deploy tay không có single source of truth.
2. GitOps đặt desired state vào Git.
3. ArgoCD pull từ Git, không cần CI push vào cluster.
4. Declarative, versioned, pulled, reconciled là 4 nguyên tắc cốt lõi.
5. `selfHeal` sửa drift khi live state bị sửa tay.
6. Rollback đúng là `git revert`, không chỉ `kubectl rollout undo`.
7. App of Apps giúp root Application quản lý nhiều app con.
8. CI validate manifest trên PR, không apply vào cluster.
9. Observability cần metrics, logs, traces.
10. SLO giúp biến "hệ thống ổn" thành mục tiêu đo được.
11. Error budget giúp cân bằng tốc độ release và độ ổn định.
12. Canary chỉ an toàn khi có metric để quyết định promote hoặc abort.

## 34. Cách Học File Này

Đọc theo thứ tự:

1. Học GitOps và ArgoCD trước.
2. Học Observability, SLI, SLO.
3. Học Canary và Argo Rollouts.
4. Quay lại đọc luồng tổng hợp.
5. Trả lời câu hỏi tự ôn mà không nhìn đáp án.
6. Chạy lab nếu cần minh chứng.

Nếu chỉ có 30 phút, tập trung các mục: 2, 3, 4, 5, 10, 11, 18, 19, 20, 24, 25, 27, 31, 33.

## 35. Từng Bước Tạo Và Chạy ArgoCD Trên Máy Local

Phần này ghi lại đúng luồng để bạn tự làm lại phần ArgoCD trên minikube.

### Bước 1 - Kiểm Tra Minikube

Kiểm tra minikube đang chạy chưa:

```powershell
minikube status
```

Nếu thấy `Stopped`, bật lại:

```powershell
minikube start
```

Kiểm tra Kubernetes node:

```powershell
kubectl get nodes
```

Kết quả mong muốn:

```text
NAME       STATUS   ROLES           VERSION
minikube   Ready    control-plane   ...
```

Nếu node chưa `Ready`, chưa nên cài ArgoCD.

### Bước 2 - Tạo Namespace Cho ArgoCD

ArgoCD nên chạy trong namespace riêng:

```powershell
kubectl create namespace argocd
```

Nếu namespace đã tồn tại, Kubernetes sẽ báo `AlreadyExists`; khi đó có thể bỏ qua.

Kiểm tra:

```powershell
kubectl get ns argocd
```

### Bước 3 - Cài ArgoCD Controller

Cài ArgoCD bằng manifest chính thức:

```powershell
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Vì sao dùng `--server-side`?

- Manifest ArgoCD có CRD khá lớn.
- `kubectl apply` kiểu client-side đôi khi bị lỗi annotation quá dài.
- Server-side apply ổn hơn khi cài các manifest lớn.

### Bước 4 - Chờ Pod ArgoCD Chạy Xong

Xem danh sách pod:

```powershell
kubectl get pods -n argocd
```

Các pod quan trọng:

```text
argocd-application-controller
argocd-applicationset-controller
argocd-dex-server
argocd-notifications-controller
argocd-redis
argocd-repo-server
argocd-server
```

Kết quả mong muốn là tất cả đều `Running` và `READY` là `1/1`.

Ví dụ:

```text
NAME                                               READY   STATUS    RESTARTS
argocd-application-controller-0                    1/1     Running   0
argocd-applicationset-controller-xxxxx             1/1     Running   0
argocd-dex-server-xxxxx                            1/1     Running   0
argocd-notifications-controller-xxxxx              1/1     Running   0
argocd-redis-xxxxx                                 1/1     Running   0
argocd-repo-server-xxxxx                           1/1     Running   0
argocd-server-xxxxx                                1/1     Running   0
```

Có thể chờ từng deployment:

```powershell
kubectl -n argocd rollout status deploy/argocd-server --timeout=180s
kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=180s
kubectl -n argocd rollout status deploy/argocd-redis --timeout=180s
kubectl -n argocd rollout status deploy/argocd-dex-server --timeout=180s
```

Nếu pod đứng ở `ContainerCreating`, `Init:0/1`, hoặc `PodInitializing`, thường là đang kéo image. Kiểm tra bằng:

```powershell
kubectl get events -n argocd --sort-by=.lastTimestamp
```

Nếu muốn xem chi tiết pod:

```powershell
kubectl describe pod -n argocd <ten-pod>
```

### Bước 5 - Lấy Mật Khẩu Admin Ban Đầu

Lấy password dạng base64:

```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'
```

Decode trên PowerShell:

```powershell
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("<base64-password>"))
```

Ví dụ trên máy hiện tại, password đã decode là:

```text
DdgYNc3Bm7921R97
```

Lưu ý: password này là của lần cài hiện tại trên máy local. Nếu xóa namespace/cài lại ArgoCD, password có thể đổi.

### Bước 6 - Mở ArgoCD UI Bằng Port-Forward

Chạy port-forward:

```powershell
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Sau đó mở trình duyệt:

```text
https://localhost:8080
```

Đăng nhập:

```text
username: admin
password: <password-da-decode>
```

Trình duyệt có thể cảnh báo certificate vì đây là HTTPS local self-signed. Chọn advanced/continue để vào.

Nếu muốn chạy port-forward nền bằng PowerShell:

```powershell
Start-Process -FilePath kubectl -ArgumentList @('-n','argocd','port-forward','svc/argocd-server','8080:443') -WindowStyle Hidden
```

Kiểm tra nếu port-forward chạy đúng, sẽ thấy:

```text
Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080
```

### Bước 7 - Kiểm Tra ArgoCD Application

Sau khi ArgoCD chạy, kiểm tra Application hiện có:

```powershell
kubectl get applications -n argocd
```

Nếu mới cài xong, thường sẽ thấy:

```text
No resources found in argocd namespace.
```

Điều này bình thường, vì mới cài controller ArgoCD chứ chưa tạo app nào.

### Bước 8 - Xem Manifest Application Trong Lab

Trong repo W9 có 2 file Application:

```text
cloud/w9/lab/argocd/platform-app.yaml
cloud/w9/lab/argocd/rollout-app.yaml
```

Xem nội dung:

```powershell
Get-Content -LiteralPath cloud\w9\lab\argocd\platform-app.yaml
Get-Content -LiteralPath cloud\w9\lab\argocd\rollout-app.yaml
```

Hiện tại các file này đang có repo URL placeholder:

```text
https://github.com/CHANGE_ME/CHANGE_ME.git
```

Nếu apply ngay, ArgoCD vẫn tạo Application nhưng sync sẽ fail vì repo không tồn tại.

### Bước 9 - Sửa Repo URL Trước Khi Apply App

Khi có repo GitHub thật, sửa:

```yaml
repoURL: https://github.com/CHANGE_ME/CHANGE_ME.git
```

thành repo của bạn, ví dụ:

```yaml
repoURL: https://github.com/<username>/<repo>.git
```

Đường dẫn trong Application phải khớp thư mục trong repo:

```yaml
path: cloud/w9/lab/manifests
```

và:

```yaml
path: cloud/w9/lab/rollout
```

Nếu repo private, cần cấu hình credential cho ArgoCD trước.

### Bước 10 - Apply ArgoCD Application

Sau khi sửa repo URL đúng:

```powershell
kubectl apply -f cloud\w9\lab\argocd\platform-app.yaml
kubectl apply -f cloud\w9\lab\argocd\rollout-app.yaml
```

Kiểm tra:

```powershell
kubectl get applications -n argocd
```

Kết quả mong muốn:

```text
NAME               SYNC STATUS   HEALTH STATUS
w9-mini-platform   Synced        Healthy
w9-rollout         Synced        Healthy
```

Nếu `OutOfSync` hoặc `Degraded`, xem chi tiết:

```powershell
kubectl describe application w9-mini-platform -n argocd
kubectl describe application w9-rollout -n argocd
```

### Bước 11 - Kiểm Tra Resource Do ArgoCD Tạo

Kiểm tra namespace/platform:

```powershell
kubectl get all -n mini-platform
```

Kiểm tra events nếu có lỗi:

```powershell
kubectl get events -n mini-platform --sort-by=.lastTimestamp
```

Nếu dùng UI, vào `https://localhost:8080`, bạn sẽ thấy các app và trạng thái:

- `Synced`: cluster khớp Git.
- `Healthy`: resource chạy ổn.
- `OutOfSync`: cluster khác Git.
- `Degraded`: resource có lỗi.

### Bước 12 - Dọn Hoặc Dừng Port-Forward Khi Không Dùng

Nếu chạy port-forward trực tiếp trong terminal, nhấn `Ctrl + C`.

Nếu chạy nền bằng `Start-Process`, tìm process kubectl:

```powershell
Get-Process kubectl
```

Sau đó dừng process nếu cần:

```powershell
Stop-Process -Name kubectl
```

Chỉ dừng khi bạn không cần mở UI nữa.
