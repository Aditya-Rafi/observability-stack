# Shortcut perintah stack observability. Semua dijalankan dari root project.
.DEFAULT_GOAL := help

.PHONY: help up down restart logs ps build config pull clean

help: ## Tampilkan daftar perintah
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

up: ## Build (jika perlu) lalu jalankan semua service di background
	docker compose up -d --build

down: ## Hentikan & hapus semua container + network
	docker compose down

restart: down up ## Restart seluruh stack

logs: ## Ikuti log semua service (Ctrl-C untuk keluar)
	docker compose logs -f

ps: ## Status semua service
	docker compose ps

build: ## Build ulang image custom (Grafana)
	docker compose build

config: ## Validasi & tampilkan konfigurasi compose hasil gabungan
	docker compose config

pull: ## Tarik versi terbaru semua image
	docker compose pull

clean: ## Hentikan stack DAN hapus volume (DATA HILANG!)
	docker compose down -v
