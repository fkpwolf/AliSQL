#!/bin/bash
#
# Test script to validate Debian 12 packaging configuration
# This validates the setup without doing a full build
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Debian 12 Package Configuration Test ==="
echo ""

# Test 1: Check build script exists and is executable
echo "[Test 1] Checking build script..."
if [ -x "$SCRIPT_DIR/build-debian12-package.sh" ]; then
    echo "  ✓ build-debian12-package.sh is executable"
else
    echo "  ✗ build-debian12-package.sh not found or not executable"
    exit 1
fi

# Test 2: Verify documentation files
echo "[Test 2] Checking documentation..."
for doc in DEBIAN12_BUILD.md DEBIAN12_QUICKSTART.md README.md; do
    if [ -f "$SCRIPT_DIR/$doc" ]; then
        echo "  ✓ $doc exists"
    else
        echo "  ✗ $doc not found"
        exit 1
    fi
done

# Test 3: Check CMakeLists.txt has Debian 12 support
echo "[Test 3] Checking CMakeLists.txt for Debian 12 support..."
if grep -q "bookworm" "$SCRIPT_DIR/deb-in/CMakeLists.txt"; then
    echo "  ✓ Debian 12 (bookworm) support found in CMakeLists.txt"
else
    echo "  ✗ Debian 12 support not found in CMakeLists.txt"
    exit 1
fi

# Test 4: Validate script help output
echo "[Test 4] Testing build script help..."
if "$SCRIPT_DIR/build-debian12-package.sh" --help > /dev/null 2>&1; then
    echo "  ✓ Build script help works"
else
    echo "  ✗ Build script help failed"
    exit 1
fi

# Test 5: Check required packaging files exist
echo "[Test 5] Checking Debian packaging files..."
for file in control.in rules.in compat; do
    if [ -f "$SCRIPT_DIR/deb-in/$file" ]; then
        echo "  ✓ deb-in/$file exists"
    else
        echo "  ✗ deb-in/$file not found"
        exit 1
    fi
done

# Test 6: Verify size optimization config
echo "[Test 6] Checking size optimization config..."
if [ -f "$SCRIPT_DIR/debian12-size-config.sh" ]; then
    echo "  ✓ debian12-size-config.sh exists"
    if grep -q "SKIP_DEBUG\|SKIP_TESTS" "$SCRIPT_DIR/debian12-size-config.sh"; then
        echo "  ✓ Size optimization flags found"
    else
        echo "  ✗ Size optimization flags not found"
        exit 1
    fi
else
    echo "  ✗ debian12-size-config.sh not found"
    exit 1
fi

# Test 7: Check boost dependency
echo "[Test 7] Checking boost dependency..."
if [ -d "$SOURCE_DIR/extra/boost/boost_1_77_0" ]; then
    echo "  ✓ Boost 1.77.0 found in extra/boost/"
else
    echo "  ⚠ Boost not found (will be downloaded during build)"
fi

echo ""
echo "=== All Tests Passed ==="
echo ""
echo "Configuration is valid for Debian 12 package building."
echo "To build packages, run:"
echo "  cd $SCRIPT_DIR"
echo "  ./build-debian12-package.sh --install-deps"
