# syntax=docker/dockerfile:1

FROM node:20-slim AS build
WORKDIR /app

# Build tooling for any native npm deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    python3 \
    make \
    g++ \
  && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:20-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production

# Minimal runtime deps + non-root user
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/* \
  && useradd -m -u 10001 appuser

# Install prod deps only
COPY --from=build /app/package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy built output
COPY --from=build /app/dist ./dist

# Where you’ll mount OAuth/token files
RUN mkdir -p /app/creds && chown -R appuser:appuser /app
USER appuser

EXPOSE 4100

# Default; override in compose/portainer if you want
CMD ["node", "dist/server.js", "--credentials-dir", "/app/creds"]
