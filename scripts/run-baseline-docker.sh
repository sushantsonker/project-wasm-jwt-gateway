#!/usr/bin/env bash
set -e

# 1. Create a dedicated network (idempotent)
docker network create jwt-baseline-net || true

# 2. Build auth-service image
docker build -t auth-service:baseline ./baseline-nginx-central-auth/auth-service

# 3. Run auth-service container
docker rm -f auth-service || true
docker run -d \
  --name auth-service \
  --network jwt-baseline-net \
  -e JWT_SECRET="my-secret" \
  auth-service:baseline

# 4. Build nginx-gateway image
docker build -t nginx-gateway:baseline ./baseline-nginx-central-auth/nginx

# 5. Run nginx-gateway container
docker rm -f nginx-gateway || true
docker run -d \
  --name nginx-gateway \
  --network jwt-baseline-net \
  -p 8080:8080 \
  nginx-gateway:baseline

echo "Baseline NGINX + centralized auth is running on http://localhost:8080"
