#!/usr/bin/env bash
set -euo pipefail

DURATION="${DURATION:-20s}"
CONNECTIONS="${CONNECTIONS:-50}"
OHA_IMAGE="ghcr.io/hatoo/oha:latest"

cd "$(dirname "$0")"
RESULTS_DIR="results"
mkdir -p "$RESULTS_DIR"

echo "==> Building and starting containers"
docker compose up -d --build

ZIEX_CID="$(docker compose ps -q ziex)"
if [ -z "$ZIEX_CID" ]; then
  echo "Could not find ziex container" >&2
  exit 1
fi
NET="$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' "$ZIEX_CID")"
if [ -z "$NET" ]; then
  echo "Could not find compose network" >&2
  exit 1
fi
echo "==> Using docker network: $NET"

wait_ready() {
  local name="$1" port="$2"
  echo -n "==> Waiting for $name on host port $port "
  for _ in $(seq 1 120); do
    if curl -fsS "http://localhost:${port}/" >/dev/null 2>&1; then
      echo "ready"
      return 0
    fi
    echo -n "."
    sleep 1
  done
  echo " TIMEOUT"
  docker compose logs "$name" | tail -30
  return 1
}

wait_ready ziex 3001
wait_ready leptos 3002

run_oha() {
  local target_host="$1" out="$2"
  docker run --rm --network "$NET" "$OHA_IMAGE" \
    -z "$DURATION" -c "$CONNECTIONS" --no-tui --output-format json \
    "http://${target_host}:3000/" > "$out"
}

echo "==> Benchmark: duration=$DURATION connections=$CONNECTIONS"
echo "==> Running oha against Ziex"
run_oha ziex "$RESULTS_DIR/ziex.json"
echo "==> Running oha against Leptos"
run_oha leptos "$RESULTS_DIR/leptos.json"

echo
echo "==> Results"
python3 - "$RESULTS_DIR/ziex.json" "$RESULTS_DIR/leptos.json" <<'PY'
import json, sys

def load(path):
    with open(path) as f:
        return json.load(f)

def ms(x):
    return x * 1000.0 if x is not None else None

def get(d, *keys):
    for k in keys:
        if isinstance(d, dict) and k in d:
            d = d[k]
        else:
            return None
    return d

frameworks = [("Ziex (Zig)", sys.argv[1]), ("Leptos (Rust)", sys.argv[2])]
rows = []
for name, path in frameworks:
    d = load(path)
    pct = d.get("latencyPercentiles", {})
    rows.append({
        "name": name,
        "rps": get(d, "summary", "requestsPerSec"),
        "avg": ms(get(d, "summary", "average")),
        "p50": ms(pct.get("p50")),
        "p90": ms(pct.get("p90")),
        "p99": ms(pct.get("p99")),
        "max": ms(get(d, "summary", "slowest")),
        "total": sum(d.get("statusCodeDistribution", {}).values()),
        "success": get(d, "summary", "successRate"),
    })

def fmt(v, unit=""):
    if v is None:
        return "n/a"
    if unit == "ms":
        return f"{v:.2f} ms"
    if unit == "rps":
        return f"{v:,.0f}"
    if unit == "count":
        return f"{v:,.0f}"
    if unit == "pct":
        return f"{v*100:.1f}%"
    return f"{v}"

hdr = f"{'metric':<14}" + "".join(f"{r['name']:>18}" for r in rows)
print(hdr)
print("-" * len(hdr))
def line(label, key, unit=""):
    print(f"{label:<14}" + "".join(f"{fmt(r[key], unit):>18}" for r in rows))

line("req/sec",    "rps", "rps")
line("avg latency","avg", "ms")
line("p50",        "p50", "ms")
line("p90",        "p90", "ms")
line("p99",        "p99", "ms")
line("max",        "max", "ms")
line("total reqs", "total", "count")
line("success",    "success", "pct")

z, l = rows[0], rows[1]
if z["p50"] and l["p50"]:
    print()
    if z["p50"] < l["p50"]:
        print(f"p50: Ziex is {l['p50']/z['p50']:.2f}x faster than Leptos")
    else:
        print(f"p50: Leptos is {z['p50']/l['p50']:.2f}x faster than Ziex")
PY

echo
echo "Raw JSON in $RESULTS_DIR/. Stop servers with: docker compose down"
