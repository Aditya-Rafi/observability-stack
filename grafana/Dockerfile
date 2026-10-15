# Image Grafana custom: provisioning (datasources) di-bake ke dalam image
# supaya container langsung punya koneksi ke Mimir/Loki/Tempo tanpa setup manual.
ARG GRAFANA_IMAGE=grafana/grafana:nightly-ubuntu-slim
FROM ${GRAFANA_IMAGE}

# Salin konfigurasi provisioning (datasources, dashboards, dll).
COPY provisioning/ /etc/grafana/provisioning/
