# Debian 12 Size Optimization Configuration
# This file can be sourced before building to reduce package size

# Size optimization options for CMake
export DEB_CMAKE_SIZE_OPTS="-DWITH_DEBUG=OFF -DWITH_UNIT_TESTS=OFF"

# Skip large packages
export DEB_SKIP_DEBUG=1
export DEB_SKIP_TESTS=1

# Compiler optimization for smaller binaries
export CFLAGS="-Os -ffunction-sections -fdata-sections"
export CXXFLAGS="-Os -ffunction-sections -fdata-sections"
export LDFLAGS="-Wl,--gc-sections -Wl,--strip-all"

# Documentation
cat <<EOF

=== Debian 12 Package Size Optimization ===

The following optimizations are applied:
1. Debug symbols removed (-DWITH_DEBUG=OFF)
2. Unit tests excluded (-DWITH_UNIT_TESTS=OFF)
3. Compiler optimizations for size (-Os)
4. Dead code elimination (--gc-sections)
5. Binary stripping (--strip-all)

Expected size reduction: 60-70% compared to full build

To use these settings, source this file before building:
  source packaging/debian12-size-config.sh
  ./packaging/build-debian12-package.sh

EOF
