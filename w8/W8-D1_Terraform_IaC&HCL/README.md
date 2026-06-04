# W8 Ngày 1 - Terraform Basics

Ngày: 01/06/2026

## Chủ đề

- Tổng quan về Infrastructure as Code (IaC).
- Cú pháp Terraform HCL.
- Workflow của Terraform: `init`, `fmt`, `validate`, `plan`, `apply`, `destroy`.
- Provider, resource, variable, output, và local value.

## Ghi chú quan trọng

Terraform mô tả trạng thái mong muốn của hạ tầng (infrastructure) bằng cách sử dụng cấu hình khai báo (declarative configuration).
Quy trình làm việc (workflow) thông thường:

1. Viết cấu hình (configuration).
2. Chạy lệnh `terraform init`.
3. Format và kiểm tra tính hợp lệ (validate).
4. Xem xét kế hoạch thực thi (execution plan).
5. Apply (áp dụng) chỉ sau khi đã kiểm tra kỹ plan.
6. Destroy (hủy) các tài nguyên test khi không còn cần thiết.

## Các lệnh thực hành

```powershell
cd w8/W8-D1_Terraform_IaC&HCL/terraform-basics
terraform init
terraform fmt
terraform validate
terraform plan
```

Ví dụ này sử dụng provider `local_file` để có thể test thử mà không cần tạo tài nguyên thật trên AWS.

## Danh sách minh chứng (Evidence Checklist)

- [ ] Ảnh chụp màn hình hoặc kết quả (output) của lệnh `terraform version`.
- [ ] Ảnh chụp màn hình hoặc kết quả của lệnh `terraform init`.
- [ ] Ảnh chụp màn hình hoặc kết quả của lệnh `terraform validate`.
- [ ] Một đoạn ghi chú ngắn giải thích về những gì plan sẽ tạo ra.
