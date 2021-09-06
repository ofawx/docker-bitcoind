FROM alpine AS build

RUN apk --no-cache add autoconf automake libtool boost-dev libevent-dev libffi-dev openssl-dev bash coreutils git && \
    apk --no-cache add --update alpine-sdk build-base

ARG VERSION

RUN git clone --depth 1 https://github.com/bitcoin/bitcoin.git --branch v$VERSION --single-branch

WORKDIR /bitcoin

RUN cd /bitcoin/depends; make NO_QT=1

RUN wget https://zlib.net/zlib-1.2.11.tar.gz && \
    echo "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1  zlib-1.2.11.tar.gz" | sha256sum -c && \
    mkdir -p /usr/src/zlib; tar zxvf zlib-1.2.11.tar.gz -C /usr/src && \
    cd /usr/src/zlib-1.2.11; ./configure; make; make install

RUN export CONFIG_SITE=/bitcoin/depends/$(/bitcoin/depends/config.guess)/share/config.site && \
    cd /bitcoin; ./autogen.sh; ./contrib/install_db4.sh . && \
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
    LDFLAGS="-s -static-libgcc -static-libstdc++ -Wl,-O2" \
    BDB_LIBS="-L/bitcoin/db4/lib -ldb_cxx-4.8" \
    BDB_CFLAGS="-I/bitcoin/db4/include"

RUN make && \
    make install

FROM alpine:latest
COPY --from=build /usr/local /usr/local
COPY --from=build /bitcoin/share/examples/bitcoin.conf /.bitcoin/bitcoin.conf

VOLUME ["/.bitcoin"]

EXPOSE 8332 8333 18332 18333 18444

CMD ["/usr/local/bin/bitcoind", "-printtoconsole"]
