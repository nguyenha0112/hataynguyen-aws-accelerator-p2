# W10 Study Notes - Tổng Hợp Chi Tiết 3 Ngày

## Mục Tiêu Tuần 10

Tuần 10 tập trung vào việc biến mini platform từ trạng thái "deploy được" sang "deploy có kiểm soát, có bảo vệ, có quy trình vận hành".

Sau 3 ngày, bạn cần nắm được:

- Cách phân quyền Kubernetes bằng RBAC.
- Cách chặn manifest nguy hiểm bằng admission policy.
- Cách quản lý secret không đưa giá trị thật vào Git.
- Cách scan image, ký image và verify image trước khi deploy.
- Cách giới hạn tài nguyên namespace bằng `ResourceQuota` và `LimitRange`.
- Cách viết runbook và làm chaos test nhỏ để luyện xử lý sự cố.

Luồng platform an toàn:

```text
Developer commit code
  -> CI build image
  -> Trivy scan image
  -> Cosign sign image
  -> GitOps update manifest
  -> ArgoCD sync vào cluster
  -> RBAC kiểm tra quyền
  -> Admission policy kiểm tra manifest
  -> ESO sync secret từ external store
  -> ResourceQuota/LimitRange giới hạn tài nguyên
  -> Observability + runbook hỗ trợ vận hành
```

## Bản Đồ Kiến Thức

| Ngày | Chủ đề | Cần hiểu |
|---|---|---|
| Day 1 | RBAC và Admission Policy | Ai được làm gì, manifest nào bị chặn |
| Day 2 | Secrets và Supply Chain Security | Secret đến từ đâu, image có đáng tin không |
| Day 3 | Platform Integration | Namespace có giới hạn, có runbook, có test phục hồi |

## Day 1 - RBAC Và Admission Policy

### 1. Trọng Tâm Theo Slide Buổi Sáng

Slide buổi sáng tập trung vào `Secure & Operate: RBAC + Admission Policy`.

Thông điệp chính:

```text
W8 có cluster.
W9 có GitOps, observability, canary.
W10 cần cluster-level enforcement: chặn lỗi ngay tại cluster, không dựa vào "dev nhớ làm đúng".
```

Vấn đề nếu cluster không có guardrail:

| Rủi ro | Ví dụ | Hậu quả |
|---|---|---|
| Xóa nhầm production | User có quyền quá rộng chạy `kubectl delete` sai namespace | Service downtime |
| Image không rõ nguồn gốc | Pull image từ registry lạ hoặc tag không pin version | CVE, khó audit |
| Pod ăn hết tài nguyên node | Không khai báo `resources.limits` | Pod khác bị evict |
| Mọi thứ nằm trong `default` namespace | 20 app dùng chung namespace | Lateral movement dễ hơn, khó phân quyền |

Gốc của vấn đề:

```text
Kubernetes mặc định không tự chặn hết lỗi vận hành/security.
Muốn chặn phải thêm 2 lớp kiểm soát:
  1. RBAC: ai được làm gì?
  2. Admission Policy: manifest có hợp lệ không?
```

Mục tiêu của phần slide:

- Tạo 3 vai trò rõ ràng: `developer`, `sre`, `viewer`.
- Dùng `kubectl auth can-i ... --as <user>` để nghiệm thu RBAC.
- Cài OPA Gatekeeper qua GitOps.
- Enforce 4 constraint quan trọng.
- Viết thêm 1 custom policy bằng `ConstraintTemplate` + `Constraint`.
- Mọi thay đổi đi qua Git/ArgoCD, không apply tay nếu đang làm theo lab GitOps.

### 2. RBAC Là Gì?

RBAC là Role-Based Access Control. Trong Kubernetes, RBAC trả lời câu hỏi:

```text
Subject nào được thực hiện verb nào trên resource nào trong scope nào?
```

Ví dụ:

```text
ServiceAccount developer được create deployments trong namespace mini-platform.
ServiceAccount developer không được delete secrets.
ServiceAccount viewer chỉ được get/list/watch.
```

### 3. Các Thành Phần Chính Của RBAC

| Thành phần | Ý nghĩa | Ví dụ |
|---|---|---|
| Subject | Ai đang thao tác | User, Group, ServiceAccount |
| Verb | Hành động | get, list, watch, create, update, delete |
| Resource | Đối tượng Kubernetes | pods, deployments, services, secrets |
| Scope | Phạm vi quyền | namespace hoặc cluster |

### 4. Role Và ClusterRole

| Loại | Scope | Khi dùng |
|---|---|---|
| `Role` | Trong một namespace | Developer thao tác trong namespace của team |
| `ClusterRole` | Toàn cluster hoặc resource cluster-scoped | SRE đọc node, viewer đọc nhiều namespace |

Điểm cần nhớ:

- `Role` không có tác dụng ngoài namespace của nó.
- `ClusterRole` có thể được bind trong một namespace bằng `RoleBinding`.
- `ClusterRoleBinding` cấp quyền trên toàn cluster, nên cần hạn chế dùng.

### 5. RoleBinding Và ClusterRoleBinding

| Loại | Ý nghĩa | Rủi ro |
|---|---|---|
| `RoleBinding` | Gán `Role` hoặc `ClusterRole` trong một namespace | Rủi ro được giới hạn trong namespace |
| `ClusterRoleBinding` | Gán `ClusterRole` toàn cluster | Rủi ro lớn nếu cấp quyền rộng |

Ví dụ tư duy:

```text
developer -> RoleBinding -> Role trong mini-platform
viewer -> RoleBinding -> ClusterRole view trong mini-platform
sre -> ClusterRoleBinding nếu thật sự cần thao tác cluster-wide
```

### 6. Model Role Nên Có

| Role | Quyền nên có | Không nên có |
|---|---|---|
| viewer | get/list/watch | create/update/delete |
| developer | deploy app, update deployment/service/configmap | sửa RBAC, đọc secret nhạy cảm, xóa namespace |
| sre | debug rộng hơn, xem events/logs, vận hành platform | admin vĩnh viễn không audit |

Nguyên tắc:

- Cấp quyền tối thiểu cần thiết.
- Không dùng `cluster-admin` cho công việc hằng ngày.
- Dùng `kubectl auth can-i` để kiểm tra trước khi giao quyền.

Theo slide lab buổi sáng, model user cụ thể là:

| User | Vai trò | Quyền kỳ vọng |
|---|---|---|
| `alice` | developer | CRUD workload như deploy/pod/service chỉ trong namespace `demo` |
| `bob` | sre | Xem và thao tác pod toàn cụm |
| `carol` | viewer | Chỉ đọc toàn cụm: get/list/watch |

Gợi ý thiết kế:

- `alice` chỉ bị bó trong 1 namespace nên dùng `Role` + `RoleBinding`.
- `bob` và `carol` cần phạm vi toàn cụm nên dùng `ClusterRole`.
- `viewer` chỉ có `get/list/watch`, không có `create/update/delete`.
- Nếu bind cho người dùng thật trong lab, dùng `subjects.kind: User`.

### 7. Lệnh Kiểm Tra RBAC

```powershell
kubectl auth can-i get pods -n mini-platform --as=system:serviceaccount:mini-platform:developer
kubectl auth can-i create deployments -n mini-platform --as=system:serviceaccount:mini-platform:developer
kubectl auth can-i delete secrets -n mini-platform --as=system:serviceaccount:mini-platform:developer
kubectl auth can-i get pods -A --as=system:serviceaccount:mini-platform:viewer
```

Lệnh nghiệm thu theo slide:

```powershell
kubectl auth can-i create deploy -n demo --as alice
kubectl auth can-i create deploy -n kube-system --as alice
kubectl auth can-i get pods -A --as bob
kubectl auth can-i delete nodes --as carol
```

Kết quả kỳ vọng:

| Lệnh test | Kỳ vọng | Ý nghĩa |
|---|---|---|
| `can-i create deploy -n demo --as alice` | `yes` | Developer được deploy trong namespace của mình |
| `can-i create deploy -n kube-system --as alice` | `no` | Developer không được đụng namespace hệ thống |
| `can-i get pods -A --as bob` | `yes` | SRE xem được pod toàn cụm |
| `can-i delete nodes --as carol` | `no` | Viewer không được thao tác phá hủy |

Cách đọc kết quả:

- `yes`: subject có quyền.
- `no`: subject không có quyền.
- Nếu kết quả không đúng mong đợi, kiểm tra lại `Role`, `RoleBinding`, namespace và tên service account.
- `--as` là impersonation: admin giả lập user để kiểm tra authorization, chưa cần authentication thật.

### 8. Admission Policy Là Gì?

Admission policy kiểm tra nội dung object trước khi object được lưu vào cluster.

Luồng Kubernetes API:

```text
kubectl apply
  -> Authentication: bạn là ai?
  -> Authorization/RBAC: bạn có quyền làm việc này không?
  -> Admission: object này có hợp lệ không?
  -> Persist vào etcd
```

RBAC và Admission khác nhau:

| RBAC | Admission |
|---|---|
| Kiểm tra ai được làm gì | Kiểm tra object có đạt chuẩn không |
| Dựa trên subject, verb, resource | Dựa trên nội dung manifest |
| Ví dụ: developer được create deployment | Ví dụ: deployment không được privileged |

### 9. OPA Gatekeeper

Gatekeeper là admission controller dùng OPA/Rego để validate Kubernetes object.

Hai khái niệm chính:

| Thành phần | Ý nghĩa |
|---|---|
| `ConstraintTemplate` | Định nghĩa logic policy |
| `Constraint` | Áp policy vào resource/namespace cụ thể |

Ví dụ policy nên có:

- Bắt buộc label `app`, `owner`, `env`.
- Chặn pod chạy `privileged`.
- Chặn image tag `latest`.
- Bắt buộc resource request/limit.

Trong slide, 4 luật cần enforce là:

| # | Luật cần chặn | Rủi ro giảm được |
|---|---|---|
| 1 | Cấm image tag `:latest` | Không biết version thật đang chạy, khó rollback/audit |
| 2 | Bắt buộc có `resources.limits` | Pod có thể ăn hết tài nguyên node |
| 3 | Cấm `runAsUser: 0` | Container chạy root, tăng blast radius khi bị khai thác |
| 4 | Cấm `hostNetwork: true` | Pod dùng network namespace của node, rủi ro bảo mật cao |

Nghiệm thu Gatekeeper theo slide:

| Thử deploy | Kỳ vọng |
|---|---|
| Pod image `:latest` | reject |
| Pod thiếu `resources.limits` | reject |
| Pod `runAsUser: 0` | reject |
| Pod `hostNetwork: true` | reject |
| Pod hợp lệ: image pin version, có limits, non-root | pass |

Điểm quan trọng:

- Controller Gatekeeper phải được cài trước.
- `ConstraintTemplate` phải có trước `Constraint`.
- Nếu làm GitOps, nên dùng sync-wave hoặc tách app để đảm bảo thứ tự: controller -> template -> constraint.
- Trước khi bật `deny`, nên chạy `warn`/audit để tránh tự chặn chính platform của mình.

### 10. ConstraintTemplate Và Constraint

`ConstraintTemplate` là nơi viết logic policy, thường bằng Rego.

Nó định nghĩa:

- Kind CRD mới mà Gatekeeper sinh ra.
- Schema parameter nhận vào.
- Logic vi phạm.

Ví dụ tư duy:

```text
ConstraintTemplate K8sRequiredLabels:
  - Nhận parameter labels.
  - Đọc labels hiện có trên object.
  - So sánh required labels với provided labels.
  - Nếu thiếu label thì tạo violation.
```

`Constraint` là instance của template.

Nó quyết định:

- Áp policy vào kind nào.
- Áp vào namespace nào.
- Dùng parameter nào.
- Chạy ở `deny`, `warn` hay audit.

Ví dụ:

```text
Template: K8sRequiredLabels
Constraint: require-owner-label
Parameter: labels = ["owner"]
Match: apps/Deployment
Action: deny
```

Flow đầy đủ:

```text
ConstraintTemplate viết logic
  -> Gatekeeper sinh CRD mới
  -> Constraint dùng CRD đó và truyền parameter
  -> Admission webhook reject manifest vi phạm
```

### 11. Custom Policy Theo Slide

Slide yêu cầu tự viết thêm 1 custom `ConstraintTemplate` thay vì chỉ dùng thư viện có sẵn.

Chọn 1 trong các đề:

| Custom policy | Ý nghĩa |
|---|---|
| Reject Deployment nếu `replicas > 5` | Chặn scale quá mức trong namespace học/lab |
| Bắt buộc workload có label `owner` | Truy vết trách nhiệm, cost, incident |
| Chỉ cho image từ registry của bạn | Chặn image không rõ nguồn gốc |

Yêu cầu nghiệm thu:

- Có `ConstraintTemplate` tự viết.
- Có `Constraint` áp dụng template đó.
- Manifest vi phạm bị reject.
- Manifest hợp lệ pass.
- Commit vào Git và để ArgoCD sync nếu đang làm theo GitOps lab.

### 12. GitOps Flow Cho RBAC + Gatekeeper

Theo slide, lab không khuyến khích `kubectl apply` tay cho phần platform chính. Mọi thứ nên đi qua Git.

Flow:

```text
Sửa YAML trong repo
  -> commit
  -> push
  -> ArgoCD sync
  -> cluster nhận RBAC/Gatekeeper policy
  -> chạy lệnh nghiệm thu
```

Gợi ý cấu trúc từ slide:

```text
rbac/
  roles.yaml
  rolebindings.yaml

gatekeeper/
  constraints/

argocd/apps/
  rbac.yaml
  gatekeeper.yaml
```

Deliverable:

- `rbac/`: 3 role hoặc clusterrole + 3 binding.
- `gatekeeper/constraints/`: 4 constraint bắt buộc + 1 custom policy.
- `argocd/apps/*.yaml`: ArgoCD app quản lý RBAC và Gatekeeper.
- Evidence: kết quả `auth can-i`, kết quả reject/pass của policy, trạng thái ArgoCD `Synced/Healthy`.

### 13. Audit Mode Và Enforce Mode

| Mode | Ý nghĩa | Khi dùng |
|---|---|---|
| audit/dryrun | Ghi nhận vi phạm nhưng chưa chặn | Khi policy mới rollout |
| enforce/deny | Reject request vi phạm | Khi policy đã ổn định |

Pattern an toàn:

1. Viết policy.
2. Chạy ở audit/dryrun.
3. Xem workload nào vi phạm.
4. Sửa manifest hoặc tạo exception có lý do.
5. Chuyển sang enforce/deny.

### 14. Lỗi Hay Gặp Day 1

| Lỗi | Nguyên nhân | Cách xử lý |
|---|---|---|
| `forbidden` khi apply | Thiếu RBAC | Chạy `kubectl auth can-i` |
| Policy không chặn | Gatekeeper chưa ready hoặc constraint sai scope | Kiểm tra pod/log Gatekeeper |
| Resource cũ vẫn tồn tại | Admission chỉ chặn create/update mới | Sửa hoặc recreate resource |
| Policy quá chặt | Chưa chạy audit trước | Thu hẹp scope, thêm exception có expiry |
| Constraint apply lỗi `no matches for kind` | ConstraintTemplate/CRD chưa tồn tại | Apply controller/template trước constraint |
| Platform tự bị policy chặn | Workload platform cũng vi phạm 4 luật | Pin image, thêm limits, chạy non-root trước khi enforce |

## Day 2 - Secrets Và Supply Chain Security

### 1. Vấn Đề Với Kubernetes Secret Thường

Kubernetes Secret không nên được commit plaintext vào Git.

Rủi ro thường gặp:

- Secret bị lộ trong repository.
- Secret bị copy qua nhiều môi trường.
- Không biết ai đã xem hoặc sửa secret.
- Secret rotate rồi nhưng app vẫn dùng giá trị cũ.
- Người không cần biết secret vẫn có thể đọc secret nếu RBAC quá rộng.

### 2. External Secrets Operator

ESO giúp sync secret từ external secret store vào Kubernetes.

Luồng:

```text
AWS Secrets Manager
  -> External Secrets Operator
  -> Kubernetes Secret
  -> Pod
```

Git chỉ chứa manifest tham chiếu:

```text
remote secret name
property/key cần lấy
tên Kubernetes Secret cần tạo
refreshInterval
```

Git không chứa giá trị secret thật.

### 3. SecretStore, ClusterSecretStore, ExternalSecret

| Thành phần | Ý nghĩa |
|---|---|
| `SecretStore` | Cấu hình provider trong một namespace |
| `ClusterSecretStore` | Cấu hình provider dùng chung toàn cluster |
| `ExternalSecret` | Mapping secret từ provider sang Kubernetes Secret |
| `refreshInterval` | Tần suất ESO kiểm tra và sync giá trị mới |

Khi nào dùng:

- Dùng `SecretStore` nếu mỗi namespace/team có provider hoặc permission riêng.
- Dùng `ClusterSecretStore` nếu platform team quản lý provider chung.
- Dùng `ExternalSecret` trong namespace app để tạo secret mà app sẽ dùng.

### 4. Secret Rotation

Rotation là thay giá trị secret theo chu kỳ hoặc khi có sự cố.

Mục tiêu:

```text
Secret rotate ở AWS Secrets Manager
  -> ESO phát hiện thay đổi
  -> Kubernetes Secret được update
  -> workload dùng giá trị mới
```

Điểm quan trọng:

- Nếu app đọc secret qua env var, pod thường cần restart để nhận giá trị mới.
- Nếu app đọc secret qua mounted volume, file có thể được cập nhật sau một khoảng trễ.
- Một số app cần reload config riêng.

Debug secret:

```powershell
kubectl get externalsecret -n mini-platform
kubectl describe externalsecret app-config -n mini-platform
kubectl get secret app-config -n mini-platform
kubectl logs -n external-secrets deploy/external-secrets
```

### 5. Trivy Image Scan

Trivy scan image để phát hiện:

- OS package CVE.
- Application dependency CVE.
- Misconfiguration.
- Secret trong image hoặc filesystem nếu cấu hình.

Trong CI nên fail khi:

- Có `CRITICAL` vulnerability.
- Có `HIGH` vulnerability nhưng không có exception được approve.

Ví dụ lệnh:

```powershell
trivy image --severity HIGH,CRITICAL --exit-code 1 nginx:1.27
```

### 6. Cosign Image Signing

Cosign dùng để ký container image.

Mục tiêu:

- Chứng minh image được build từ pipeline tin cậy.
- Chứng minh image không bị thay đổi sau khi ký.
- Cho phép cluster verify image trước khi chạy.

Hai kiểu ký phổ biến:

| Kiểu | Ý nghĩa | Khi dùng |
|---|---|---|
| Keyless OIDC | CI identity ký image, không cần quản lý private key dài hạn | GitHub Actions/GitLab CI |
| Key-based | Dùng private/public key rõ ràng | Môi trường cần key custody riêng |

Ví dụ:

```powershell
cosign sign --key cosign.key ghcr.io/org/app:v1
cosign verify --key cosign.pub ghcr.io/org/app:v1
```

### 7. Verify Image Ở Admission Layer

Scan và sign trong CI chưa đủ, vì vẫn có thể có người apply image khác vào cluster.

Admission verify giúp:

- Reject image chưa ký.
- Reject image ký bởi identity không tin cậy.
- Chỉ cho phép registry hoặc org cụ thể.
- Bảo vệ production ngay tại cluster.

Ví dụ policy dùng Kyverno `verifyImages`.

### 8. Exception Security

Exception là ngoại lệ tạm thời, không phải bỏ qua vĩnh viễn.

Exception tốt cần có:

- CVE hoặc control được exception.
- Owner chịu trách nhiệm.
- Lý do business/technical.
- Expiry date.
- Mitigation tạm thời.
- Kế hoạch xử lý dứt điểm.

Không nên có:

- Exception không thời hạn.
- Exception không owner.
- Exception ghi chung chung "accepted risk".

### 9. Lỗi Hay Gặp Day 2

| Lỗi | Nguyên nhân | Cách xử lý |
|---|---|---|
| ESO không sync | Sai provider/permission/remote key | `kubectl describe externalsecret` |
| Secret update nhưng app chưa nhận | App đọc env var | Restart pod hoặc thêm reload |
| Trivy fail nhiều CVE | Base image cũ | Update image hoặc tạo exception có expiry |
| Cosign verify fail | Sai key, sai identity, sai image digest | Verify đúng digest và trust policy |
| Admission reject image đúng | Policy quá chặt hoặc image chưa ký | Ký image, sửa policy scope |

## Day 3 - Platform Integration, Cost Guard Và Runbook

### 1. Vì Sao Cần Day 3?

Day 1 và Day 2 tạo guardrail về quyền, policy, secret và image. Nhưng platform vẫn cần guardrail vận hành:

- Một namespace không được dùng hết tài nguyên cluster.
- Workload phải có request/limit hợp lý.
- Khi có lỗi, team cần runbook để xử lý nhanh.
- Cần chaos test nhỏ để biết hệ thống phục hồi ra sao.

### 2. ResourceQuota

`ResourceQuota` giới hạn tổng tài nguyên trong một namespace.

Nó có thể giới hạn:

- Tổng CPU request.
- Tổng memory request.
- Tổng CPU limit.
- Tổng memory limit.
- Số lượng pod.
- Số lượng service.
- Số lượng configmap.
- Số lượng secret.
- Storage/PVC nếu có.

Ví dụ ý nghĩa:

```text
Namespace mini-platform chỉ được request tối đa 2 CPU và 2Gi memory.
Nếu workload mới làm tổng request vượt giới hạn, Kubernetes sẽ reject hoặc không tạo thêm pod.
```

Lệnh kiểm tra:

```powershell
kubectl get resourcequota -n mini-platform
kubectl describe resourcequota mini-platform-quota -n mini-platform
```

### 3. LimitRange

`LimitRange` đặt default/min/max resource cho container hoặc pod trong namespace.

Nó giúp:

- Container không khai báo request/limit vẫn có default.
- Container xin quá nhiều tài nguyên sẽ bị chặn.
- Tránh workload best-effort quá nhiều.
- Giúp scheduler dự đoán tài nguyên tốt hơn.

Ví dụ:

```text
Nếu container không khai báo request CPU, namespace tự gán defaultRequest 100m.
Nếu container xin memory lớn hơn max, Kubernetes reject manifest.
```

Lệnh kiểm tra:

```powershell
kubectl get limitrange -n mini-platform
kubectl describe limitrange mini-platform-limits -n mini-platform
```

### 4. ResourceQuota Và LimitRange Khác Nhau Thế Nào?

| ResourceQuota | LimitRange |
|---|---|
| Giới hạn tổng tài nguyên namespace | Giới hạn/default cho từng container/pod |
| Chống một namespace chiếm hết cluster | Chống workload khai báo tài nguyên xấu |
| Phù hợp theo team/env | Phù hợp làm policy mặc định trong namespace |
| Ví dụ: namespace tối đa 20 pod | Ví dụ: container tối đa 2 CPU |

Hai cái nên dùng cùng nhau:

```text
LimitRange đảm bảo từng pod khai báo hợp lý.
ResourceQuota đảm bảo tổng namespace không vượt mức.
```

### 5. Cost Guard

Cost guard không chỉ để tiết kiệm tiền. Nó giúp platform ổn định hơn.

Rủi ro nếu không có cost guard:

- Workload request quá cao làm cluster scale không cần thiết.
- Workload limit quá thấp bị `OOMKilled`.
- Một namespace chiếm hết tài nguyên của namespace khác.
- Không có label owner/cost-center nên khó truy vết chi phí.

Nên kết hợp:

- Required labels: `app`, `owner`, `env`, `cost-center`.
- `ResourceQuota` theo namespace/team.
- `LimitRange` default request/limit.
- Dashboard theo namespace, deployment, owner.

### 6. Runbook

Runbook là tài liệu thao tác khi có sự cố.

Runbook tốt nên viết theo triệu chứng, không chỉ theo tên tool.

Ví dụ triệu chứng:

- Pod pending.
- Pod crash loop.
- Rollout fail.
- Secret không sync.
- Admission policy reject.
- Quota exceeded.

Runbook nên có:

- Triệu chứng.
- Ảnh hưởng.
- Lệnh kiểm tra nhanh.
- Nguyên nhân khả năng cao.
- Cách xử lý tạm thời.
- Cách xử lý bền vững.
- Khi nào cần escalate.
- Evidence cần lưu.

### 7. Chaos Test Nhỏ

Chaos test là tạo lỗi có kiểm soát để học cách phục hồi.

Không phải phá hệ thống bừa bãi. Mục tiêu là:

- Kiểm tra controller có tự phục hồi không.
- Kiểm tra policy có chặn đúng không.
- Kiểm tra runbook có đủ rõ không.
- Kiểm tra team có biết rollback/debug không.

Scenario nên tập:

| Test | Mục tiêu |
|---|---|
| Xóa pod | Deployment/Rollout có tạo pod mới không |
| Workload vượt quota | Namespace có bị chặn trước khi ảnh hưởng cluster không |
| Manifest thiếu label | Admission policy có reject đúng không |
| Image tag sai | Rollout có fail rõ ràng không |
| ExternalSecret lỗi | Team có đọc được status và event không |

### 8. Lỗi Hay Gặp Day 3

| Lỗi | Nguyên nhân | Cách xử lý |
|---|---|---|
| Pod bị reject vì quota | Request/limit vượt quota namespace | Giảm resource hoặc tăng quota có approve |
| Pod pending | Không đủ node resource hoặc quota hết | `kubectl describe pod`, xem events |
| Pod OOMKilled | Memory limit quá thấp | Tăng limit hoặc sửa memory leak |
| Policy reject workload đúng | Thiếu label/metadata | Sửa manifest |
| Secret không update | ESO/provider/IAM lỗi | `kubectl describe externalsecret` |

## Debug Cheatsheet

### RBAC

```powershell
kubectl auth can-i create deployments -n mini-platform --as=system:serviceaccount:mini-platform:developer
kubectl auth can-i delete secrets -n mini-platform --as=system:serviceaccount:mini-platform:developer
kubectl auth can-i get pods -A --as=system:serviceaccount:mini-platform:viewer
```

### Admission Policy

```powershell
kubectl get constraints
kubectl get constrainttemplates
kubectl get events -n mini-platform --sort-by=.lastTimestamp
```

### Secrets

```powershell
kubectl get externalsecret -n mini-platform
kubectl describe externalsecret app-config -n mini-platform
kubectl get secret app-config -n mini-platform
kubectl logs -n external-secrets deploy/external-secrets
```

### Image Scan Và Signing

```powershell
trivy image --severity HIGH,CRITICAL --exit-code 1 <image>
cosign verify --key cosign.pub <image>
```

### Quota Và Limit

```powershell
kubectl get resourcequota,limitrange -n mini-platform
kubectl describe resourcequota mini-platform-quota -n mini-platform
kubectl describe limitrange mini-platform-limits -n mini-platform
```

### Rollout

```powershell
kubectl get rollout -n mini-platform
kubectl get analysisrun -n mini-platform
kubectl get pods -n mini-platform
kubectl get events -n mini-platform --sort-by=.lastTimestamp
```

## Checklist Ôn Tập

### Day 1

- [ ] Giải thích được RBAC là gì.
- [ ] Phân biệt được `Role` và `ClusterRole`.
- [ ] Phân biệt được `RoleBinding` và `ClusterRoleBinding`.
- [ ] Biết dùng `kubectl auth can-i`.
- [ ] Nghiệm thu được `alice`, `bob`, `carol` bằng `kubectl auth can-i ... --as`.
- [ ] Giải thích được admission policy nằm ở đâu trong Kubernetes API flow.
- [ ] Phân biệt được `ConstraintTemplate` và `Constraint`.
- [ ] Nêu được 4 constraint trọng tâm: cấm `:latest`, bắt buộc `resources.limits`, cấm `runAsUser: 0`, cấm `hostNetwork: true`.
- [ ] Giải thích được vì sao phải apply Gatekeeper theo thứ tự controller -> template -> constraint.
- [ ] Tự chọn được 1 custom policy và mô tả cách test reject/pass.
- [ ] Biết vì sao nên audit trước khi enforce.

### Day 2

- [ ] Giải thích được vì sao không commit secret vào Git.
- [ ] Vẽ được flow AWS Secrets Manager -> ESO -> Kubernetes Secret -> Pod.
- [ ] Phân biệt được `SecretStore`, `ClusterSecretStore`, `ExternalSecret`.
- [ ] Giải thích được `refreshInterval`.
- [ ] Biết khi nào app cần restart để nhận secret mới.
- [ ] Giải thích được Trivy scan rủi ro gì.
- [ ] Giải thích được Cosign sign image để làm gì.
- [ ] Biết exception security cần owner, reason, expiry, mitigation.

### Day 3

- [ ] Giải thích được `ResourceQuota`.
- [ ] Giải thích được `LimitRange`.
- [ ] Phân biệt được quota tổng namespace và limit từng container.
- [ ] Biết vì sao request/limit liên quan đến cost.
- [ ] Biết runbook nên viết theo triệu chứng.
- [ ] Biết chaos test nhỏ nên có expected result và rollback plan.

## Câu Hỏi Ôn Tập Nhanh

1. RBAC trả lời câu hỏi gì?
2. Admission policy trả lời câu hỏi gì?
3. Vì sao không nên cấp `cluster-admin` cho developer?
4. Khi nào dùng `Role`, khi nào dùng `ClusterRole`?
5. `ConstraintTemplate` khác `Constraint` như thế nào?
6. Vì sao `alice` nên bị giới hạn trong namespace `demo`?
7. Vì sao `carol` không được `delete nodes`?
8. Bốn constraint trọng tâm trong slide là gì?
9. Vì sao cấm image tag `:latest`?
10. Vì sao bắt buộc `resources.limits`?
11. Vì sao cấm `runAsUser: 0`?
12. Vì sao `hostNetwork: true` là rủi ro?
13. Vì sao cần apply Gatekeeper theo thứ tự controller -> template -> constraint?
14. Vì sao nên chạy policy ở audit/warn mode trước?
15. Nếu ArgoCD sync fail vì policy reject, bạn debug từ đâu?
16. Vì sao Kubernetes Secret không nên commit vào Git?
17. ESO giúp ích gì trong secret rotation?
18. App đọc secret qua env var có tự nhận secret mới không?
19. Trivy và Cosign giải quyết hai rủi ro khác nhau nào?
20. Vì sao cần verify image ở admission layer dù CI đã scan/sign?
21. Exception security thiếu expiry có vấn đề gì?
22. `ResourceQuota` khác `LimitRange` như thế nào?
23. Nếu pod `Pending`, bạn kiểm tra những gì?
24. Nếu workload bị quota chặn, ai nên approve tăng quota?
25. Chaos test khác gì với phá hệ thống bừa bãi?
26. Một runbook tốt cần những phần nào?

## Ghi Nhớ Ngắn Gọn

- RBAC kiểm soát người thao tác.
- Admission policy kiểm soát manifest.
- Slide W10 sáng nhấn mạnh 2 câu hỏi: "ai được làm gì?" và "manifest có hợp lệ không?"
- 3 vai trò trọng tâm: `developer`, `sre`, `viewer`.
- 4 policy trọng tâm: cấm `:latest`, bắt buộc limits, cấm root, cấm hostNetwork.
- Gatekeeper cần đúng thứ tự: controller trước, template sau, constraint cuối.
- ESO giúp Git không chứa secret thật.
- Trivy tìm CVE trước khi release.
- Cosign chứng minh image đến từ nguồn tin cậy.
- Verify image ở admission layer bảo vệ cluster.
- `ResourceQuota` giới hạn tổng namespace.
- `LimitRange` đặt default/min/max cho container.
- Runbook giúp xử lý sự cố có quy trình.
- Chaos test giúp luyện phục hồi trước khi có sự cố thật.
