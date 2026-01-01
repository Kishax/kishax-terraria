#!/bin/bash
# Upload Terraria world data and tshock.sqlite to S3
# Based on data/terraria/Makefile

set -e

S3_BUCKET="${S3_BUCKET:-kishax-production-terraria-backups}"
AWS_REGION="${AWS_REGION:-ap-northeast-1}"
CREATE_NEW_VERSION="${1:-false}"

if [ "$CREATE_NEW_VERSION" = "new" ]; then
    echo "🆕 新バージョンを作成します"
    YEARMONTH=$(date +%Y%m)

    # Find latest version in current month
    LATEST_VERSION=$(aws s3 ls s3://${S3_BUCKET}/deployment/${YEARMONTH}/ --region ${AWS_REGION} 2>/dev/null | grep PRE | awk '{print $2}' | sed 's/\///' | sort -rn | head -n 1)

    if [ -z "$LATEST_VERSION" ]; then
        NEW_VERSION=1
    else
        NEW_VERSION=$((LATEST_VERSION + 1))
    fi

    echo "📦 新バージョン: ${YEARMONTH}/${NEW_VERSION}"
    S3_PATH="s3://${S3_BUCKET}/deployment/${YEARMONTH}/${NEW_VERSION}/terraria/"
else
    echo "🔍 S3から最新バージョンを検索中..."
    LATEST_YEARMONTH=$(aws s3 ls s3://${S3_BUCKET}/deployment/ --region ${AWS_REGION} | grep PRE | awk '{print $2}' | sed 's/\///' | sort -r | head -n 1)
    LATEST_VERSION=$(aws s3 ls s3://${S3_BUCKET}/deployment/${LATEST_YEARMONTH}/ --region ${AWS_REGION} | grep PRE | awk '{print $2}' | sed 's/\///' | sort -rn | head -n 1)

    echo "📦 既存バージョンに上書き: ${LATEST_YEARMONTH}/${LATEST_VERSION}"
    S3_PATH="s3://${S3_BUCKET}/deployment/${LATEST_YEARMONTH}/${LATEST_VERSION}/terraria/"
fi

echo "📤 アップロード中..."

# Upload Worlds directory
echo "  📤 Uploading Worlds..."
aws s3 sync /terraria/Worlds/ ${S3_PATH}Worlds/ --region ${AWS_REGION} --delete

# Upload tshock.sqlite only
echo "  📤 Uploading tshock.sqlite..."
aws s3 cp /terraria/tshock/tshock.sqlite ${S3_PATH}tshock/tshock.sqlite --region ${AWS_REGION}

echo "✅ アップロード完了"
