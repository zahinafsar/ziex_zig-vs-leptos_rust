FROM debian:bookworm-slim AS build

ARG ZIG_VER=0.16.0
RUN apt-get update && apt-get install -y curl xz-utils
RUN curl -fL https://ziglang.org/download/${ZIG_VER}/zig-$(uname -m)-linux-${ZIG_VER}.tar.xz -o zig.tar.xz && \
tar xf zig.tar.xz && \
mv zig-$(uname -m)-linux-${ZIG_VER}/ /opt/zig
ENV PATH="/opt/zig:$PATH"

WORKDIR /build
COPY build.zig build.zig.zon ./
RUN zig build --fetch
COPY app/ ./app/
RUN zig build --release=fast

FROM debian:bookworm-slim
WORKDIR /app

COPY --from=build /build/zig-out/bin /app
COPY --from=build /build/zig-out/static /app/static

ENTRYPOINT ["/app/ziex_app"]