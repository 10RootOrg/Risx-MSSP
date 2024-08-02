#!/bin/bash

SETUP_DIR_NAME="setup_platform"
RESULT_FILENAME="self_extracted.sh"
DOCKER_IMAGES_DIR="docker"

SETUP_DIR="$(dirname $(pwd)$(dirname $0))/${SETUP_DIR_NAME}"
PACKAGE_DIR=$(mktemp -d)

echo ">>> Archiving content of ${SETUP_DIR}"
rsync -az "${SETUP_DIR}/" "${PACKAGE_DIR}/"

echo ">>> Searching for docker images in *Dockerfile"
declare -a images
for dockerfile in $(find "${PACKAGE_DIR}" -type f -name "*Dockerfile" -print)
do
  for from in "$(grep '^FROM' "${dockerfile}")"
  do
    images="${images[@]} $(echo ${from} | sed -nEe 's/^FROM[[:space:]]+//p')"
  done
done

echo ">>> Searching for docker images in docker-compose files"
for compose in $(find "${PACKAGE_DIR}" -type f -name "docker-compose.y*" -print)
do
  for image in $(sed -nEe 's/^[[:space:]]+image://gp' "${compose}")
  do
    ver=$(echo "${image}" | cut -d':' -f 2)
    if [[ $(echo "${ver}" | grep -v '\$') ]]
    then
      images="${images[@]} $image"
    fi
  done
done

echo ">>> Pulling and saving images to ${DOCKER_IMAGES_DIR}"
mkdir -p "${PACKAGE_DIR}/${DOCKER_IMAGES_DIR}"
for image in $(echo "${images[@]}" | sort | uniq)
do
  safe_name=$(echo "${image}" | sed -nEe 's/\//_/gp')
  docker pull "${image}"
  docker image save -o "${PACKAGE_DIR}/${DOCKER_IMAGES_DIR}/${safe_name}.tar" "${image}"
done

echo ">>> Creating self-extracting shell script"
# NB. Keep last empty newline! Wouldn't work without it!
cat <<EOF > "${RESULT_FILENAME}"
#!/bin/bash

sed -e '1,/END_'OF_SCRIPT/d "\$0" | tar -xzf -; exit 0

END_OF_SCRIPT
EOF
tar -cz -C "${PACKAGE_DIR}" ./ >> "${RESULT_FILENAME}"

rm -rf ${PACKAGE_DIR}
