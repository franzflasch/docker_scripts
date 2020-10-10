#!/bin/bash

set -e

print_usage() {
   echo "usage: $0 -i <docker_image> -u <username> -o <optional_docker_args>"
   echo "example call:"
   echo "./docker_start_with_x.sh -i ubuntu20_04_dev_image:2 -u ${USER} -o \"-v/home/franz:/working_dir --privileged\" --rm --ssh_mount --pulse_audio"
   echo "use this as optional_docker_arg to enable support for tun/tap devices in docker:"
   echo "--cap-add=NET_ADMIN --device /dev/net/tun"
   echo ""
   echo "Options:"
   echo "-u             username within docker image"
   echo "-i             docker image to take"
   echo "-o             optional docker arguments e.g. \"-v<some-dir>:<some-dir>\""
   echo "-r             auto remove docker container after exit"
   echo "--ssh          map SSH agent socket into container, so that host ssh-keys can be used within docker container,"
   echo "               this needs a running ssh-agent to work - start with [ eval \"\$(ssh-agent -s)\" ]"
   echo "--ssh_mount    mount ~/.ssh into docker container"
   echo "--pulse_audio  enable shared pulse audio support"
   exit 1
}

# Generate container name manually as we need it for pulse audio
cid=$(shuf -i1-1000000 -n1 | sha256sum | awk '{print $1}' | cut -c1-8)

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
      --ssh)
      ssh_auth_sock_file=$(dirname $SSH_AUTH_SOCK)/$(basename $SSH_AUTH_SOCK)
      DOCKER_SSH_OPTS="-v $ssh_auth_sock_file:$ssh_auth_sock_file -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
      shift
      ;;
      --ssh_mount)
      DOCKER_SSH_OPTS="-v ${HOME}/.ssh:/home/${DOCKER_USER}/.ssh:ro"
      shift # past argument
      ;;
      --pulse_audio)
      DOCKER_PULSE_AUDIO_OPTS="-e PULSE_SERVER=unix:/tmp/pulseaudio.socket \
	                       -e PULSE_COOKIE=/tmp/pulseaudio.cookie \
	                       -v /tmp/docker-${cid}/pulseaudio.socket:/tmp/pulseaudio.socket \
	                       -v /tmp/docker-${cid}/pulseaudio.client.conf:/etc/pulse/client.conf"
      shift
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
echo DOCKER_SSH_OPTS  = "${DOCKER_SSH_OPTS}"

if [ ! -z "$DOCKER_PULSE_AUDIO_OPTS" ]
then
	mkdir -p /tmp/docker-${cid}

cat << EOF > /tmp/docker-${cid}/pulseaudio.client.conf
default-server = unix:/tmp/pulseaudio.socket
# Prevent a server running in the container
autospawn = no
daemon-binary = /bin/true
# Prevent the use of shared memory
enable-shm = false
EOF

	pactl_id=$(pactl load-module module-native-protocol-unix socket=/tmp/docker-${cid}/pulseaudio.socket)
fi

## Graphical SECTION
# -e DISPLAY=$DISPLAY \
# -v /tmp/.X11-unix:/tmp/.X11-unix \
# --device /dev/dri \

## ALSA Sound support
# --group-add $(getent group audio | cut -d: -f3) \
# --device /dev/snd \

## This is needed by some applications e.g. gnome-terminal:
# -v /run/dbus/:/run/dbus/ \
# -v /dev/shm:/dev/shm \

set +e
docker run --name ${cid} -it $REMOVE_FLAG\
           --user=$DOCKER_USER \
           -e DISPLAY=$DISPLAY \
           -v /tmp/.X11-unix:/tmp/.X11-unix \
           --device /dev/dri \
           --group-add $(getent group audio | cut -d: -f3) \
           --device /dev/snd \
           -v /run/user/$(id -u)/:/run/user/$(id -u)/ \
           -v /run/dbus/:/run/dbus/ \
           -v /dev/shm:/dev/shm \
	   $DOCKER_PULSE_AUDIO_OPTS \
           $DOCKER_SSH_OPTS \
           $OPT_DOCKER_ARGS \
           $DOCKER_IMAGE

set -e


if [ ! -z "$DOCKER_PULSE_AUDIO_OPTS" ]
then
	pactl unload-module ${pactl_id}
	rm -rf /tmp/docker-${cid}
fi

