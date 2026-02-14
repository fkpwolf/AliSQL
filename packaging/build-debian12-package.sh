#!/bin/bash
#
# Build Debian 12 (Bookworm) packages for AliSQL
# This script creates optimized, smaller-sized packages
#

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$SOURCE_DIR}"
DEB_CODENAME="${DEB_CODENAME:-bookworm}"
DEB_PRODUCT="${DEB_PRODUCT:-community}"

# Package size optimization flags
SKIP_DEBUG_PACKAGES="${SKIP_DEBUG_PACKAGES:-1}"
SKIP_TEST_PACKAGES="${SKIP_TEST_PACKAGES:-1}"
MINIMAL_BUILD="${MINIMAL_BUILD:-1}"

# --- Helper Functions ---
log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

check_prerequisites() {
    log_info "Checking build prerequisites..."
    
    local missing_deps=()
    
    # Essential build tools
    for cmd in cmake dpkg-buildpackage lsb_release; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_deps[*]}"
        log_info "Install them with:"
        log_info "  sudo apt-get update"
        log_info "  sudo apt-get install -y cmake debhelper devscripts lsb-release"
        return 1
    fi
    
    log_info "All prerequisites satisfied"
    return 0
}

install_build_dependencies() {
    log_info "Installing build dependencies..."
    
    # Install essential Debian build dependencies
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        debhelper \
        cmake \
        bison \
        libaio-dev \
        libncurses5-dev \
        libssl-dev \
        zlib1g-dev \
        libcurl4-openssl-dev \
        libldap2-dev \
        libsasl2-dev \
        libnuma-dev \
        libmecab-dev \
        perl \
        psmisc \
        po-debconf \
        lsb-release \
        fakeroot \
        patchelf \
        libjson-perl \
        elfutils \
        devscripts || {
            log_error "Failed to install build dependencies"
            return 1
        }
    
    log_info "Build dependencies installed successfully"
}

configure_cmake() {
    log_info "Configuring CMake for Debian 12..."
    
    cd "$BUILD_DIR"
    
    # Set Debian codename
    export DEB_CODENAME="$DEB_CODENAME"
    
    local cmake_args=(
        -DCMAKE_BUILD_TYPE=RelWithDebInfo
        -DBUILD_CONFIG=mysql_release
        -DDEB_PRODUCT="$DEB_PRODUCT"
        -DDEB_CODENAME="$DEB_CODENAME"
    )
    
    # Size optimization: disable debug build if requested
    if [ "$SKIP_DEBUG_PACKAGES" = "1" ]; then
        log_info "Disabling debug packages to reduce size"
        cmake_args+=(-DDEB_WITH_DEBUG=0)
    fi
    
    # Minimal build configuration
    if [ "$MINIMAL_BUILD" = "1" ]; then
        log_info "Using minimal build configuration"
        cmake_args+=(
            -DWITH_UNIT_TESTS=0
            -DWITH_EMBEDDED_SERVER=0
        )
    fi
    
    log_info "Running CMake with args: ${cmake_args[*]}"
    cmake . "${cmake_args[@]}"
    
    log_info "CMake configuration complete"
}

build_packages() {
    log_info "Building Debian packages..."
    
    cd "$BUILD_DIR"
    
    # Check if debian/ directory was created by CMake
    if [ ! -d "debian" ]; then
        log_error "debian/ directory not found. CMake configuration may have failed."
        return 1
    fi
    
    log_info "Building source package..."
    
    # Build packages with dpkg-buildpackage
    # -us -uc: Don't sign the packages (for development builds)
    # -b: Binary-only build (faster, no source package)
    # -j$(nproc): Use all available CPU cores
    
    local dpkg_args="-us -uc -b"
    
    log_info "Running dpkg-buildpackage..."
    dpkg-buildpackage $dpkg_args -j$(nproc) || {
        log_error "Package build failed"
        return 1
    }
    
    log_info "Package build completed successfully"
}

list_packages() {
    log_info "Listing built packages..."
    
    cd "$SOURCE_DIR"
    
    if ls ../*.deb 1> /dev/null 2>&1; then
        log_info "Built packages:"
        ls -lh ../*.deb | awk '{printf "  %s %s\n", $5, $9}'
        
        log_info ""
        log_info "Total package size:"
        du -ch ../*.deb | tail -1
    else
        log_error "No .deb packages found"
        return 1
    fi
}

create_install_script() {
    log_info "Creating installation helper script..."
    
    cat > "$SOURCE_DIR/../install-alisql-packages.sh" <<'EOF'
#!/bin/bash
# Install AliSQL Debian packages
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing AliSQL packages..."
sudo dpkg -i "$SCRIPT_DIR"/*.deb || {
    echo "Fixing dependencies..."
    sudo apt-get install -f -y
}

echo "Installation complete!"
echo "To start MySQL server:"
echo "  sudo systemctl start mysql"
echo "  sudo systemctl enable mysql"
EOF
    
    chmod +x "$SOURCE_DIR/../install-alisql-packages.sh"
    log_info "Created install-alisql-packages.sh in parent directory"
}

show_usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Build Debian 12 (Bookworm) packages for AliSQL with size optimization.

OPTIONS:
    -h, --help              Show this help message
    -i, --install-deps      Install build dependencies
    --with-debug            Include debug packages (increases size)
    --with-tests            Include test packages (increases size)
    --full-build            Full build (disables minimal optimizations)
    
ENVIRONMENT VARIABLES:
    DEB_CODENAME            Debian codename (default: bookworm)
    DEB_PRODUCT             Product type: community or commercial (default: community)
    BUILD_DIR               Build directory (default: source directory)
    SKIP_DEBUG_PACKAGES     Skip debug packages (default: 1)
    SKIP_TEST_PACKAGES      Skip test packages (default: 1)
    MINIMAL_BUILD           Use minimal build settings (default: 1)

EXAMPLES:
    # Basic build with optimizations:
    $0
    
    # Install dependencies and build:
    $0 --install-deps
    
    # Full build with all packages:
    $0 --full-build --with-debug --with-tests

EOF
}

# --- Main ---
main() {
    local install_deps=0
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -i|--install-deps)
                install_deps=1
                shift
                ;;
            --with-debug)
                SKIP_DEBUG_PACKAGES=0
                shift
                ;;
            --with-tests)
                SKIP_TEST_PACKAGES=0
                shift
                ;;
            --full-build)
                MINIMAL_BUILD=0
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    log_info "=== AliSQL Debian 12 Package Builder ==="
    log_info "Source directory: $SOURCE_DIR"
    log_info "Build directory: $BUILD_DIR"
    log_info "Debian codename: $DEB_CODENAME"
    log_info "Product type: $DEB_PRODUCT"
    log_info "Skip debug packages: $SKIP_DEBUG_PACKAGES"
    log_info "Skip test packages: $SKIP_TEST_PACKAGES"
    log_info "Minimal build: $MINIMAL_BUILD"
    log_info ""
    
    # Check prerequisites
    if ! check_prerequisites; then
        if [ "$install_deps" = "1" ]; then
            install_build_dependencies
        else
            log_error "Use --install-deps to install missing dependencies"
            exit 1
        fi
    fi
    
    # Configure and build
    configure_cmake
    build_packages
    
    # Show results
    list_packages
    create_install_script
    
    log_info ""
    log_info "=== Build Complete ==="
    log_info "Packages are located in: $(dirname "$SOURCE_DIR")"
    log_info "To install, run: ../install-alisql-packages.sh"
}

# Run main if script is executed (not sourced)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
