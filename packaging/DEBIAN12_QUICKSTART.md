# Debian 12 Package Quick Reference

## TL;DR - Build Minimal Packages

```bash
cd packaging
./build-debian12-package.sh --install-deps
```

Packages will be in parent directory (`../*.deb`)

## Install Packages

```bash
cd ..
sudo dpkg -i *.deb
```

## What Gets Built (Minimal Config)

✅ Core packages only (~150-200MB total):
- `mysql-community-server` - MySQL server
- `mysql-community-client` - Client tools  
- `mysql-common` - Shared files
- `libmysqlclient21` - Client library
- `libmysqlclient-dev` - Development headers

❌ Excluded to save space:
- Debug symbol packages (~1-2GB)
- Test suite packages (~500MB)
- Development server packages

## Build Options Summary

| Command | Package Size | Build Time |
|---------|--------------|------------|
| Default (minimal) | ~150-200MB | 30-45 min |
| `--with-tests` | ~500-700MB | 45-60 min |
| `--with-debug` | ~1-2GB | 60-90 min |
| `--full-build --with-debug --with-tests` | ~2-3GB | 90-120 min |

*Times are approximate on 4-core system with 8GB RAM*

## Common Issues

### "debian/ directory not found"
```bash
# Run from repository root
cd /path/to/AliSQL
./packaging/build-debian12-package.sh
```

### "Missing build dependencies"
```bash
./packaging/build-debian12-package.sh --install-deps
```

### Reduce size even more
```bash
# Use aggressive optimization
source packaging/debian12-size-config.sh
./packaging/build-debian12-package.sh
```

## Package Details

Each core package contains:

**mysql-community-server**
- `/usr/sbin/mysqld` - Server binary
- `/usr/bin/mysql_*` - Server utilities
- `/etc/mysql/` - Configuration
- systemd service files

**mysql-community-client**  
- `/usr/bin/mysql` - Command-line client
- `/usr/bin/mysqldump` - Backup tool
- `/usr/bin/mysqlimport` - Import tool
- `/usr/bin/mysqlshow` - Schema viewer

**libmysqlclient21**
- `/usr/lib/*/libmysqlclient.so.21` - Shared library

## System Requirements

- Debian 12 (Bookworm) or Ubuntu 22.04+
- 4GB RAM minimum (8GB recommended)
- 20GB free disk space for build
- 1-2GB for installed packages

## Post-Installation

```bash
# Start MySQL
sudo systemctl start mysql
sudo systemctl enable mysql

# Secure installation
sudo mysql_secure_installation

# Connect
mysql -u root -p
```

## Advanced Options

### Build for specific Debian version
```bash
DEB_CODENAME=bookworm ./packaging/build-debian12-package.sh
```

### Commercial edition
```bash
DEB_PRODUCT=commercial ./packaging/build-debian12-package.sh
```

### Custom optimization
```bash
MINIMAL_BUILD=1 \
SKIP_DEBUG_PACKAGES=1 \
SKIP_TEST_PACKAGES=1 \
./packaging/build-debian12-package.sh
```

## More Information

- Detailed guide: [DEBIAN12_BUILD.md](DEBIAN12_BUILD.md)
- Main README: [../README.md](../README.md)
- Build script: [build-debian12-package.sh](build-debian12-package.sh)
