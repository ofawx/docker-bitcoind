FROM alpine AS build

RUN apk --no-cache add autoconf automake libtool boost-dev libevent-dev libffi-dev openssl-dev bash coreutils git && \
    apk --no-cache add --update alpine-sdk build-base

ARG VERSION

RUN git clone --depth 1 https://github.com/bitcoin/bitcoin.git --branch v$VERSION --single-branch

WORKDIR /bitcoin

RUN cd /bitcoin/depends; make NO_QT=1

RUN wget https://zlib.net/zlib-1.3.tar.gz && \
    echo "ff0ba4c292013dbc27530b3a81e1f9a813cd39de01ca5e0f8bf355702efa593e  zlib-1.3.tar.gz" | sha256sum -c && \
    mkdir -p /usr/src/zlib; tar zxvf zlib-1.3.tar.gz -C /usr/src && \
    cd /usr/src/zlib-1.3; ./configure; make -j"$(($(nproc)+1))"; make -j"$(($(nproc)+1))" install

RUN export CONFIG_SITE=/bitcoin/depends/$(/bitcoin/depends/config.guess)/share/config.site && \
    cd /bitcoin; ./autogen.sh; \
    ./configure --disable-ccache \
    --disable-maintainer-mode \
    --disable-dependency-tracking \
    --enable-reduce-exports --disable-bench \
    --disable-tests \
    --disable-gui-tests \
    --without-gui \
    --without-miniupnpc \
    CFLAGS="-O2 -g0 --static -static -fPIC" \
    CXXFLAGS="-O2 -g0 --static -static -fPIC" \
    LDFLAGS="-s -static-libgcc -static-libstdc++ -Wl,-O2"

RUN make -j"$(($(nproc)+1))" && \
    make -j"$(($(nproc)+1))" install

FROM alpine:latest
COPY --from=build /usr/local /usr/local
COPY --from=build /bitcoin/share/examples/bitcoin.conf /.bitcoin/bitcoin.conf

VOLUME ["/.bitcoin"]

EXPOSE 8332 8333 18332 18333 18444

ENTRYPOINT ["/usr/local/bin/bitcoind", "-printtoconsole"]
