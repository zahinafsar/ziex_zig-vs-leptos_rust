#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
RESULTS_DIR="results"
mkdir -p "$RESULTS_DIR"

echo "==> Building images"
docker build -t ssr-bench-ziex ./ziex-app
docker build -t ssr-bench-leptos ./leptos-app

echo "==> Running Ziex render benchmark"
docker run --rm ssr-bench-ziex | tee "$RESULTS_DIR/ziex.json"

echo "==> Running Leptos render benchmark"
docker run --rm ssr-bench-leptos | tee "$RESULTS_DIR/leptos.json"

echo
echo "==> Results (component render: string -> HTML)"
python3 - "$RESULTS_DIR/ziex.json" "$RESULTS_DIR/leptos.json" <<'PY'
import json, sys

def load(path):
    with open(path) as f:
        return json.load(f)

rows = []
for name, path in [("Ziex (Zig)", sys.argv[1]), ("Leptos (Rust)", sys.argv[2])]:
    d = load(path)
    rows.append({"name": name, "ns": d["ns_per_op"], "bytes": d["bytes_per_op"]})

hdr = f"{'metric':<14}" + "".join(f"{r['name']:>18}" for r in rows)
print(hdr)
print("-" * len(hdr))
print(f"{'ns / render':<14}" + "".join(f"{r['ns']:>18.2f}" for r in rows))
print(f"{'renders / sec':<14}" + "".join(f"{1e9 / r['ns']:>18,.0f}" for r in rows))
print(f"{'bytes / render':<14}" + "".join(f"{r['bytes']:>18,}" for r in rows))

z, l = rows[0], rows[1]
print()
if z["ns"] < l["ns"]:
    print(f"Ziex is {l['ns'] / z['ns']:.2f}x faster per render than Leptos")
else:
    print(f"Leptos is {z['ns'] / l['ns']:.2f}x faster per render than Ziex")
PY
