# SSR Render Benchmark: Ziex vs Leptos

Micro-benchmark of pure server-side rendering: how fast each framework turns a
component into an HTML string. No HTTP server, no network, no client bundle. Each
program builds one component and renders it to a writer in a tight loop, then
reports nanoseconds per render. Everything runs in Docker so the result is
reproducible.

Both render the identical workload: a `<main>` containing 50
`<div>SSR {v}-{i}</div>` rows produced by a server-side loop.

- **Ziex** (Zig, `0.1.0-dev`, Zig 0.16.0): `SsrPage(allocator)` component in
  `ziex-app/app/SsrPage.zx`, rendered with `component.render(&writer, .{})` into a
  `std.Io.Writer.Allocating`.
- **Leptos** (Rust, `0.8`): `SsrPage()` component rendered with `.to_html()` under
  a fresh `Owner`.

Each renders 1,000,000 times and prints one JSON line with `ns_per_op` and
`bytes_per_op`.

## Layout

```
ssr-bench/
├── ziex-app/
│   ├── app/SsrPage.zx     component under test (takes allocator as props)
│   ├── app/main.zig       render loop, no App/server started
│   └── Dockerfile
├── leptos-app/
│   ├── src/main.rs        component + render loop
│   └── Dockerfile
├── bench.sh               builds both images, runs both, prints comparison
└── results/              raw JSON output
```

## Run

```bash
./bench.sh
```

The script builds both images, runs each container once (the container's only job
is to render the component a million times and print its timing), then prints a
side-by-side table. Raw JSON lands in `results/*.json`.

## Notes on fairness

- Both time build + render of the same 50-row list, freshly on every iteration,
  through each framework's real SSR path (Ziex's `{for (...)}` template loop plus
  `Component.render`; Leptos's `view!` plus `.to_html()`). Nothing is cached.
- Ziex is built `--release=fast`; Leptos is built `--release` with LTO.
- Ziex resets an arena allocator each iteration; Leptos creates and drops a
  reactive `Owner` each iteration. Both costs are part of one SSR render and are
  left in.
- The output sizes differ: Leptos SSR output includes its `<!>` text hydration
  markers, so it emits more bytes per render than Ziex's plain markup. That is the
  genuine output of each engine, not padding.
- Numbers depend on host hardware and Docker CPU allocation. Treat them as a
  relative comparison on one machine, not absolute throughput claims.

## Results

Host: Apple Silicon (arm64), Docker Desktop. 1,000,000 renders each. Raw data in
`results/*.json`.

| metric         | Ziex (Zig) | Leptos (Rust) |
| -------------- | ---------: | ------------: |
| ns / render    |    ~4,920  |        ~1,790 |
| renders / sec  |   ~203,000 |      ~559,000 |
| bytes / render |        953 |         1,406 |

On this machine **Leptos rendered about 2.7x faster per component** than this
pre-1.0 Ziex dev build. Both are fast in absolute terms (hundreds of thousands of
full component renders per second). Ziex is `0.1.0-dev`, so its render path is not
final.
