#!/bin/bash
set -euo pipefail

echo "Building Lambda deployment package..."
docker run --rm \
  -v "$PWD":/workspace \
  -w /workspace \
  --entrypoint /bin/bash \
  public.ecr.aws/lambda/python:3.13 \
  -c '
    set -euo pipefail
    rm -rf dist lambda-package.zip
    mkdir -p dist

    # Ensure zip is available
    microdnf install -y zip >/dev/null

    # Install Python dependencies for Linux/arm64
    pip install --upgrade pip >/dev/null
    pip install -r requirements.txt -t dist/ --no-cache-dir >/dev/null

    # Copy source package
    cp -r src dist/

    # Package
    cd dist && zip -r ../lambda-package.zip . >/dev/null
  '

echo "✅ Lambda package built: $(ls -lh lambda-package.zip | awk '{print $5}')"
