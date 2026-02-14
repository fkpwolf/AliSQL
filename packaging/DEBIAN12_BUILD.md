# Building AliSQL Debian 12 Packages

## Quick Start

From the repository root on a Debian 12 system:

```bash
# Install dependencies and build (as root)
sudo packaging/build-debian12-package.sh --install-deps

# Or install dependencies separately, then build as a regular user
sudo packaging/build-debian12-package.sh --install-deps
# (the flag only installs deps when run alone before cmake; to split the steps
#  call --install-deps first, then run the script again without it)
packaging/build-debian12-package.sh
```

The `.deb` file will be written to `build-deb12/`.

## CI / GitHub Actions

The workflow at `.github/workflows/build-debian12-packages.yml` runs
automatically on pushes to `main`, `master`, and `develop`, as well as on
pull requests targeting those branches.  It can also be triggered manually
via **Actions → Build Debian 12 Packages → Run workflow**, with an optional
build-type selector (`Release` or `RelWithDebInfo`).

## Keeping the Package Small

The build script applies several size-reduction strategies:

| Technique | Approximate savings |
|---|---|
| `Release` build (no debug info) | ~1–1.5 GB |
| Strip ELF binaries (`strip --strip-unneeded`) | additional ~200 MB |
| Exclude MySQL test suite | ~500 MB |
| Remove static `.a` libraries | ~100–200 MB |

Together these keep the final `.deb` well under 300 MB for a typical x86-64
build, compared to 2+ GB for a full debug build with tests.

## Build Options

| Environment variable | Default | Description |
|---|---|---|
| `BUILD_TYPE` | `Release` | CMake build type |
| `JOBS` | `$(nproc)` | Parallel make jobs |
| `PACKAGE_NAME` | `alisql-server` | Name used in the `.deb` filename |
