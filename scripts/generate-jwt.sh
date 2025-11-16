#!/usr/bin/env bash
set -euo pipefail

# Generate an HS256 JWT for testing the baseline and WASM demos.
# Claims:
#   sub:  "user123"
#   iss:  "auth.example.com"
#   roles: ["admin"]
# Secret:
#   "my-secret"

docker run --rm node:20-alpine sh -c '
  set -e
  mkdir -p /tmp/app && cd /tmp/app
  npm init -y >/dev/null 2>&1
  npm install jsonwebtoken >/dev/null 2>&1
  node -e "console.log(require(\"jsonwebtoken\").sign(
    { sub: \"user123\", iss: \"auth.example.com\", roles: [\"admin\"] },
    \"my-secret\",
    { algorithm: \"HS256\", expiresIn: \"10m\" }
  ))"
'
