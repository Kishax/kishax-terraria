#!/bin/bash
# Download Terraria world data and tshock.sqlite from S3
# Based on data/terraria/Makefile

set -e

S3_BUCKET="${S3_BUCKET:-kishax-production-terraria-backups}"
AWS_REGION="${AWS_REGION:-ap-northeast-1}"

echo "🔍 S3から最新バージョンを検索中..."

# Find latest year-month directory
LATEST_YEARMONTH=$(aws s3 ls s3://${S3_BUCKET}/deployment/ --region ${AWS_REGION} | grep PRE | awk '{print $2}' | sed 's/\///' | sort -r | head -n 1)

if [ -z "$LATEST_YEARMONTH" ]; then
    echo "⚠️  No deployment found in S3"
    exit 0
fi

# Find latest version within that year-month
LATEST_VERSION=$(aws s3 ls s3://${S3_BUCKET}/deployment/${LATEST_YEARMONTH}/ --region ${AWS_REGION} | grep PRE | awk '{print $2}' | sed 's/\///' | sort -rn | head -n 1)

if [ -z "$LATEST_VERSION" ]; then
    echo "⚠️  No version found in S3"
    exit 0
fi

echo "📦 最新バージョン: ${LATEST_YEARMONTH}/${LATEST_VERSION}"
echo "📥 ダウンロード中..."

# Download Worlds directory
echo "  📥 Downloading Worlds..."
aws s3 sync s3://${S3_BUCKET}/deployment/${LATEST_YEARMONTH}/${LATEST_VERSION}/terraria/Worlds/ /terraria/Worlds/ --region ${AWS_REGION} --delete || true

# Download tshock.sqlite
echo "  📥 Downloading tshock.sqlite..."
mkdir -p /terraria/tshock
aws s3 sync s3://${S3_BUCKET}/deployment/${LATEST_YEARMONTH}/${LATEST_VERSION}/terraria/tshock/ /terraria/tshock/ --region ${AWS_REGION} --exclude "*" --include "tshock.sqlite" || true

echo "✅ ダウンロード完了"
