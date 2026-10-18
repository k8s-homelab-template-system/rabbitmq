# rabbitmq

Helm chart chạy RabbitMQ trên Kubernetes. Chart này không tự viết template mà dùng lại chart [`bitnami/rabbitmq`](https://artifacthub.io/packages/helm/bitnami/rabbitmq) (16.0.14, lấy từ `oci://registry-1.docker.io/bitnamicharts`) làm dependency.

Cấu hình mặc định (xem [values.yaml](values.yaml)):

- RabbitMQ 4.1.3, 1 node, ổ 2Gi dùng StorageClass mặc định
- User `app`, mật khẩu và Erlang cookie tự sinh
- Bật plugin `rabbitmq_management` (UI + HTTP API ở port 15672), Ingress cho UI tắt sẵn
- Không bật metrics

> **Lưu ý về image:** Bitnami đã gỡ các image `docker.io/bitnami/rabbitmq`, nên chart này dùng `bitnamilegacy/rabbitmq:4.1.3-debian-12-r1` (bật `global.security.allowInsecureImages`). Image legacy không còn được cập nhật bảo mật.

## Cài đặt

```bash
helm dependency build .
helm upgrade --install rabbitmq . --namespace homelab --create-namespace
```

Thường thì chart này được cài qua umbrella chart `scs` chứ không cài riêng.

## Kết nối

Với release tên `<release>`, chart tạo:

| Resource | Tên |
| --- | --- |
| Service | `<release>-rabbitmq` (AMQP 5672, management UI 15672) |
| Secret | `<release>-rabbitmq` (key `rabbitmq-password` cho user `app`, `rabbitmq-erlang-cookie`) |

Lấy mật khẩu:

```bash
kubectl get secret <release>-rabbitmq -n homelab -o jsonpath='{.data.rabbitmq-password}' | base64 -d
```

Mở management UI:

```bash
kubectl port-forward svc/<release>-rabbitmq -n homelab 15672:15672
```

Rồi vào http://localhost:15672, đăng nhập bằng user `app`.

Hoặc bật Ingress (trỏ tới port 15672):

```yaml
rabbitmq:
  ingress:
    enabled: true
    hostname: rabbitmq.homelab.local
```

Mật khẩu được sinh ngẫu nhiên khi cài lần đầu. Để tránh bị đổi khi upgrade, hãy tạo Secret trước rồi trỏ tới nó bằng `rabbitmq.auth.existingPasswordSecret` và `rabbitmq.auth.existingErlangSecret`.
