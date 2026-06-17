# Multi-stage build for the Medusa admin SPA (container: medusa-web).
# This is a pure static frontend (Vite build) served by nginx. There is no
# database, no volume, and no runtime secret — nothing here is destructive.
#
# The Medusa backend URL is baked in at BUILD time (Vite inlines it):
#   MEDUSA_BACKEND_URL=https://med.awakenfs.store docker compose build web

FROM node:20-slim AS build
WORKDIR /app
# Vite + this dependency tree can spike past the default heap on a small box.
ENV NODE_OPTIONS=--max-old-space-size=1536
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --network-timeout 600000
COPY . .
# Consumed by vite.config.ts -> __MEDUSA_BACKEND_URL__ (see src/services/config.ts).
ARG MEDUSA_BACKEND_URL=""
ENV MEDUSA_BACKEND_URL=$MEDUSA_BACKEND_URL
# `yarn build` == `vite build`, output goes to ./public (vite.config build.outDir).
RUN yarn build

FROM nginx:1.27-alpine AS run
# SPA routing: serve built assets, fall back to index.html for client-side routes.
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/public /usr/share/nginx/html
EXPOSE 80
