{{/*
Credential đang lưu trong cluster (đã giải mã): đọc Secret hiện tại, nếu chưa có thì đọc
Secret cũ do chart bitnami tạo (<release>-rabbitmq). Trả về "" khi cài lần đầu.
Dùng chung cho templates/auth-secret.yaml và rabbitmq.auth.password trong values.yaml.
Params: secret, legacySecret, key, context
*/}}
{{- define "homelab.rabbitmq.storedCredential" -}}
{{- $ns := .context.Release.Namespace -}}
{{- $current := (lookup "v1" "Secret" $ns .secret).data | default dict -}}
{{- $legacy := (lookup "v1" "Secret" $ns .legacySecret).data | default dict -}}
{{- index $current .key | default (index $legacy .key) | default "" | b64dec -}}
{{- end -}}
