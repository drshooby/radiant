#!/bin/bash

# Build FFMPEG Lambda layer for AL2023 / Python 3.12
# Uses AWS Lambda Python 3.12 base image for compatibility

set -euo pipefail

HOST_DESKTOP="$HOME/Desktop"
ZIP_NAME="ffmpeg-layer.zip"
IMAGE="amazonlinux:2023"

if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "Error: Docker daemon is not running."
    exit 1
fi

echo "Starting build inside Docker (x86_64)..."

docker pull --platform linux/amd64 $IMAGE

docker run --rm --platform linux/amd64 -v "$HOST_DESKTOP":/host -w /tmp $IMAGE /bin/bash -c "\
  set -e; \
  dnf -y update; \
  dnf install -y gcc make autoconf automake bzip2 bzip2-devel cmake git libtool pkgconfig nasm yasm zlib-devel zip wget; \
  
  # Build x264
  echo 'Building x264...'; \
  mkdir -p /tmp/ffmpeg_build; cd /tmp/ffmpeg_build; \
  git clone --depth 1 https://code.videolan.org/videolan/x264.git; \
  cd x264; \
  ./configure --prefix=/opt --enable-static --enable-pic; \
  make -j\$(nproc); make install; \
  
  # Verify x264 installed
  if [ ! -f /opt/lib/libx264.a ]; then \
    echo 'ERROR: x264 library not found at /opt/lib/libx264.a'; \
    exit 1; \
  fi; \
  echo 'x264 installed successfully'; \
  
  # Build FFmpeg with x264
  echo 'Building FFmpeg with libx264...'; \
  cd /tmp/ffmpeg_build; \
  git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg_source; \
  cd ffmpeg_source; \
  PKG_CONFIG_PATH=/opt/lib/pkgconfig ./configure \
    --prefix=/opt \
    --disable-shared \
    --enable-static \
    --disable-doc \
    --disable-debug \
    --enable-pic \
    --enable-gpl \
    --enable-nonfree \
    --disable-ffplay \
    --enable-libx264; \
  make -j\$(nproc); make install; \
  
  # Verify FFmpeg has x264 support
  if ! /opt/bin/ffmpeg -encoders 2>&1 | grep -q libx264; then \
    echo 'ERROR: FFmpeg was built but does not have libx264 support'; \
    exit 1; \
  fi; \
  echo 'FFmpeg built successfully with libx264 support'; \
  
  cd /opt; zip -r9 /host/$ZIP_NAME bin lib; \
  echo 'FFmpeg layer with libx264 created at ~/Desktop/$ZIP_NAME'; \
"

if [ $? -eq 0 ]; then
  echo "Removing Docker image..."
  docker image rm $IMAGE || true
  echo "Build completed successfully. Layer at ~/Desktop/$ZIP_NAME"
else
  echo "Build failed. Check the output above for errors."
  exit 1
fi