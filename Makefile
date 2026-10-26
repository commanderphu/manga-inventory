# Manga Inventory — Steuerung für Dev-Setup und Deploy
# `make` oder `make help` zeigt alle Ziele.

SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c
.DEFAULT_GOAL := help

API_IMAGE   := ghcr.io/commanderphu/manga-api
PROD_URL    := https://manga-api.phudevelopement.xyz

# Dev-Datenbank: manga_inventory im gemeinsamen central_postgres auf cisco.
# Der Containername löst nur im Docker-Netz core_network auf — die API läuft
# aber nativ, deshalb die LAN-IP, an die der Port gebunden ist.
# Zugangsdaten (DB_NAME/DB_USER/DB_PASSWORD) kommen aus api/.env.
DB_CONTAINER ?= central_postgres
DB_HOST      ?= 192.168.178.100
DB_PORT      ?= 5432
env_var       = $$(sed -n 's/^$(1)=//p' api/.env)
DB_EXEC       = docker exec -e PGPASSWORD="$(call env_var,DB_PASSWORD)"
DB_ARGS       = -h localhost -U "$(call env_var,DB_USER)" -d "$(call env_var,DB_NAME)"

# Lokale Ports: Frontend auf 3000 (Next-Standard), API auf 4000
API_PORT      ?= 4000
FRONTEND_PORT ?= 3000
DEV_API_KEY   ?= dev-api-key

# Überschreibt api/.env — dotenv lässt bereits gesetzte Variablen in Ruhe
API_DEV_ENV := \
	DB_HOST=$(DB_HOST) DB_PORT=$(DB_PORT) \
	PORT=$(API_PORT) NODE_ENV=development \
	API_KEY=$(DEV_API_KEY) JWT_SECRET=dev-jwt-secret \
	ALLOWED_ORIGINS=http://localhost:$(FRONTEND_PORT)

# Überschreibt frontend/.env.local, die sonst auf die Produktion zeigt
FRONTEND_DEV_ENV := API_URL=http://localhost:$(API_PORT) API_KEY=$(DEV_API_KEY)

.PHONY: help
help: ## Diese Übersicht
	@awk 'BEGIN {FS = ":.*##"} /^##@/ {printf "\n\033[1m%s\033[0m\n", substr($$0, 5)} /^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

##@ Setup

.PHONY: install install-api install-frontend install-app
install: install-api install-frontend ## Abhängigkeiten für API und Frontend installieren
install-api:
	cd api && npm install
install-frontend:
	cd frontend && pnpm install --config.confirmModulesPurge=false
install-app: ## Flutter-Abhängigkeiten installieren
	cd app && flutter pub get

##@ Entwicklung

.PHONY: dev api frontend app
dev: db-check ## API und Frontend zusammen starten (gegen central_postgres)
	@echo "API:      http://localhost:$(API_PORT)  (Swagger: /docs)"
	@echo "Frontend: http://localhost:$(FRONTEND_PORT)"
	@$(MAKE) --no-print-directory -j2 api frontend

api: ## Nur die API mit Hot-Reload (nodemon) gegen central_postgres
	cd api && $(API_DEV_ENV) npm run dev

frontend: ## Nur das Frontend (Next.js) gegen die lokale API
	cd frontend && $(FRONTEND_DEV_ENV) pnpm dev --port $(FRONTEND_PORT)

app: ## Flutter-App starten (Achtung: URLs sind fest auf die Produktion verdrahtet)
	cd app && flutter run

##@ Datenbank (manga_inventory auf central_postgres)

.PHONY: db-check db-psql db-backup
db-check: ## Ist die Dev-Datenbank erreichbar?
	@test -f api/.env || { echo "api/.env fehlt — Vorlage: api/.env.example"; exit 1; }
	@$(DB_EXEC) $(DB_CONTAINER) psql $(DB_ARGS) -tAc "SELECT 'Dev-DB ok: ' || count(*) || ' Titel' FROM manga"

db-psql: ## psql-Shell auf der Dev-Datenbank
	$(DB_EXEC) -it $(DB_CONTAINER) psql $(DB_ARGS)

db-backup: ## Dump der Dev-Datenbank nach ~/ (vor Migrationen!)
	@# Als Superuser des Containers: manga und device_tokens gehören nicht
	@# manga_admin, dessen Dump bricht an fehlenden Rechten ab.
	@# Erst in .tmp schreiben: ein abgebrochener Dump darf kein Backup ersetzen
	f=~/manga_inventory-dev-db-sicherung-$$(date +%Y%m%d-%H%M%S).sql.gz; \
	docker exec $(DB_CONTAINER) sh -c "pg_dump --no-owner -U \"\$$POSTGRES_USER\" -d $(call env_var,DB_NAME)" \
		| gzip > "$$f.tmp" && mv "$$f.tmp" "$$f" && ls -lh "$$f" || { rm -f "$$f.tmp"; exit 1; }

##@ Image

.PHONY: image image-test
image: ## API-Image lokal bauen
	docker build -t $(API_IMAGE):dev api

image-test: image ## Image starten und /health prüfen — wie die CI
	@docker rm -f manga-smoke >/dev/null 2>&1 || true
	@docker run -d --name manga-smoke -p 127.0.0.1:3999:3000 -e NODE_ENV=production $(API_IMAGE):dev >/dev/null
	@for i in $$(seq 1 20); do \
		if curl -fsS http://localhost:3999/health; then echo; echo "Health-Check ok"; docker rm -f manga-smoke >/dev/null; exit 0; fi; \
		sleep 1; \
	done; \
	docker logs manga-smoke; docker rm -f manga-smoke >/dev/null; exit 1

##@ Produktion

.PHONY: deploy deploy-status prod-health prod-logs
deploy: ## Build + Deploy auf dmz über GitHub Actions anstoßen
	gh workflow run api-image.yml --ref main
	@sleep 3
	gh run watch $$(gh run list --workflow api-image.yml -L 1 --json databaseId -q '.[0].databaseId')

deploy-status: ## Letzte Läufe des Deploy-Workflows
	gh run list --workflow api-image.yml -L 5

prod-health: ## /health der Produktions-API abfragen
	curl -fsS $(PROD_URL)/health; echo

prod-logs: ## Logs des API-Containers auf dmz
	ssh dmz docker logs --tail 100 -f vacation_manga_api

##@ Aufräumen

.PHONY: clean
clean: ## Build-Artefakte entfernen
	rm -rf frontend/.next
	-docker image rm $(API_IMAGE):dev 2>/dev/null
