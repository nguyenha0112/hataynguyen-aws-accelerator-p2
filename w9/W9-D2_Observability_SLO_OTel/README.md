# W9-D2 - Observability: SLO/SLI/OTel

## Mục Tiêu

Bổ sung telemetry để biết platform W8 có đạt mục tiêu reliability từ góc nhìn người dùng hay không:

- Metrics với Prometheus.
- Dashboard với Grafana.
- Logs với Loki.
- Traces thông qua OpenTelemetry Collector.
- SLO và burn-rate alert cho availability và latency.

## Bản Nháp SLI/SLO

| User Journey | SLI | SLO |
|---|---|---|
| Web request availability | Tỷ lệ HTTP request không phải 5xx | 99.5% trong 30 ngày |
| Web request latency | Tỷ lệ request dưới 500 ms | 95% trong 30 ngày |

## Burn-Rate Alerts

| Window | Purpose | Example |
|---|---|---|
| Fast burn | Phát hiện sự cố nghiêm trọng nhanh | Burn rate 1h và 5m vượt ngưỡng |
| Slow burn | Phát hiện degradation kéo dài | Burn rate 6h và 30m vượt ngưỡng |

## Lệnh Chạy Local

```powershell
kubectl create namespace observability
kubectl apply -f otel/collector.yaml
kubectl apply -f alert-rules/slo-burn-rate.yaml
kubectl get pods -n observability
```

## Checklist Minh Chứng

- [ ] Screenshot Prometheus target.
- [ ] Screenshot Grafana dashboard.
- [ ] Ví dụ request trace hoặc log của OTel Collector.
- [ ] Screenshot alert rule hoặc output `kubectl get prometheusrule`.
