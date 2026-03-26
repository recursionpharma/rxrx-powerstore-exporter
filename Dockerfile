ARG ARCH="amd64"
ARG OS="linux"
ARG PORT=9010
FROM quay.io/prometheus/busybox-${OS}-${ARCH}:latest
LABEL maintainer="The Prometheus Authors <prometheus-developers@googlegroups.com>"

WORKDIR /powerstore_exporter

COPY build/powerstore-metrics-exporter .

COPY bulk .
COPY https .

RUN chmod +x ./powerstore-metrics-exporter

EXPOSE ${PORT}

ENTRYPOINT ["/powerstore_exporter/powerstore-metrics-exporter"]
CMD ["-c","/powerstore_exporter/config/config.yml"]