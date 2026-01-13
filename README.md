# Container Scripts

Personal container scripts for development environments, now migrated from Docker to Podman.

## 🚨 Migration Notice

**This project has migrated from Docker to Podman.** The Docker setup is kept for compatibility but is no longer maintained. All new development and features will be focused on the Podman setup.

## Quick Start (Podman)

### Run a graphical APP in a Podman container on a remote server via SSH X11 forwarding:

1. Connect to the server via SSH with X11 forwarding enabled:
```console
ssh -X <remote_server>
```

2. Start the Podman container:
```console
./podman/podman_start_with_x.sh -i ubuntu24_04_dev_image:1 -u $USER -o "--net=host --hostname $(hostname) -v /home/$USER/.Xauthority:/home/$USER/.Xauthority -v /home/$USER/:/working_dir" --rm
```

3. You should now be able to run X apps from the Podman container and they will be displayed on the client which is connected via SSH.

## Podman Setup

### Building Images

```bash
# Build with user-specific arguments
podman build --build-arg USER_NAME=$USER --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t ubuntu24_04_dev_image:1 -f podman/podmanfiles/ubuntu24_04_dev_image.podmanfile .

# Example for Ubuntu 24.04
cd podman/podmanfiles
podman build --build-arg USER_NAME=$USER --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t ubuntu24_04_dev_image:1 -f ubuntu24_04_dev_image.podmanfile .
```

### Available Images

- `ubuntu24_04_dev_image` - Ubuntu 24.04 with development tools
- `ubuntu22_04_dev_image` - Ubuntu 22.04 with development tools  
- `ubuntu20_04_dev_image` - Ubuntu 20.04 with development tools
- `ubuntu18_04_dev_image` - Ubuntu 18.04 with development tools
- `ubuntu16_04_dev_image` - Ubuntu 16.04 with development tools
- `ubuntu19_04_dev_image` - Ubuntu 19.04 with development tools
- `ubuntu14_04_dev_image` - Ubuntu 14.04 with development tools
- `ubuntu14_04_i386_image` - Ubuntu 14.04 i386 with development tools
- `debian10_dev_image` - Debian 10 (Buster) with development tools
- `debian9_dev_image` - Debian 9 with development tools
- `manjaro_test` - Manjaro Linux with development tools

### Features

- **X11 Forwarding**: Full graphical application support
- **Audio Support**: ALSA and PulseAudio support
- **SSH Integration**: SSH agent socket mounting and SSH key sharing
- **User Mapping**: Host UID/GID mapping for seamless file permissions
- **Development Tools**: Pre-installed build-essential, cmake, git, etc.

## Docker Setup (Deprecated)

The Docker setup is kept for backward compatibility but is no longer maintained. If you need to use Docker:

```bash
# Build Docker images (deprecated)
docker build --build-arg USER_NAME=$USER --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t ubuntu24_04_dev_image:1 -f docker/dockerfiles/ubuntu24_04_dev_image.dockerfile .

# Run Docker containers (deprecated)
./docker/docker_start_with_x.sh -i ubuntu24_04_dev_image:1 -u $USER -o "--net=host" --rm
```

## Usage Examples

### Basic Usage
```bash
./podman/podman_start_with_x.sh -i ubuntu24_04_dev_image:1 -u $USER
```

### With SSH Agent Forwarding
```bash
./podman/podman_start_with_x.sh -i ubuntu24_04_dev_image:1 -u $USER --ssh
```

### With SSH Key Mounting
```bash
./podman/podman_start_with_x.sh -i ubuntu24_04_dev_image:1 -u $USER --ssh_mount
```

### With PulseAudio Support
```bash
./podman/podman_start_with_x.sh -i ubuntu24_04_dev_image:1 -u $USER --pulse_audio
```

### Combined Options
```bash
./podman/podman_start_with_x.sh -i ubuntu24_04_dev_image:1 -u $USER -o "--net=host --privileged" --ssh_mount --pulse_audio --rm
```

## Sound Configuration

### Sound via ALSA
Sound via ALSA should work if you specify the ALSA_CARD environment variable:
```console
ALSA_CARD=Generic speaker-test
```

If your application uses PulseAudio you can fake pulse via the apulse tool:
```console
ALSA_CARD=Generic apulse retroarch
```

Note: When using ALSA only one application can use the audio device at a time, otherwise it reports an error "Device busy".

## Device Mounting

### Mount devices into an already running container
Note: This only works when the container was started with "--privileged"

Example with Blackmagic debug probe (/dev/ttyACM0 and /dev/ttyACM1):
1. Start the container with the device unplugged
2. When container is started, plug the device
3. Check that the devices ttyACM0 and ttyACM1 were created on the host
4. Check the device nodes on the host:
```console
ls -la /dev/ttyACM*
```

Output will be something like:
```console
crw-rw----+ 1 root dialout 166, 0 Dec 24 08:31 /dev/ttyACM0
crw-rw----+ 1 root dialout 166, 1 Dec 24 08:31 /dev/ttyACM1
```

5. Create the device in the container using mknod:
```console
sudo mknod /dev/ttyACM0 c 166 0
sudo mknod /dev/ttyACM1 c 166 1
```

Devices should now be usable within the container.

## Podman vs Docker Advantages

- **Rootless by default**: Enhanced security without requiring root privileges
- **Systemd integration**: Better integration with modern Linux systems
- **Pod support**: Native support for container groups
- **Daemonless architecture**: More lightweight and reliable
- **Drop-in compatibility**: Most Docker commands work with Podman

## Resources

- [Podman Documentation](https://podman.io/)
- [Remote GUI app in container](http://wangkejie.me/2018/01/08/remote-gui-app-in-docker/)
- [Running graphical apps in containers](https://blog.yadutaf.fr/2017/09/10/running-a-graphical-app-in-a-docker-container-on-a-remote-server/)