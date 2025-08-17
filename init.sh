#!/bin/bash

# Danh sách các service và đường dẫn đến values.yaml tương ứng
SERVICES=(
  "bookie-client:./frontend/bookie-client/values.yaml"
  "bookie-owner:./frontend/bookie-owner/values.yaml"
  "sms:./backend/sms/values.yaml"
  "storage:./backend/storage/values.yaml"
  "review:./backend/review/values.yaml"
  "booking:./backend/booking/values.yaml"
  "auth:./backend/auth/values.yaml"
  "messaging:./backend/messaging/values.yaml"
  "gate:./backend/gate/values.yaml"
)

# Đường dẫn đến Helm chart
CHART_PATH="./helm-chart"

# Namespace Kubernetes (có thể thay đổi hoặc bỏ đi nếu không cần)
NAMESPACE="default"

# Hàm kiểm tra trạng thái deployment
check_deployment_ready() {
  local service_name=$1
  echo "🔄 Đang chờ $service_name sẵn sàng..."

  while true; do
    READY=$(kubectl get deployment "$service_name" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    TOTAL=$(kubectl get deployment "$service_name" -n "$NAMESPACE" -o jsonpath='{.status.replicas}' 2>/dev/null)

    if [[ "$READY" == "$TOTAL" && -n "$READY" ]]; then
      echo "✅ $service_name đã sẵn sàng!"
      break
    else
      echo "⏳ $service_name chưa sẵn sàng, chờ thêm..."
      sleep 5
    fi
  done
}

# Triển khai từng service theo hàng đợi
for ENTRY in "${SERVICES[@]}"; do
  SERVICE_NAME="${ENTRY%%:*}"
  VALUES_PATH="${ENTRY##*:}"

  echo "🚀 Đang triển khai $SERVICE_NAME với $VALUES_PATH..."
  
  helm upgrade --install "$SERVICE_NAME" "$CHART_PATH" -n "$NAMESPACE" -f "$VALUES_PATH" --wait
  
  if [ $? -eq 0 ]; then
    check_deployment_ready "$SERVICE_NAME"
  else
    echo "❌ Lỗi khi deploy $SERVICE_NAME, dừng script!"
    exit 1
  fi
done

echo "🎉 Tất cả các service đã được triển khai thành công!"
