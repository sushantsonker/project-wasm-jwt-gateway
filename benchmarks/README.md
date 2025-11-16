# benchmarks

Place performance benchmarks, scripts, and results here.

Replace this placeholder with benchmark instructions and notes.

1. Generate a JWT Token

You must generate a token before testing either pipeline.

From repo root:

chmod +x scripts/generate-jwt.sh
export TOKEN=$(./scripts/generate-jwt.sh)
echo $TOKEN


This produces a valid HS256 JWT with:

iss = "auth.example.com"

sub = "user123"

roles = ["admin"]

secret = "my-secret"

🚀 2. Run Baseline: NGINX Gateway + Centralized Auth Service
2.1 Create Docker network
docker network create jwt-baseline-net || true

2.2 Start auth-service
docker build -t auth-service:baseline ./baseline-nginx-central-auth/auth-service

docker rm -f auth-service || true

docker run -d \
  --name auth-service \
  --network jwt-baseline-net \
  -e JWT_SECRET="my-secret" \
  auth-service:baseline

2.3 Start nginx-gateway
docker build -t nginx-gateway:baseline ./baseline-nginx-central-auth/nginx

docker rm -f nginx-gateway || true

docker run -d \
  --name nginx-gateway \
  --network jwt-baseline-net \
  -p 8080:8080 \
  nginx-gateway:baseline


NGINX listens at:

http://localhost:8080/api/

2.4 Test Baseline Pipeline
Valid token:
curl -i \
  -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/get

Missing token:
curl -i http://localhost:8080/api/get

Invalid token:
curl -i \
  -H "Authorization: Bearer bogus" \
  http://localhost:8080/api/get

🧩 3. Build the WASM JWT Filter (Rust → wasm32-wasip1)

From repo root:

docker run --rm -it \
  -v "$(pwd)/wasm-jwt-filter/filter:/code" \
  -w /code \
  rustlang/rust:nightly \
  sh -c "rustup target add wasm32-wasip1 && cargo build --release --target wasm32-wasip1"


Output file:

wasm-jwt-filter/filter/target/wasm32-wasip1/release/jwt-filter.wasm

⚡ 4. Run Envoy + WASM JWT Filter

From repo root:

cd wasm-jwt-filter/envoy-demo


Run Envoy with mounted WASM and config:

docker rm -f envoy-wasm || true

docker run -d \
  --name envoy-wasm \
  -v "$(pwd)/envoy.yaml:/etc/envoy/envoy.yaml" \
  -v "$(pwd)/../filter/target/wasm32-wasip1/release/jwt-filter.wasm:/etc/envoy/jwt-filter.wasm" \
  -p 8000:8000 \
  envoyproxy/envoy:v1.30.1


Envoy now listens at:

http://localhost:8000/

🧪 5. Test WASM / Envoy Pipeline
Valid JWT:
curl -i \
  -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/get

Missing token:
curl -i http://localhost:8000/get

Invalid token:
curl -i \
  -H "Authorization: Bearer bogus" \
  http://localhost:8000/get


Expected behavior depends on your lib.rs implementation
(default stub = everything passes through).

🛑 6. Stop Everything
docker rm -f nginx-gateway auth-service envoy-wasm

📌 Summary
Pipeline	Description	Start Command	URL
Baseline	NGINX → centralized auth → httpbin	docker run nginx-gateway …	http://localhost:8080

WASM optimized	Envoy → WASM filter → httpbin	docker run envoy-wasm …	http://localhost:8000

Use $TOKEN from scripts/generate-jwt.sh to authenticate.