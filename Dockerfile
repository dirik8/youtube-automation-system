FROM node:20-alpine

WORKDIR /app

# Install system dependencies for Puppeteer
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    freetype-dev \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    python3 \
    make \
    g++

# Set Puppeteer to use installed Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Install n8n and additional packages
RUN npm install -g n8n@latest

# Install additional Node.js packages for workflows
RUN npm install -g \
    puppeteer-extra@3.3.6 \
    puppeteer-extra-plugin-stealth@2.11.2 \
    papaparse@5.4.1 \
    axios@1.6.0

# Create n8n directory
RUN mkdir -p /root/.n8n

# Copy custom nodes and configurations
COPY configs/n8n-config.json /root/.n8n/config.json

EXPOSE 5678

CMD ["n8n", "start"]
