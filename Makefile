include .env

.PHONY: help console upload-s3 download-s3 backup-world deploy-world build-image upload-image load-image deploy-image

.DEFAULT_GOAL := help

# Docker image build and upload settings
IMAGE_NAME := kishax-terraria
IMAGE_TAG := latest
S3_BUCKET := kishax-production-docker-images
S3_PATH := terraria
AWS_PROFILE := AdministratorAccess-126112056177

help: ## ヘルプを表示
	@echo "Kishax Terraria Server Makefile"
	@echo ""
	@echo "利用可能なコマンド:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Docker Image管理:"
	@echo "  build-image          - Build Docker image (linux/amd64)"
	@echo "  upload-image         - Upload Docker image to S3"
	@echo "  load-image           - Download and load Docker image from S3"
	@echo "  deploy-image         - Build and upload Docker image"

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

build-image:
	@echo "Building Docker image for linux/amd64..."
	docker build --platform linux/amd64 -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "Build complete: $(IMAGE_NAME):$(IMAGE_TAG)"

upload-image:
	@echo "Saving Docker image to tar.gz..."
	docker save $(IMAGE_NAME):$(IMAGE_TAG) | gzip > $(IMAGE_NAME)-$(IMAGE_TAG).tar.gz
	@echo "Uploading to S3..."
	aws s3 cp $(IMAGE_NAME)-$(IMAGE_TAG).tar.gz \
		s3://$(S3_BUCKET)/$(S3_PATH)/$(IMAGE_NAME)-$(IMAGE_TAG).tar.gz \
		--profile $(AWS_PROFILE)
	@echo "Cleaning up local tar.gz file..."
	rm $(IMAGE_NAME)-$(IMAGE_TAG).tar.gz
	@echo "Upload complete!"

load-image:
	@echo "Downloading Docker image from S3..."
	aws s3 cp \
		s3://$(S3_BUCKET)/$(S3_PATH)/$(IMAGE_NAME)-$(IMAGE_TAG).tar.gz \
		$(IMAGE_NAME)-$(IMAGE_TAG).tar.gz
	@echo "Loading Docker image..."
	gunzip -c $(IMAGE_NAME)-$(IMAGE_TAG).tar.gz | docker load
	@echo "Cleaning up downloaded tar.gz file..."
	rm $(IMAGE_NAME)-$(IMAGE_TAG).tar.gz
	@echo "Load complete: $(IMAGE_NAME):$(IMAGE_TAG)"

deploy-image: build-image upload-image

