# AliSQL Packaging

This directory contains packaging configurations and build scripts for various platforms.

## Supported Platforms

### Debian/Ubuntu
- **Debian 12 (Bookworm)** - ✅ Fully supported with optimized build
- Debian 11 (Bullseye) - Compatible
- Ubuntu 22.04 LTS - Compatible
- Ubuntu 24.04 LTS - Compatible

### RPM-based Distributions
- Fedora
- Oracle Enterprise Linux (OEL)
- SLES

### Other Platforms
- Windows (WiX installer)
- Solaris

## Quick Start - Debian 12 Packages

Build optimized, size-efficient packages for Debian 12:

```bash
cd packaging
./build-debian12-package.sh --install-deps
```

See [DEBIAN12_QUICKSTART.md](DEBIAN12_QUICKSTART.md) for quick reference or [DEBIAN12_BUILD.md](DEBIAN12_BUILD.md) for detailed guide.

## Package Size Optimization

The Debian 12 build script includes several optimizations to keep packages small:

1. **Skip Debug Packages** - Saves ~1-2GB
2. **Skip Test Packages** - Saves ~500MB  
3. **Minimal Build Configuration** - Saves ~200-300MB
4. **Compiler Optimizations** - Additional 10-20% reduction

Result: **~150-200MB** total package size vs **~2-3GB** for full build

## Directory Structure

```
packaging/
├── DEBIAN12_BUILD.md          - Detailed Debian 12 build guide
├── DEBIAN12_QUICKSTART.md     - Quick reference for Debian 12
├── build-debian12-package.sh  - Automated build script
├── debian12-size-config.sh    - Size optimization configuration
├── deb-in/                    - Debian packaging templates
│   ├── control.in            - Package control file
│   ├── rules.in              - Build rules
│   ├── CMakeLists.txt        - CMake configuration
│   └── ...                   - Other Debian files
├── rpm-*/                     - RPM packaging for various distros
├── WiX/                       - Windows installer
└── solaris/                   - Solaris packaging
```

## Documentation

- **[DEBIAN12_QUICKSTART.md](DEBIAN12_QUICKSTART.md)** - Quick start guide (TL;DR)
- **[DEBIAN12_BUILD.md](DEBIAN12_BUILD.md)** - Comprehensive Debian 12 guide
- **[deb-in/README](deb-in/README)** - Debian packaging notes

## Build Examples

### Minimal build (default)
```bash
./packaging/build-debian12-package.sh
```

### Full build with all features
```bash
./packaging/build-debian12-package.sh --full-build --with-debug --with-tests
```

### Install dependencies first
```bash
./packaging/build-debian12-package.sh --install-deps
```

### With aggressive size optimization
```bash
source packaging/debian12-size-config.sh
./packaging/build-debian12-package.sh
```

## Package Types

The build produces several package types:

### Core Packages (Always Built)
- `mysql-*-server` - Server binaries and utilities
- `mysql-*-client` - Client tools (mysql, mysqldump, etc.)
- `mysql-common` - Common configuration files
- `libmysqlclient*` - Client libraries

### Optional Packages
- `mysql-*-test` - Test suite (large)
- `mysql-*-debug` - Debug binaries (very large)  
- `mysql-*-dbgsym` - Debug symbols (very large)

## Environment Variables

Configure builds with environment variables:

```bash
# Target Debian version
DEB_CODENAME=bookworm

# Product edition (community/commercial)
DEB_PRODUCT=community

# Build directory
BUILD_DIR=/tmp/alisql-build

# Size optimization flags
SKIP_DEBUG_PACKAGES=1
SKIP_TEST_PACKAGES=1
MINIMAL_BUILD=1
```

## Contributing

When adding new packaging features:

1. Update relevant documentation
2. Test on target platform
3. Verify package sizes
4. Update this README

## Support

For packaging issues:
1. Check the relevant documentation in this directory
2. Review CMake configuration output
3. Check build logs
4. Open an issue on GitHub

## License

See [../LICENSE](../LICENSE) for license information.
