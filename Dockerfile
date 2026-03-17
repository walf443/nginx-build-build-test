FROM golang:1.24-trixie AS builder

RUN apt-get update && apt-get install -y \
    build-essential \
    libpcre2-dev \
    zlib1g-dev \
    libssl-dev \
    git \
    mercurial \
    patch \
    cmake \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

RUN go install github.com/cubicdaiya/nginx-build@latest

COPY configure.sh /tmp/configure.sh
RUN chmod +x /tmp/configure.sh

# Build BoringSSL separately with CMake
RUN git clone https://boringssl.googlesource.com/boringssl /tmp/boringssl \
    && cd /tmp/boringssl \
    && mkdir build \
    && cd build \
    && cmake -GNinja .. \
    && ninja \
    && cd /tmp/boringssl \
    && mkdir -p .openssl/lib \
    && cp build/libssl.a .openssl/lib/ \
    && cp build/libcrypto.a .openssl/lib/ \
    && ln -s /tmp/boringssl/include .openssl/include

ARG NGINX_VERSION=1.28.2
RUN nginx-build -d /tmp/nginx-build \
    -v ${NGINX_VERSION} \
    -c /tmp/configure.sh \
    -pcre \
    -zlib \
    && cd /tmp/nginx-build/nginx/${NGINX_VERSION}/nginx-${NGINX_VERSION} \
    && make install

FROM debian:trixie-slim

RUN apt-get update && apt-get install -y \
    libpcre2-8-0 \
    zlib1g \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/log/nginx /var/cache/nginx

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx

EXPOSE 80

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
