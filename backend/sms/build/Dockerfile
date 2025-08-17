FROM ghcr.io/android-sms-gateway/server:1.25.3

# Sao chép tệp cấu hình vào container
COPY ./config/config.yml /app/config.yml


WORKDIR /app

# Mở cổng 3000
EXPOSE 3000

# Lệnh mặc định để chạy khi container khởi động
ENTRYPOINT  ["/docker-entrypoint.sh"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -fs http://localhost:3000/health

CMD [ "/app/app" ]