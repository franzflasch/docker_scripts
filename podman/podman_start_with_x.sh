#!/bin/bash

set -e

print_usage() {
   echo "usage: $0 -i <podman_image> -u <username> -o <optional_podman_args>"
   echo "example call:"
   echo "./podman_start_with_x.sh -i ubuntu24_04_dev_image:1 -u ${USER} -o \"-v/home/franz:/working_dir --privileged\" --rm --ssh_mount --pulse_audio"
   echo "use this as optional_podman_arg to enable support for tun/tap devices in podman:"
   echo "--cap-add=NET_ADMIN --device /dev/net/tun"
   echo ""
   echo "Options:"
   echo "-u             username within podman image"
   echo "-i             podman image to take"
   echo "-o             optional podman arguments e.g. \"-v<some-dir>:<some-dir>\""
   echo "-r             auto remove podman container after exit"
   echo "--ssh          map SSH agent socket into container, so that host ssh-keys can be used within podman container,"
   echo "               this needs a running ssh-agent to work - start with [ eval \"\$(ssh-agent -s)\" ]"
   echo "--ssh_mount    mount ~/.ssh into podman container"
   echo "--pulse_audio  enable shared pulse audio support"
   echo "--rootless     run in rootless mode (default for podman)"
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
      PODMAN_IMAGE="$2"
      shift # past argument
      shift # past value
      ;;
      -u|--user)
      PODMAN_USER="$2"
      shift # past argument
      shift # past value
      ;;
      -o|--optargs)
      OPT_PODMAN_ARGS="$2"
      shift # past argument
      shift # past value
      ;;
      -r|--rm)
      REMOVE_FLAG="--rm"
      shift # past argument
      ;;
      --ssh)
      ssh_auth_sock_file=$(dirname $SSH_AUTH_SOCK)/$(basename $SSH_AUTH_SOCK)
      PODMAN_SSH_OPTS="-v $ssh_auth_sock_file:$ssh_auth_sock_file -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
      shift
      ;;
      --ssh_mount)
      PODMAN_SSH_OPTS="-v ${HOME}/.ssh:/home/${PODMAN_USER}/.ssh:ro"
      shift # past argument
      ;;
      --pulse_audio)
      PODMAN_PULSE_AUDIO_OPTS="-e PULSE_SERVER=unix:/tmp/pulseaudio.socket \
	                       -e PULSE_COOKIE=/tmp/pulseaudio.cookie \
	                       -v /tmp/podman-${cid}/pulseaudio.socket:/tmp/pulseaudio.socket \
	                       -v /tmp/podman-${cid}/pulseaudio.client.conf:/etc/pulse/client.conf"
      shift
      ;;
      --rootless)
      ROOTLESS_MODE=true
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

if [ -z ${PODMAN_IMAGE+x} ]; then print_usage; fi

echo "Starting image $PODMAN_IMAGE with the following options:"
echo PODMAN_USER      = "${PODMAN_USER}"
echo OPT_PODMAN_ARGS  = "${OPT_PODMAN_ARGS}"
echo REMOVE_FLAG      = "${REMOVE_FLAG}"
echo PODMAN_SSH_OPTS  = "${PODMAN_SSH_OPTS}"
echo ROOTLESS_MODE    = "${ROOTLESS_MODE}"

if [ ! -z "$PODMAN_PULSE_AUDIO_OPTS" ]
then
	mkdir -p /tmp/podman-${cid}

cat << EOF > /tmp/podman-${cid}/pulseaudio.client.conf
default-server = unix:/tmp/pulseaudio.socket
# Prevent a server running in the container
autospawn = no
daemon-binary = /bin/true
# Prevent the use of shared memory
enable-shm = false
EOF

	pactl_id=$(pactl load-module module-native-protocol-unix socket=/tmp/podman-${cid}/pulseaudio.socket)
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
podman run --name ${cid} -it $REMOVE_FLAG\
           --userns=keep-id \
           --user=$PODMAN_USER \
           -e DISPLAY=$DISPLAY \
           -v /tmp/.X11-unix:/tmp/.X11-unix \
           --device /dev/dri \
           --group-add $(getent group audio | cut -d: -f3) \
           --device /dev/snd \
           -v /run/user/$(id -u)/:/run/user/$(id -u)/ \
           -v /run/dbus/:/run/dbus/ \
           -v /dev/shm:/dev/shm \
	   $PODMAN_PULSE_AUDIO_OPTS \
           $PODMAN_SSH_OPTS \
           $OPT_PODMAN_ARGS \
           $PODMAN_IMAGE

set -e


if [ ! -z "$PODMAN_PULSE_AUDIO_OPTS" ]
then
	pactl unload-module ${pactl_id}
	rm -rf /tmp/podman-${cid}
fi