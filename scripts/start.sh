#!/bin/bash
set -e

echo "Starting Kishax Terraria Server Environment..."

# TShock download URLs
TSHOCK_VERSION="5.2.4"
TSHOCK_TERRARIA_VERSION="1.4.4.9"
TSHOCK_URL="https://github.com/Pryaxis/TShock/releases/download/v${TSHOCK_VERSION}/TShock-${TSHOCK_VERSION}-for-Terraria-${TSHOCK_TERRARIA_VERSION}-linux-amd64-Release.zip"
TCR_PLUGIN_URL="https://github.com/xNarnia/TCR-TerrariaChatRelay/releases/download/v2.6.1-TS5.2.1/TerrariaChatRelay-v2.6.1-TS-5.2.1.zip"

# Download TShock if not already present
if [ ! -f "/terraria/TShock.Server" ]; then
    echo "📥 Downloading TShock ${TSHOCK_VERSION}..."
    wget -q "$TSHOCK_URL" -O /tmp/tshock.zip
    unzip -q /tmp/tshock.zip -d /terraria
    chmod +x /terraria/TShock.Server
    rm /tmp/tshock.zip
    echo "✅ TShock downloaded successfully"
else
    echo "✅ TShock already installed"
fi

# Download TerrariaChatRelay plugin if not already present
if [ ! -f "/terraria/ServerPlugins/TCR.Discord.TShock.dll" ]; then
    echo "📥 Downloading TerrariaChatRelay plugin..."
    wget -q "$TCR_PLUGIN_URL" -O /tmp/tcr.zip
    unzip -q /tmp/tcr.zip -d /tmp/tcr
    mkdir -p /terraria/ServerPlugins
    cp /tmp/tcr/*.dll /terraria/ServerPlugins/ 2>/dev/null || true
    rm -rf /tmp/tcr.zip /tmp/tcr
    echo "✅ TerrariaChatRelay plugin downloaded successfully"
else
    echo "✅ TerrariaChatRelay plugin already installed"
fi

# Download world data and tshock.sqlite from S3 if enabled
if [ "${S3_DOWNLOAD_ENABLED:-true}" = "true" ]; then
    echo "🌍 S3 download enabled, checking for world data..."
    /terraria/scripts/download-from-s3.sh || echo "⚠️  S3 download failed or no data found, continuing with fresh setup"
else
    echo "⏭️  S3 download disabled, using local data"
fi

# Create necessary directories
mkdir -p /terraria/Worlds
mkdir -p /terraria/tshock/TerrariaChatRelay
mkdir -p /terraria/tshock/logs

# Process config.json
echo "📝 Configuring TShock server..."
if [ -f "/terraria/config/config.json" ]; then
    CONFIG_FILE="/terraria/tshock/config.json"

    # Copy config if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        cp /terraria/config/config.json "$CONFIG_FILE"
    fi

    # Replace environment variables
    sed -i "s|\${SERVER_PASSWORD}|${SERVER_PASSWORD}|g" "$CONFIG_FILE"
    sed -i "s|\${SERVER_PORT}|${SERVER_PORT:-7777}|g" "$CONFIG_FILE"
    sed -i "s|\${MAX_SLOTS}|${MAX_SLOTS:-8}|g" "$CONFIG_FILE"
    sed -i "s|\${SERVER_NAME}|${SERVER_NAME:-Kishax Terraria Server}|g" "$CONFIG_FILE"
    sed -i "s|\${REST_API_ENABLED}|${REST_API_ENABLED:-true}|g" "$CONFIG_FILE"
    sed -i "s|\${REST_API_PORT}|${REST_API_PORT:-7878}|g" "$CONFIG_FILE"
    sed -i "s|\${REST_API_TOKEN}|${REST_API_TOKEN}|g" "$CONFIG_FILE"
    sed -i "s|\${REST_API_USERNAME}|${REST_API_USERNAME:-admin}|g" "$CONFIG_FILE"
    sed -i "s|\${REST_API_USERGROUP}|${REST_API_USERGROUP:-superadmin}|g" "$CONFIG_FILE"

    echo "✅ config.json configured"
fi

# Process TerrariaChatRelay-Discord.json
echo "📝 Configuring Discord bot..."
if [ -f "/terraria/config/TerrariaChatRelay-Discord.json" ]; then
    TCR_CONFIG_FILE="/terraria/tshock/TerrariaChatRelay/TerrariaChatRelay-Discord.json"

    # Copy config if it doesn't exist
    if [ ! -f "$TCR_CONFIG_FILE" ]; then
        cp /terraria/config/TerrariaChatRelay-Discord.json "$TCR_CONFIG_FILE"
    fi

    # Replace environment variables
    sed -i "s|\${DISCORD_BOT_TOKEN}|${DISCORD_BOT_TOKEN}|g" "$TCR_CONFIG_FILE"
    sed -i "s|\${DISCORD_CHANNEL_ID}|${DISCORD_CHANNEL_ID}|g" "$TCR_CONFIG_FILE"

    echo "✅ TerrariaChatRelay-Discord.json configured"
fi

# Create serverconfig.txt if it doesn't exist
if [ ! -f "/terraria/serverconfig.txt" ]; then
    echo "📝 Creating serverconfig.txt..."
    cat > /terraria/serverconfig.txt <<EOF
# Terraria Server Configuration
world=/terraria/Worlds/world.wld
autocreate=1
worldname=Kishax World
difficulty=1
maxplayers=${MAX_SLOTS:-8}
port=${SERVER_PORT:-7777}
password=${SERVER_PASSWORD}
motd=Welcome to Kishax Terraria Server!
worldpath=/terraria/Worlds/
EOF
    echo "✅ serverconfig.txt created"
fi

echo "Configuration completed!"
echo "Starting TShock server..."

# Start TShock in screen session
cd /terraria
screen -dmS terraria ./TShock.Server -config serverconfig.txt

echo "Terraria server started in screen session 'terraria'"
echo "Use 'docker exec -it kishax-terraria screen -r terraria' to access server console"
echo "Available screen sessions:"
screen -list

# Keep container alive by waiting for screen session
while screen -list | grep -q "terraria" 2>/dev/null; do
  sleep 30
done

echo "Screen session has ended. Container will exit."
