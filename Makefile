include .env

.PHONY: help console upload-s3 download-s3 backup-world deploy-world

.DEFAULT_GOAL := help

help: ## ヘルプを表示
	@echo "Kishax Terraria Server Makefile"
	@echo ""
	@echo "利用可能なコマンド:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

console: ## Terrariaサーバコンソールに接続
	@if ! docker ps --format "table {{.Names}}" | grep -q kishax-terraria; then \
		echo "⚠️  kishax-terrariaコンテナが動作していません。make up で起動してください。"; \
		exit 1; \
	fi
	@echo "🎮 Terrariaサーバコンソールに接続します..."
	@echo "終了するには Ctrl+A → D を押してください"
	docker exec -it kishax-terraria screen -rx terraria

logs-tshock: ## TShockログを表示
	@if ! docker ps --format "table {{.Names}}" | grep -q kishax-terraria; then \
		echo "⚠️  kishax-terrariaコンテナが動作していません。make up で起動してください。"; \
		exit 1; \
	fi
	docker exec -it kishax-terraria cat /terraria/tshock/logs/$$(docker exec kishax-terraria ls -t /terraria/tshock/logs | head -n 1)

upload-s3: ## ワールドデータをS3にアップロード
	@if ! docker ps --format "table {{.Names}}" | grep -q kishax-terraria; then \
		echo "⚠️  kishax-terrariaコンテナが動作していません。make up で起動してください。"; \
		exit 1; \
	fi
	docker exec -it kishax-terraria /terraria/scripts/upload-to-s3.sh

upload-s3-new: ## ワールドデータを新バージョンとしてS3にアップロード
	@if ! docker ps --format "table {{.Names}}" | grep -q kishax-terraria; then \
		echo "⚠️  kishax-terrariaコンテナが動作していません。make up で起動してください。"; \
		exit 1; \
	fi
	docker exec -it kishax-terraria /terraria/scripts/upload-to-s3.sh new

download-s3: ## S3からワールドデータをダウンロード
	@if ! docker ps --format "table {{.Names}}" | grep -q kishax-terraria; then \
		echo "⚠️  kishax-terrariaコンテナが動作していません。make up で起動してください。"; \
		exit 1; \
	fi
	docker exec -it kishax-terraria /terraria/scripts/download-from-s3.sh

backup-world: upload-s3-new ## ワールドをバックアップ (新バージョン作成)

deploy-world: upload-s3 ## ワールドをデプロイ (既存バージョンに上書き)

