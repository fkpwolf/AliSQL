# CI/CD Examples for Debian 12 Package Building

This document provides example CI/CD configurations for automatically building Debian 12 packages.

## GitHub Actions Example

Create `.github/workflows/build-debian12-packages.yml`:

```yaml
name: Build Debian 12 Packages

on:
  push:
    branches: [ main, develop ]
    tags: [ 'v*' ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build-minimal:
    name: Build Minimal Packages
    runs-on: ubuntu-24.04
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Free disk space
        run: |
          sudo rm -rf /usr/share/dotnet
          sudo rm -rf /opt/ghc
          sudo rm -rf /usr/local/share/boost
          df -h
          
      - name: Install dependencies
        run: |
          cd packaging
          ./build-debian12-package.sh --install-deps
          
      - name: Build packages
        run: |
          cd packaging
          ./build-debian12-package.sh
          
      - name: List packages
        run: |
          ls -lh ../*.deb || true
          du -ch ../*.deb || true
          
      - name: Upload packages
        uses: actions/upload-artifact@v4
        with:
          name: debian12-minimal-packages
          path: '*.deb'
          retention-days: 30
          
  build-full:
    name: Build Full Packages (with Tests)
    runs-on: ubuntu-24.04
    if: github.event_name == 'push' && startsWith(github.ref, 'refs/tags/')
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Install dependencies
        run: |
          cd packaging
          ./build-debian12-package.sh --install-deps
          
      - name: Build packages
        run: |
          cd packaging
          ./build-debian12-package.sh --with-tests
          
      - name: Upload packages
        uses: actions/upload-artifact@v4
        with:
          name: debian12-full-packages
          path: '*.deb'
          retention-days: 90
```

## GitLab CI Example

Create `.gitlab-ci.yml`:

```yaml
stages:
  - build
  - test
  - package

variables:
  DEBIAN_FRONTEND: noninteractive

build-debian12-minimal:
  stage: build
  image: debian:bookworm
  script:
    - apt-get update
    - cd packaging
    - ./build-debian12-package.sh --install-deps
    - ./build-debian12-package.sh
  artifacts:
    paths:
      - "*.deb"
    expire_in: 30 days
  only:
    - main
    - develop
    - tags

build-debian12-full:
  stage: build
  image: debian:bookworm
  script:
    - apt-get update
    - cd packaging
    - ./build-debian12-package.sh --install-deps
    - ./build-debian12-package.sh --with-tests --with-debug
  artifacts:
    paths:
      - "*.deb"
    expire_in: 90 days
  only:
    - tags

test-packages:
  stage: test
  image: debian:bookworm
  dependencies:
    - build-debian12-minimal
  script:
    - apt-get update
    - dpkg -i *.deb || apt-get install -f -y
    - systemctl start mysql
    - mysql --version
  only:
    - main
    - tags
```

## Jenkins Pipeline Example

Create `Jenkinsfile`:

```groovy
pipeline {
    agent {
        docker {
            image 'debian:bookworm'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    
    parameters {
        choice(
            name: 'BUILD_TYPE',
            choices: ['minimal', 'with-tests', 'full'],
            description: 'Package build type'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh '''
                    apt-get update
                    cd packaging
                    ./build-debian12-package.sh --install-deps
                '''
            }
        }
        
        stage('Build Packages') {
            steps {
                script {
                    def buildCmd = './build-debian12-package.sh'
                    
                    if (params.BUILD_TYPE == 'with-tests') {
                        buildCmd += ' --with-tests'
                    } else if (params.BUILD_TYPE == 'full') {
                        buildCmd += ' --with-tests --with-debug'
                    }
                    
                    sh """
                        cd packaging
                        ${buildCmd}
                    """
                }
            }
        }
        
        stage('Archive Packages') {
            steps {
                archiveArtifacts artifacts: '*.deb', fingerprint: true
            }
        }
        
        stage('Test Installation') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    dpkg -i *.deb || apt-get install -f -y
                    systemctl start mysql
                    mysql --version
                '''
            }
        }
    }
    
    post {
        success {
            echo 'Build successful!'
        }
        failure {
            echo 'Build failed!'
        }
    }
}
```

## Docker Build Example

Create `Dockerfile.debian12-builder`:

```dockerfile
FROM debian:bookworm

# Install build dependencies
RUN apt-get update && apt-get install -y \
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
    devscripts \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy source
COPY . /build/

# Build packages
RUN cd packaging && ./build-debian12-package.sh

# Extract packages to output
RUN mkdir -p /output && mv ../*.deb /output/

CMD ["ls", "-lh", "/output/"]
```

Build and run:

```bash
# Build the builder image
docker build -f Dockerfile.debian12-builder -t alisql-debian12-builder .

# Run and extract packages
docker run --rm -v $(pwd)/output:/output alisql-debian12-builder
```

## Local Build Script with Docker

Create `scripts/docker-build-debian12.sh`:

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$SOURCE_DIR/output}"

echo "Building Debian 12 packages in Docker..."

docker run --rm \
    -v "$SOURCE_DIR:/build" \
    -v "$OUTPUT_DIR:/output" \
    -w /build \
    debian:bookworm \
    bash -c '
        apt-get update && \
        cd packaging && \
        ./build-debian12-package.sh --install-deps && \
        ./build-debian12-package.sh && \
        mv ../*.deb /output/
    '

echo "Packages built and saved to: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"/*.deb
```

## Makefile Example

Create `Makefile`:

```makefile
.PHONY: debian12-minimal debian12-full debian12-test clean

debian12-minimal:
	cd packaging && ./build-debian12-package.sh

debian12-with-tests:
	cd packaging && ./build-debian12-package.sh --with-tests

debian12-full:
	cd packaging && ./build-debian12-package.sh --full-build --with-tests --with-debug

debian12-install-deps:
	cd packaging && ./build-debian12-package.sh --install-deps

debian12-test:
	bash packaging/test-debian12-config.sh

clean:
	rm -rf debian/
	rm -f ../*.deb ../*.ddeb ../*.dsc ../*.changes ../*.buildinfo
	rm -f ../install-alisql-packages.sh

help:
	@echo "AliSQL Debian 12 Package Targets:"
	@echo "  debian12-minimal        - Build minimal packages (default)"
	@echo "  debian12-with-tests     - Build with test packages"
	@echo "  debian12-full          - Build all packages"
	@echo "  debian12-install-deps  - Install build dependencies"
	@echo "  debian12-test          - Test configuration"
	@echo "  clean                  - Remove build artifacts"
```

## Automated Release Workflow

Complete GitHub Actions workflow for releases:

```yaml
name: Release Debian 12 Packages

on:
  release:
    types: [created]

jobs:
  build-and-release:
    runs-on: ubuntu-24.04
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup environment
        run: |
          cd packaging
          ./build-debian12-package.sh --install-deps
          
      - name: Build minimal packages
        run: |
          cd packaging
          ./build-debian12-package.sh
          
      - name: Build full packages
        run: |
          cd packaging
          ./build-debian12-package.sh --with-tests
          mv ../*.deb ../full/
          
      - name: Upload to release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            ../*.deb
            ../full/*.deb
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Best Practices

1. **Cache Dependencies**: Cache apt packages to speed up builds
2. **Parallel Builds**: Use `-j$(nproc)` for faster compilation
3. **Artifact Retention**: Keep minimal builds longer than full builds
4. **Test Packages**: Always test installation before release
5. **Disk Space**: Monitor disk usage, clean up between builds
6. **Build Matrix**: Test on multiple Debian/Ubuntu versions
7. **Notifications**: Set up alerts for build failures

## Troubleshooting CI/CD

### Disk Space Issues
```bash
# Free up space before build
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
docker system prune -af
```

### Timeout Issues
```bash
# Increase timeout in CI config
timeout-minutes: 180  # 3 hours
```

### Dependency Issues
```bash
# Update package lists
apt-get update
apt-get upgrade -y
```

## Security Considerations

1. **Scan packages** with tools like `lintian`
2. **Sign packages** with GPG keys
3. **Use secrets** for credentials
4. **Scan for vulnerabilities** with `trivy` or similar
5. **Limit artifact access** to authorized users

## Monitoring

Add monitoring to track:
- Build time trends
- Package sizes over time
- Build success/failure rates
- Artifact download counts

Example with Prometheus metrics:
```yaml
- name: Export metrics
  run: |
    echo "build_duration_seconds $(date +%s)" >> metrics.txt
    echo "package_size_bytes $(stat -f%z ../*.deb)" >> metrics.txt
```
