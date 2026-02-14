# AliSQL Debian 12 Package Size Comparison

This document shows the expected package sizes for different build configurations.

## Size Comparison Table

| Build Configuration | Core Packages | Test Packages | Debug Symbols | Total Size |
|---------------------|---------------|---------------|---------------|------------|
| **Minimal (Default)** | 150-200 MB | - | - | **~200 MB** |
| With Tests | 150-200 MB | 400-500 MB | - | **~700 MB** |
| With Debug | 150-200 MB | - | 1-1.5 GB | **~1.7 GB** |
| Full Build | 150-200 MB | 400-500 MB | 1-1.5 GB | **~2.5 GB** |

## Package Breakdown (Minimal Build)

Individual package sizes in the minimal configuration:

| Package | Size | Description |
|---------|------|-------------|
| mysql-community-server | ~80-100 MB | Server binary and utilities |
| mysql-community-client | ~30-40 MB | Client tools |
| mysql-community-server-core | ~70-90 MB | Core server binaries |
| mysql-community-client-core | ~25-35 MB | Core client binaries |
| mysql-common | ~5-10 MB | Shared configuration |
| libmysqlclient21 | ~15-20 MB | Client library |
| libmysqlclient-dev | ~10-15 MB | Development headers |
| mysql-community-client-plugins | ~5-10 MB | Client plugins |

**Total Core Packages: ~150-200 MB**

## Excluded Packages (Minimal Build)

These packages are **not built** in the minimal configuration to save space:

| Package | Size | Reason |
|---------|------|--------|
| mysql-community-test | ~400-500 MB | Test suite only needed for development |
| mysql-community-server-debug | ~200-300 MB | Debug binaries only needed for debugging |
| mysql-community-test-debug | ~500-600 MB | Debug test binaries |
| *-dbgsym packages | ~1-1.5 GB | Debug symbols only needed for debugging |

**Total Excluded: ~2-3 GB**

## Size Optimization Techniques

The minimal build achieves size reduction through:

1. **No Debug Symbols** (saves ~1-1.5 GB)
   - Compiled without -g flag
   - No separate dbgsym packages
   
2. **No Test Suite** (saves ~400-500 MB)
   - mysql-test directory excluded
   - Test binaries not built
   
3. **Compiler Optimization** (saves ~50-100 MB)
   - `-Os` flag for size optimization
   - Dead code elimination
   - Binary stripping
   
4. **Minimal Dependencies** (saves ~50-100 MB)
   - Only essential runtime dependencies
   - Development packages separate

## Build Commands for Different Sizes

### Minimal (200 MB)
```bash
./packaging/build-debian12-package.sh
```

### With Tests (700 MB)
```bash
./packaging/build-debian12-package.sh --with-tests
```

### With Debug (1.7 GB)
```bash
./packaging/build-debian12-package.sh --with-debug
```

### Full Build (2.5 GB)
```bash
./packaging/build-debian12-package.sh --full-build --with-debug --with-tests
```

### Ultra-Minimal (150 MB)
```bash
source packaging/debian12-size-config.sh
./packaging/build-debian12-package.sh
```

## Installation Size

After installation, the packages consume different amounts of disk space:

| Configuration | Installed Size |
|---------------|----------------|
| Minimal | ~500-700 MB |
| With Tests | ~1.5-2 GB |
| With Debug | ~3-4 GB |
| Full | ~5-6 GB |

*Note: Installed size is larger than package size due to decompression and additional runtime files*

## Disk Space Requirements

Build process requires additional temporary space:

| Phase | Space Needed |
|-------|--------------|
| Source Code | ~500 MB |
| Build Artifacts | ~3-5 GB |
| Final Packages | See table above |
| **Total for Build** | **~5-10 GB** |

## Recommendations

### For Production Servers
Use the **minimal build** (default):
- Small package size for efficient distribution
- Only includes necessary runtime components
- Faster installation
- Lower disk usage

### For Development
Use the **with-tests** build:
- Includes test suite for validation
- Reasonable size compromise
- Useful for regression testing

### For Debugging Issues
Use the **with-debug** build:
- Includes debug symbols
- Enables detailed debugging
- Use only when needed

### For Development + Testing
Use the **full build**:
- All components included
- Maximum flexibility
- Largest size

## Additional Size Savings

For even smaller packages, you can:

1. **Strip additional binaries**
   ```bash
   strip --strip-unneeded /usr/sbin/mysqld
   ```

2. **Remove documentation**
   ```bash
   rm -rf /usr/share/doc/mysql-*
   rm -rf /usr/share/man/man*/mysql*
   ```

3. **Compress with UPX** (use carefully)
   ```bash
   upx --best /usr/sbin/mysqld
   ```

*Note: Stripping and compression should be done carefully as they may affect debugging and troubleshooting*

## Conclusion

The **minimal build** (default) provides the best balance of:
- ✓ Small package size (~200 MB)
- ✓ Fast download and installation
- ✓ Complete runtime functionality
- ✓ Production-ready

Choose other configurations based on specific needs.
