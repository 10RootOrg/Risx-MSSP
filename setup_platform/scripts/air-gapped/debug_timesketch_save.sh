#!/bin/bash
set -x  # Enable debug output

echo "=== Checking disk space ==="
df -h .

echo ""
echo "=== Inspecting image layers ==="
sudo docker inspect us-docker.pkg.dev/osdfir-registry/timesketch/timesketch:20251219 | grep -A 10 "Layers"

echo ""
echo "=== Attempting docker save with error output ==="
sudo docker save us-docker.pkg.dev/osdfir-registry/timesketch/timesketch:20251219 -o airgap-bundle/docker-images/timesketch_test.tar
echo "Exit code: $?"

echo ""
echo "=== Checking saved file size ==="
ls -lh airgap-bundle/docker-images/timesketch_test.tar

echo ""
echo "=== Trying alternative save method (stdout redirect) ==="
sudo docker save us-docker.pkg.dev/osdfir-registry/timesketch/timesketch:20251219 > airgap-bundle/docker-images/timesketch_test2.tar
echo "Exit code: $?"
ls -lh airgap-bundle/docker-images/timesketch_test2.tar

echo ""
echo "=== Testing with a different image (ubuntu) ==="
sudo docker save ubuntu:22.04 -o airgap-bundle/docker-images/ubuntu_test.tar
ls -lh airgap-bundle/docker-images/ubuntu_test.tar
