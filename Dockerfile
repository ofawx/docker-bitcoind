# Use Alpine for tiny image
FROM alpine:latest

# Get version from build action (in turn from /version)
ARG VERSION

# Make sure APKs are downloaded over SSL. See: https://github.com/gliderlabs/docker-alpine/issues/184
RUN sed -i 's|http://dl-cdn.alpinelinux.org|https://alpine.global.ssl.fastly.net|g' /etc/apk/repositories

# Install PGP for verification
RUN apk add --no-cache  gnupg

# Trusted Bitcoin keys
# https://github.com/bitcoin/bitcoin/blob/master/contrib/verify-commits/trusted-keys
ENV KEYS 71A3B16735405025D447E8F274810B012346C9A6 133EAC179436F14A5CF1B794860FEB804E669320
RUN timeout 16s  gpg  --keyserver keyserver.ubuntu.com  --recv-keys $KEYS

# Print imported keys, but also ensure there's no other keys in the system
RUN gpg --list-keys | tail -n +3 | tee /tmp/keys.txt && \
    gpg --list-keys $KEYS | diff - /tmp/keys.txt

# Download checksums
ADD https://bitcoincore.org/bin/bitcoin-core-$VERSION/SHA256SUMS.asc  ./

# Download source code (intentionally different website than checksums)
ADD https://bitcoin.org/bin/bitcoin-core-$VERSION/bitcoin-$VERSION.tar.gz ./

# Verify that hashes are signed with the previously imported key
RUN gpg --verify SHA256SUMS.asc

# Verify that downloaded source-code archive matches exactly the hash that's provided
RUN grep " bitcoin-$VERSION.tar.gz\$" SHA256SUMS.asc | sha256sum -c -

# Extract
RUN tar -xzf "bitcoin-$VERSION.tar.gz" && \
    rm  -f   "bitcoin-$VERSION.tar.gz"

# Get BerkeleyDB source
ADD https://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz

# Check source against known hash
# https://github.com/bitcoin/bitcoin/blob/master/contrib/install_db4.sh
#ENV BDB_HASH='12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef'
