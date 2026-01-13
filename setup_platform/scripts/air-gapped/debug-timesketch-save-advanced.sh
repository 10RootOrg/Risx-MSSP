#!/bin/bash
set -x

echo "=== Checking Timesketch image format ==="
sudo docker inspect us-docker.pkg.dev/osdfir-registry/timesketch/timesketch:20251219 --format='{{.RepoDigests}}'
sudo docker inspect us-docker.pkg.dev/osdfir-registry/timesketch/timesketch:20251219 --format='{{.GraphDriver}}'

echo ""
echo "=== Checking layer sizes in Docker storage ==="
for layer in $(sudo docker inspect us-docker.pkg.dev/osdfir-registry/timesketch/timesketch:20251219 --format='{{range .RootFS.Layers}}{{println .}}{{end}}'); do
    echo "Layer: $layer"
    sudo du -sh /var/lib/docker/overlay2/*/diff 2>/dev/null | grep -v "^0" | head -5
done

echo ""
echo "=== Trying docker export instead of save ==="
CONTAINER_ID=$(sudo docker create us-docker.pkg.dev/osdfir-registry/timesketch/timesketch:20251219)
echo "Created container: $CONTAINER_ID"
sudo docker export $CONTAINER_ID -o /tmp/timesketch_export.tar
echo "Export size:"
ls -lh /tmp/timesketch_export.tar
sudo docker rm $CONTAINER_ID

echo ""
echo "=== Trying save with compression ==="
sudo docker save us-docker.pkg.dev/osdfir-registry/timesketch/timesketch:20251219 | gzip > /tmp/timesketch_compressed.tar.gz
ls -lh /tmp/timesketch_compressed.tar.gz

echo ""
echo "=== Checking if issue is specific to destination ==="
sudo docker save us-docker.pkg.dev/osdfir-registry/timesketch/timesketch:20251219 -o /var/tmp/timesketch_test_vartmp.tar
ls -lh /var/tmp/timesketch_test_vartmp.tar

echo ""
echo "=== Inspecting saved tar contents ==="
tar -tzf airgap-bundle/docker-images/us-docker.pkg.dev_osdfir-registry_timesketch_timesketch_20251219.tar | head -20

echo ""
echo "=== Comparing with working Ubuntu image ==="
echo "Ubuntu image size in Docker:"
sudo docker images ubuntu:22.04
echo "Ubuntu saved tar size:"
ls -lh airgap-bundle/docker-images/ubuntu_22.04.tar
echo "Ubuntu tar contents (first 10 lines):"
tar -tzf airgap-bundle/docker-images/ubuntu_22.04.tar | head -10
