# Observability Stack

Dashboard observability berbasis **Grafana** dengan tiga pilar data:

| Komponen | Peran | Port (default) |
| --- | --- | --- |
| **Grafana** | Visualisasi / dashboard | `3000` |
| **Mimir** | Metrics (Prometheus-compatible) | `9009` |
| **Loki** | Logs | `3100` |
| **Tempo** | Tracing (OTLP) | `3200`, `4317` (gRPC), `4318` (HTTP) |

## Konsep

Tiap komponen punya `docker-compose.yml` sendiri di subfoldernya
(`mimir/`, `loki/`, `tempo/`, `grafana/`). File root [`compose.yaml`](compose.yaml)
**tidak menggabungkan** isinya, melainkan memakai fitur `include:` Docker Compose v2.
Hasilnya: cukup **satu perintah** dari root untuk menjalankan semuanya — tanpa perlu
masuk ke tiap subfolder satu per satu.

```
observability/
├── compose.yaml          # orchestrator (include semua subfolder)
├── .env / .env.example   # versi image, port, kredensial
├── Makefile              # shortcut perintah
├── grafana/
│   ├── docker-compose.yml
│   ├── Dockerfile        # bake provisioning ke image Grafana
│   └── provisioning/datasources/datasources.yml
├── mimir/  (docker-compose.yml + mimir.yml)
├── loki/   (docker-compose.yml + loki.yml)
└── tempo/  (docker-compose.yml + tempo.yml)
```

## Cara pakai

```bash
# 1. Siapkan environment (sekali saja)
cp .env.example .env        # lalu ubah GF_SECURITY_ADMIN_PASSWORD

# 2. Jalankan SEMUA dengan satu perintah
docker compose up -d --build
#   atau:  make up

# 3. Buka Grafana
#    http://localhost:3000   (login sesuai .env)

# 4. Hentikan
docker compose down         # atau: make down
```

Datasource (Mimir, Loki, Tempo) sudah otomatis terpasang di Grafana lewat provisioning,
jadi tidak perlu dikonfigurasi manual.

## Menjalankan satu komponen saja (opsional)

```bash
docker compose -f mimir/docker-compose.yml up -d
```

## Perintah berguna

```bash
make help     # daftar semua shortcut
make logs     # ikuti log semua service
make ps       # status service
make config   # validasi konfigurasi gabungan
make clean    # hentikan + hapus volume (data hilang)
```
