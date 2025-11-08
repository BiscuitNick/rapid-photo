#!/bin/bash
# Build Lambda package with psycopg2 compiled for Linux

echo "Building Lambda package with psycopg2 from source..."
docker run --rm \
  -v "$PWD":/workspace \
  -w /workspace \
  public.ecr.aws/lambda/python:3.13 \
  bash -c '
    rm -rf dist lambda-package.zip
    mkdir -p dist
    
    # Install PostgreSQL development libraries
    yum install -y postgresql-devel gcc python3-devel -q
    
    # Install dependencies (psycopg2 will be built from source)
    pip install boto3 Pillow python-dotenv typing-extensions -t dist/ --upgrade -q
    
    # Build psycopg2 from source
    pip install psycopg2==2.9.9 -t dist/ --no-binary psycopg2 -q
    
    # Copy source code
    cp -r src/* dist/
    
    # Create package
    cd dist && zip -r ../lambda-package.zip . -q
  '

echo "✅ Lambda package built: $(ls -lh lambda-package.zip | awk '{print $5}')"
