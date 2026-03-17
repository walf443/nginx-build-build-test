#!/bin/sh

./configure \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_v3_module \
--with-cc-opt="-I/tmp/boringssl/include" \
--with-ld-opt="/tmp/boringssl/.openssl/lib/libssl.a /tmp/boringssl/.openssl/lib/libcrypto.a -lstdc++"
