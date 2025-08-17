FROM envoyproxy/envoy:v1.24-latest

WORKDIR /etc/envoy

COPY ./envoy.yaml .

EXPOSE 8081

CMD ["envoy", "-c", "/etc/envoy/envoy.yaml"]


