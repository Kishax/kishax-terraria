# Dockerfile for TShock Terraria Server
FROM mcr.microsoft.com/dotnet/runtime:6.0

# Install runtime dependencies (removed screen and AWS CLI v2 for size optimization)
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    jq \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v1 (lighter than v2)
RUN pip3 install --no-cache-dir awscli && rm -rf /root/.cache

# Create directories
RUN mkdir -p /terraria \
    && mkdir -p /terraria/tshock \
    && mkdir -p /terraria/scripts \
    && mkdir -p /terraria/config

# Set working directory
WORKDIR /terraria

# Copy configuration files
COPY config/config.json /terraria/config/config.json
COPY config/TerrariaChatRelay-Discord.json /terraria/config/TerrariaChatRelay-Discord.json
COPY config/TCR.json /terraria/config/TCR.json

# Copy startup scripts
COPY scripts/start.sh /terraria/start.sh
COPY scripts/download-from-s3.sh /terraria/scripts/download-from-s3.sh
COPY scripts/upload-to-s3.sh /terraria/scripts/upload-to-s3.sh
RUN chmod +x /terraria/start.sh /terraria/scripts/*.sh

# Expose Terraria port
EXPOSE 7777

# Start script
CMD ["./start.sh"]
