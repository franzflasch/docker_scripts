#!/bin/bash

set -e

print_usage() {
   echo "usage: $0 <docker_image> <username> <host_shared_dir> <docker_shared_dir> <optional_docker_args>"
   echo "example call:"
   echo "./docker_start_with_x.sh -i ubuntu18_04_3dprinting:1 -u franz -o \"-v /home/franz/:/working_dir --device /dev/ttyUSB0\""
   echo "use this as optional_docker_arf to enable support for tun/tap devices in docker:"
   echo "--cap-add=NET_ADMIN --device /dev/net/tun"
   exit 1
}

# Parse commandline parameters
POSITIONAL=()
while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
      -i|--image)
      DOCKER_IMAGE="$2"
      shift # past argument
      shift # past value
      ;;
      -u|--user)
      DOCKER_USER="$2"
      shift # past argument
      shift # past value
      ;;
      -o|--optargs)
      OPT_DOCKER_ARGS="$2"
      shift # past argument
      shift # past value
      ;;
      -r|--rm)
      REMOVE_FLAG="--rm"
      shift # past argument
      ;;
      -h|--help)
      print_usage
      ;;
      *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -z ${DOCKER_IMAGE+x} ]; then print_usage; fi

echo "Starting image $DOCKER_IMAGE with the following options:"
echo DOCKER_USER      = "${DOCKER_USER}"
echo OPT_DOCKER_ARGS  = "${OPT_DOCKER_ARGS}"
echo REMOVE_FLAG      = "${REMOVE_FLAG}"

docker run -ti $REMOVE_FLAG\
           --user=$DOCKER_USER \
           -e DISPLAY=$DISPLAY \
           -v /tmp/.X11-unix:/tmp/.X11-unix \
           --group-add $(getent group audio | cut -d: -f3) \
           --device /dev/snd \
           --device /dev/dri \
           -v /run/user/$(id -u)/pulse:/run/user/$(id -u)/pulse \
           -v /run/dbus/:/run/dbus/ \
           -v /dev/shm:/dev/shm \
           $OPT_DOCKER_ARGS \
           $DOCKER_IMAGE
