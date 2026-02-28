# syntax=docker/dockerfile:1
FROM node:20-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production

COPY --from=build /app/package*.json ./
RUN npm ci --omit=dev

COPY --from=build /app/dist ./dist

# OAuth callback listener
EXPOSE 4100

# Default files/dirs are runtime-mounted:
#  - .gauth.json
#  - .accounts.json
#  - credentials dir (stores .oauth2.<email>.json)
CMD ["node", "dist/server.js"]
