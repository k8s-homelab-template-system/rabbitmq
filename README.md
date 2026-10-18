# rabbitmq

Helm chart chạy RabbitMQ trên Kubernetes. Chart này không tự viết template mà dùng lại chart [`bitnami/rabbitmq`](https://artifacthub.io/packages/helm/bitnami/rabbitmq) (16.0.14, lấy từ `oci://registry-1.docker.io/bitnamicharts`) làm dependency.

Cấu hình mặc định (xem [values.yaml](values.yaml)):

- RabbitMQ 4.1.3, 1 node, ổ 2Gi dùng StorageClass mặc định
- User `app`, mật khẩu và Erlang cookie tự sinh, lưu trong Secret `<release>-rabbitmq-auth`
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
| Secret | `<release>-rabbitmq-auth` (key `rabbitmq-password` cho user `app`, `rabbitmq-erlang-cookie`) |

Lấy mật khẩu:

```bash
kubectl get secret <release>-rabbitmq-auth -n homelab -o jsonpath='{.data.rabbitmq-password}' | base64 -d
```

Mở management UI:

```bash
kubectl port-forward svc/<release>-rabbitmq -n homelab 15672:15672
```

Rồi vào http://localhost:15672, đăng nhập bằng user `app`.

Hoặc bật Ingress (trỏ tới port 15672). Host là `<ingress.subdomain>.<global.baseDomain>`, mặc định `rabbitmq-mgm.<global.baseDomain>`:

```yaml
global:
  baseDomain: vodka.bid
rabbitmq:
  ingress:
    enabled: true
    # subdomain: rabbitmq-mgm
```

Thiếu `global.baseDomain` khi bật Ingress thì `helm template` báo lỗi.

## Credential

Mật khẩu và Erlang cookie nằm trong Secret `<release>-rabbitmq-auth`, do chart này tạo ([templates/auth-secret.yaml](templates/auth-secret.yaml)). Không có credential nào trong git.

- Sinh ngẫu nhiên khi cài lần đầu, giữ nguyên khi upgrade (`lookup` Secret đang có).
- Có annotation `helm.sh/resource-policy: keep`: gỡ release vẫn giữ Secret, cài lại dùng đúng credential cũ.

Tự quản lý Secret (kubectl, Sealed Secrets, External Secrets...): đặt `authSecret.create: false` và tạo Secret tên `<release>-rabbitmq-auth` với 2 key trên, hoặc trỏ `rabbitmq.auth.existingPasswordSecret` / `existingErlangSecret` sang tên khác.
