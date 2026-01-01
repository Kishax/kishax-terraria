# Dockerfile for TShock Terraria Server
FROM mcr.microsoft.com/dotnet/runtime:6.0

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    screen \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws

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

# Copy startup scripts
COPY scripts/start.sh /terraria/start.sh
COPY scripts/download-from-s3.sh /terraria/scripts/download-from-s3.sh
COPY scripts/upload-to-s3.sh /terraria/scripts/upload-to-s3.sh
RUN chmod +x /terraria/start.sh /terraria/scripts/*.sh

# Expose Terraria port
EXPOSE 7777

# Start script
CMD ["./start.sh"]
