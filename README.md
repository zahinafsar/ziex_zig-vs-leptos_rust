# SSR Latency Benchmark: Ziex vs Leptos

Head-to-head SSR latency comparison of two full-stack frameworks, each rendering
the same minimal hello-world page, benchmarked with [`oha`](https://github.com/hatoo/oha).
Everything runs in Docker so the result is reproducible.

- **Ziex** (Zig, `0.1.0-dev.1259`, Zig 0.16.0) - `zig build serve`, file-routed page at `app/pages/page.zx`
- **Leptos** (Rust, `0.8`) - Axum server rendering a `view!` to an HTML string per request

Both serve on container port `3000`. Both render an identical minimal page: an
`<h1>` heading plus a paragraph, wrapped in a full HTML document.

## Layout

```
ssr-bench/
├── ziex-app/        Ziex app (starter template reduced to one SSR page) + Dockerfile
├── leptos-app/      Axum + Leptos SSR server + Dockerfile
├── docker-compose.yml   ziex -> localhost:3001, leptos -> localhost:3002
├── bench.sh         builds, starts, waits, runs oha, prints comparison
└── results/         raw oha JSON output
```

## Run

```bash
./bench.sh
```

Tunables (env vars):

```bash
DURATION=30s CONNECTIONS=100 ./bench.sh
```

The script:
1. `docker compose up -d --build` (builds both images, starts both servers)
2. Waits until each server answers on its host port
3. Runs `oha` from a container on the shared docker network, hitting each server
   directly (`http://ziex:3000/`, `http://leptos:3000/`) to avoid host port-mapping noise
4. Parses the JSON and prints a req/sec + p50/p90/p99 latency table

Stop the servers:

```bash
docker compose down
```

## Notes on fairness

- Both render per request with no caching. Ziex uses its production `serve` path
  (`--release=fast`); Leptos is built `--release` with LTO.
- The Leptos side isolates pure SSR render cost (no hydration/WASM assets), which
  matches what Ziex's SSR path does for a static page.
- Load is generated from a separate container on the same bridge network, so both
  frameworks face identical network conditions.
- Numbers depend on host hardware and Docker CPU allocation. Treat them as a
  relative comparison on one machine, not absolute throughput claims.

## Results

Host: Apple Silicon (arm64), Docker Desktop. Load: `oha`, 20s, 50 connections,
requests issued container-to-container over the shared bridge network. Two runs,
consistent. Raw data in `results/*.json`.

| metric       | Ziex (Zig) | Leptos (Rust) |
| ------------ | ---------: | ------------: |
| req/sec      |   ~182,700 |      ~235,000 |
| avg latency  |    0.27 ms |       0.22 ms |
| p50          |    0.23 ms |       0.10 ms |
| p90          |    0.46 ms |       0.54 ms |
| p99          |    0.98 ms |       0.90 ms |
| success      |       100% |          100% |
| total (20s)  |     ~3.65M |        ~4.6M  |

**Takeaways**

- On this machine, **Leptos was faster** for a minimal SSR page: ~28% higher
  throughput and roughly 2x lower median (p50) latency.
- At the tail they converge: **p90/p99 are within noise of each other** (~0.5 ms
  and ~0.9-1.0 ms for both).
- Both are extremely fast in absolute terms - sub-millisecond p50, millions of
  requests over 20s, 100% success. For a hello-world page this mostly measures
  per-request framework + HTTP-stack overhead, not real template work.
- This does **not** reproduce Ziex's published benchmark (which shows Ziex ahead
  of Leptos). Likely differences: their Leptos figure may include hydration/heavier
  output, different hardware, and a different HTTP harness. Ziex is also pre-1.0
  (`0.1.0-dev`), so its `serve` path is not final.

To draw stronger conclusions, raise the workload (e.g. `CONNECTIONS=200`,
list-render page) and run on the target deployment hardware rather than a laptop.
