# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automated builds and testing.

## Available Workflows

### Build Debian 12 Packages

**File:** `build-debian12-packages.yml`

Automatically builds Debian 12 packages for AliSQL.

#### Triggers

- **Push**: Automatically runs on push to `main`, `master`, or `develop` branches
- **Pull Request**: Runs on PRs targeting `main` or `master` branches
- **Manual**: Can be triggered manually via GitHub Actions UI with build type selection

#### Manual Trigger Options

When triggering manually, you can choose the build type:
- **minimal** (default) - ~200MB packages, fastest build
- **with-tests** - ~700MB packages, includes test suite
- **full** - ~2.5GB packages, includes everything (tests + debug symbols)

#### Jobs

1. **build-debian12**
   - Builds Debian 12 packages
   - Frees up disk space for large builds
   - Installs dependencies automatically
   - Uploads built packages as artifacts (retained 30 days)
   - Generates build summary

2. **validate-config**
   - Validates packaging configuration
   - Runs validation tests
   - Ensures build scripts are correct

#### Artifacts

Built packages are uploaded as artifacts and can be downloaded from:
- GitHub Actions run page → "Artifacts" section
- Artifact name format: `debian12-packages-{build_type}-{commit_sha}`
- Retention: 30 days

#### Usage

##### Automatic Builds

Push to any monitored branch:
```bash
git push origin main
```

##### Manual Builds

1. Go to repository → Actions → "Build Debian 12 Packages"
2. Click "Run workflow"
3. Select branch and build type
4. Click "Run workflow"

#### Build Times (Approximate)

| Build Type | Time | Package Size |
|------------|------|--------------|
| Minimal | 30-45 min | ~200 MB |
| With Tests | 45-60 min | ~700 MB |
| Full | 60-90 min | ~2.5 GB |

*Times vary based on GitHub Actions runner load*

#### Disk Space Management

The workflow automatically frees up ~10GB of disk space by removing:
- .NET SDK (~2GB)
- GHC Haskell compiler (~3GB)
- Boost libraries (~2GB)
- APT cache (~1GB)

This ensures enough space for the MySQL build process.

#### Troubleshooting

##### Build Fails with "No space left on device"

The workflow already frees up space. If still failing:
1. Reduce build scope (use `minimal` instead of `full`)
2. Check if CMake cache is too large
3. Verify source checkout is complete

##### Packages Not Uploaded

Check the workflow run for:
- Build errors in the build step
- File paths (packages should be in `../*.deb` or `*.deb`)
- `if-no-files-found: error` will fail the step if no packages exist

##### Dependency Installation Fails

The `--install-deps` flag should handle all dependencies. If it fails:
1. Check Ubuntu 24.04 package availability
2. Verify network connectivity
3. Check for apt repository issues

## Adding New Workflows

To add new workflows:

1. Create a new `.yml` file in this directory
2. Follow GitHub Actions syntax
3. Use descriptive job and step names
4. Add appropriate triggers
5. Document in this README

## Related Documentation

- **Build Script**: `../packaging/build-debian12-package.sh`
- **Quick Start**: `../packaging/DEBIAN12_QUICKSTART.md`
- **Full Guide**: `../packaging/DEBIAN12_BUILD.md`
- **CI/CD Examples**: `../packaging/CI_CD_EXAMPLES.md`

## Status Badge

Add to your README to show build status:

```markdown
![Build Debian 12 Packages](https://github.com/fkpwolf/AliSQL/actions/workflows/build-debian12-packages.yml/badge.svg)
```

## Support

For issues with GitHub Actions:
1. Check workflow run logs
2. Review the build script documentation
3. Open an issue on GitHub
