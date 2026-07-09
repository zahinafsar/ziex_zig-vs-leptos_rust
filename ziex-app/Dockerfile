FROM debian:bookworm-slim AS base

ARG ZIG_VERSION=0.16.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl xz-utils git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN arch="$(uname -m)"; \
    case "$arch" in \
      aarch64|arm64) zarch=aarch64 ;; \
      x86_64|amd64) zarch=x86_64 ;; \
      *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://ziglang.org/download/${ZIG_VERSION}/zig-${zarch}-linux-${ZIG_VERSION}.tar.xz" -o /tmp/zig.tar.xz; \
    mkdir -p /opt/zig; \
    tar -xJf /tmp/zig.tar.xz -C /opt/zig --strip-components=1; \
    rm /tmp/zig.tar.xz; \
    ln -s /opt/zig/zig /usr/local/bin/zig

WORKDIR /app
COPY . .

RUN zig build --release=fast

ENV PORT=3000
EXPOSE 3000

CMD ["zig", "build", "serve", "--release=fast"]
