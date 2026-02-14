#!/bin/bash
# Build script for creating AliSQL Debian 12 packages.
# Produces a minimal .deb by stripping debug symbols and excluding the test suite.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---- Configurable knobs (override via environment) ----
BUILD_TYPE="${BUILD_TYPE:-Release}"         # Release keeps binary small
JOBS="${JOBS:-$(nproc)}"
PACKAGE_NAME="${PACKAGE_NAME:-alisql-server}"
INSTALL_PREFIX="/usr"

# ---- Derived values ----
MYSQL_VERSION_MAJOR=$(awk -F= '/MYSQL_VERSION_MAJOR/{print $2}' "$SOURCE_DIR/MYSQL_VERSION")
MYSQL_VERSION_MINOR=$(awk -F= '/MYSQL_VERSION_MINOR/{print $2}' "$SOURCE_DIR/MYSQL_VERSION")
MYSQL_VERSION_PATCH=$(awk -F= '/MYSQL_VERSION_PATCH/{print $2}' "$SOURCE_DIR/MYSQL_VERSION")
VERSION="${MYSQL_VERSION_MAJOR}.${MYSQL_VERSION_MINOR}.${MYSQL_VERSION_PATCH}"

BUILD_DIR="$SOURCE_DIR/build-deb12"
STAGE_DIR="$BUILD_DIR/stage"
PKG_ROOT="$BUILD_DIR/pkg-root"

usage() {
    cat <<EOF
Usage: $0 [--install-deps] [--build-type Release|RelWithDebInfo]

Options:
  --install-deps      Install build dependencies (requires root)
  --build-type TYPE   CMake build type (default: Release)
  -h, --help          Show this help
EOF
}

install_deps() {
    echo "==> Installing build dependencies for Debian 12..."
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential cmake pkg-config \
        libssl-dev libncurses5-dev libaio-dev libcurl4-openssl-dev \
        libnuma-dev libldap2-dev libsasl2-dev \
        bison patchelf fakeroot dpkg-dev \
        zlib1g-dev
}

do_cmake() {
    echo "==> Configuring (CMake ${BUILD_TYPE}) ..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    cmake "$SOURCE_DIR" \
        -DFORCE_INSOURCE_BUILD=OFF \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
        -DSYSCONFDIR=/etc/mysql \
        -DMYSQL_DATADIR=/var/lib/mysql \
        -DMYSQL_UNIX_ADDR=/var/run/mysqld/mysqld.sock \
        -DINSTALL_LAYOUT=DEB \
        -DWITH_UNIT_TESTS=OFF \
        -DWITH_DEBUG=OFF \
        -DWITH_EMBEDDED_SERVER=OFF \
        -DWITH_EXAMPLE_STORAGE_ENGINE=OFF \
        -DWITH_INNODB_MEMCACHED=OFF \
        -DWITH_ZLIB=bundled \
        -DWITH_ZSTD=bundled \
        -DWITH_BOOST="$SOURCE_DIR/extra/boost/boost_1_77_0" \
        -DWITH_EXTRA_CHARSETS=all \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_MYISAM_STORAGE_ENGINE=1 \
        -DWITH_CSV_STORAGE_ENGINE=1 \
        -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
        -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
        -DWITH_FEDERATED_STORAGE_ENGINE=1 \
        -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 \
        -DWITH_TEMPTABLE_STORAGE_ENGINE=1 \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_0900_ai_ci \
        -DENABLED_LOCAL_INFILE=ON \
        -DCOMPILATION_COMMENT="AliSQL Debian 12 Package" \
        -DREPRODUCIBLE_BUILD=OFF
}

do_build() {
    echo "==> Building with ${JOBS} parallel jobs ..."
    cd "$BUILD_DIR"
    make -j"$JOBS" VERBOSE=0
}

do_package() {
    echo "==> Packaging ..."
    cd "$BUILD_DIR"

    # Stage the install tree
    rm -rf "$STAGE_DIR"
    make install DESTDIR="$STAGE_DIR"

    # Strip all ELF binaries and shared libraries to minimize size
    find "$STAGE_DIR" -type f \( -name '*.so*' -o -perm /111 \) -print0 | \
        xargs -0 --no-run-if-empty strip --strip-unneeded 2>/dev/null || true

    # Remove test suite files to save ~500 MB
    rm -rf "$STAGE_DIR/$INSTALL_PREFIX/lib/mysql-test"
    rm -rf "$STAGE_DIR/$INSTALL_PREFIX/mysql-test"

    # Remove static libraries to save space
    find "$STAGE_DIR" -name '*.a' -delete 2>/dev/null || true

    # ---- Build the .deb ----
    local arch
    arch=$(dpkg --print-architecture)

    rm -rf "$PKG_ROOT"
    mkdir -p "$PKG_ROOT/DEBIAN"

    # Copy installed files into the package root
    cp -a "$STAGE_DIR"/* "$PKG_ROOT"/

    # Create the control file
    cat > "$PKG_ROOT/DEBIAN/control" <<CTRL
Package: ${PACKAGE_NAME}
Version: ${VERSION}-1debian12
Architecture: ${arch}
Maintainer: AliSQL Maintainers <alisql@example.com>
Depends: libc6, libssl3, libncurses6, libtinfo6, libaio1, zlib1g, libstdc++6, libnuma1
Section: database
Priority: optional
Homepage: https://github.com/alibaba/AliSQL
Description: AliSQL Server – a MySQL branch from Alibaba
 AliSQL is a MySQL branch from Alibaba Group, focusing on performance,
 stability, and ease of use. This package provides the server, client
 tools, and shared libraries for Debian 12 (Bookworm).
CTRL

    # Build the package
    dpkg-deb --build "$PKG_ROOT" "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}-1debian12_${arch}.deb"

    echo ""
    echo "==> Package created:"
    ls -lh "$BUILD_DIR"/*.deb
}

# ---- CLI entry point ----
while [[ $# -gt 0 ]]; do
    case "$1" in
        --install-deps)  install_deps; shift ;;
        --build-type)    shift; BUILD_TYPE="$1"; shift ;;
        -h|--help)       usage; exit 0 ;;
        *)               echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

do_cmake
do_build
do_package
