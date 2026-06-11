# W9-D2 - Observability: SLO, SLI, OpenTelemetry

## Muc Tieu

Sau ngay nay ban can hieu cach quan sat platform Kubernetes bang tin hieu gan voi nguoi dung:

- Metrics voi Prometheus.
- Dashboard voi Grafana.
- Logs voi Loki hoac logging stack tuong duong.
- Traces qua OpenTelemetry Collector.
- SLI/SLO cho availability va latency.
- Burn-rate alert de canh bao khi error budget bi dot qua nhanh.

## Observability La Gi?

Observability la kha nang hieu duoc ben trong he thong dang xay ra gi dua tren tin hieu phat ra ben ngoai.

Khac voi viec chi hoi "pod co running khong", observability hoi:

- Nguoi dung co goi duoc request khong?
- Request nao dang loi?
- Loi tang sau deploy nao?
- Latency cham o service nao?
- Version moi co lam SLO xau di khong?

## Ba Tru Cot: Metrics, Logs, Traces

| Tin hieu | Dung de tra loi | Vi du |
|---|---|---|
| Metrics | He thong dang thay doi theo thoi gian nhu the nao? | request rate, error rate, p95 latency |
| Logs | Su kien cu the nao da xay ra? | request id X bi 500 do database timeout |
| Traces | Mot request di qua dau va mat bao lau? | gateway -> api -> db |

Nen dung ca ba:

- Metrics de phat hien van de.
- Logs de doc chi tiet su kien.
- Traces de thay duong di va nut that.

## Metrics

Metrics la du lieu dang so theo thoi gian. Prometheus thu thap metrics bang cach scrape endpoint HTTP, thuong la `/metrics`.

Bon loai metric hay gap:

| Loai | Y nghia | Vi du |
|---|---|---|
| Counter | Chi tang, khong giam | Tong so request |
| Gauge | Tang giam duoc | So pod dang ready |
| Histogram | Phan phoi gia tri | Thoi gian request |
| Summary | Thong ke quantile o client | p95 latency tinh tai app |

Voi HTTP service, metric quan trong:

- `http_requests_total`: tong request theo status code.
- `http_request_duration_seconds_bucket`: latency histogram.
- `container_cpu_usage_seconds_total`: CPU.
- `container_memory_working_set_bytes`: memory.

## Prometheus

Prometheus gom cac phan:

- Scraper: lay metrics tu targets.
- Time-series database: luu du lieu theo timestamp va labels.
- PromQL: ngon ngu query.
- Alerting rules: dinh nghia dieu kien canh bao.
- Alertmanager: gui alert ra Slack/email/PagerDuty neu co cau hinh.

Labels giup chia metric theo dimension:

```text
http_requests_total{job="web", status="500", namespace="mini-platform"}
```

Can than voi high cardinality. Khong nen gan label co qua nhieu gia tri nhu user id, request id, session id.

## Grafana

Grafana dung de ve dashboard tu Prometheus/Loki/Tempo. Dashboard tot nen tra loi nhanh:

- Service co dang up khong?
- Error rate hien tai la bao nhieu?
- p95/p99 latency co tang khong?
- Deploy moi co lien quan den loi khong?
- SLO con bao nhieu error budget?

Dashboard khong nen chi toan CPU/RAM. CPU/RAM huu ich, nhung SLO user-facing moi la trung tam.

## Logs

Logs nen co cau truc thay vi text tuy tien:

```json
{
  "level": "error",
  "service": "web",
  "request_id": "abc123",
  "status": 500,
  "message": "database timeout"
}
```

Log tot can co:

- Timestamp.
- Level: info, warn, error.
- Service name.
- Request/correlation id.
- Error message ngan gon.
- Context vua du, khong lo secret.

## Traces

Trace la ban do duong di cua mot request. Mot trace gom nhieu span.

Vi du:

```text
Trace request /checkout
  span: gateway 20 ms
  span: payment-api 120 ms
  span: database 400 ms
```

Trace giup thay service nao lam request cham. Trong microservices, traces rat quan trong vi mot request co the di qua nhieu service.

## OpenTelemetry

OpenTelemetry la bo chuan va tooling de thu thap telemetry:

- Metrics.
- Logs.
- Traces.

OpenTelemetry Collector co the nhan tin hieu tu app, xu ly, roi gui sang backend:

```text
App -> OTel Collector -> Prometheus/Grafana Tempo/Loki/Jaeger
```

Collector gom cac khoi:

| Thanh phan | Y nghia |
|---|---|
| Receivers | Nhan du lieu, vi du OTLP |
| Processors | Xu ly, batch, them metadata, filter |
| Exporters | Gui du lieu sang backend |
| Pipelines | Noi receiver -> processor -> exporter |

File trong repo:

```text
cloud/w9/W9-D2_Observability_SLO_OTel/otel/collector.yaml
```

## SLI

SLI la Service Level Indicator: chi so do muc do tot cua service.

SLI phai gan voi hanh vi nguoi dung. Vi du:

- Availability SLI: ti le request khong phai 5xx.
- Latency SLI: ti le request nhanh hon 500 ms.
- Freshness SLI: ti le data duoc cap nhat trong 5 phut.
- Correctness SLI: ti le response dung nghiep vu.

SLI nen do duoc bang metric.

## SLO

SLO la Service Level Objective: muc tieu cho SLI trong mot khoang thoi gian.

Vi du:

| User Journey | SLI | SLO |
|---|---|---|
| Web request availability | Ti le HTTP request khong phai 5xx | 99.5% trong 30 ngay |
| Web request latency | Ti le request duoi 500 ms | 95% trong 30 ngay |

SLO tot can:

- Gan voi trai nghiem nguoi dung.
- Co con so ro.
- Co time window ro.
- Co nguong vua thuc te, khong ao tuong 100%.

## Error Budget

Error budget la phan duoc phep loi.

Neu SLO availability la 99.5% trong 30 ngay:

```text
Error budget = 100% - 99.5% = 0.5%
```

Neu co 100,000 request/thang, service duoc phep co toi da 500 request loi ma van dat SLO.

Y nghia quan trong:

- Con nhieu error budget: team co the release nhanh hon.
- Gan het error budget: giam release, uu tien reliability.
- Dot qua nhanh: alert va rollback/canary abort.

## Burn Rate

Burn rate la toc do dot error budget.

Vi du:

- Burn rate = 1: dot dung toc do cho phep.
- Burn rate = 10: dang dot nhanh gap 10 lan, neu tiep tuc se het budget som.

Burn-rate alert tot hon alert "error rate > 5%" don gian vi no gan voi SLO va time window.

## Fast Burn Va Slow Burn

| Window | Muc dich | Vi du |
|---|---|---|
| Fast burn | Bat su co nghiem trong nhanh | 5m va 1h deu xau |
| Slow burn | Bat degradation keo dai | 30m va 6h deu xau |

Ket hop nhieu window giup giam alert nhieu va van bat duoc su co that.

## PromQL Mau

Availability SLI:

```promql
1 - (
  sum(rate(http_requests_total{status=~"5.."}[5m]))
  /
  sum(rate(http_requests_total[5m]))
)
```

Error rate:

```promql
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))
```

Latency duoi 500 ms voi histogram:

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

## Alert Rule

File trong repo:

```text
cloud/w9/W9-D2_Observability_SLO_OTel/alert-rules/slo-burn-rate.yaml
```

Khi dung Prometheus Operator, alert rule thuong la `PrometheusRule`. Neu local stack chua co Operator, ban can cai kube-prometheus-stack hoac doi rule thanh format Prometheus native tuy stack.

## Lenh Chay Local

```powershell
kubectl create namespace observability
kubectl apply -f otel/collector.yaml
kubectl apply -f alert-rules/slo-burn-rate.yaml
kubectl get pods -n observability
```

Kiem tra resource:

```powershell
kubectl get all -n observability
kubectl get prometheusrule -A
kubectl describe prometheusrule <rule-name> -n observability
```

Neu cluster chua co CRD `PrometheusRule`, ban se can cai monitoring stack truoc.

## Loi Hay Gap

| Loi | Nguyen nhan | Cach xu ly |
|---|---|---|
| `no matches for kind PrometheusRule` | Chua cai Prometheus Operator CRD | Cai kube-prometheus-stack hoac dung rule native |
| Prometheus khong thay target | ServiceMonitor/scrape config thieu | Kiem tra labels va namespace selector |
| Dashboard khong co data | Query sai metric name hoac app chua expose metric | Kiem tra `/metrics` va Prometheus targets |
| Trace khong hien | App chua instrument hoac Collector exporter sai | Kiem tra OTel pipeline va logs |
| Alert qua nhieu | Nguong qua nhay hoac window qua ngan | Dung multi-window burn-rate |

## Checklist Minh Chung

- [ ] Screenshot Prometheus target.
- [ ] Screenshot Grafana dashboard.
- [ ] Vi du request trace hoac log cua OTel Collector.
- [ ] Screenshot alert rule hoac output `kubectl get prometheusrule`.

## Cau Hoi Tu On

- Metrics, logs, traces khac nhau nhu the nao?
- Vi sao dashboard chi co CPU/RAM la chua du?
- SLI khac SLO nhu the nao?
- Error budget anh huong quyet dinh release ra sao?
- Burn-rate alert co loi gi hon alert theo error rate tuc thoi?
- OpenTelemetry Collector gom nhung thanh phan nao?
- Vi sao can tranh label co cardinality cao?
