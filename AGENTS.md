# AGENTS.md

This repository contains container scripts and containerfiles for development environments. This file provides guidance for agentic coding agents working in this repository.

## Repository Overview

This is a collection of personal container scripts and containerfiles for creating development environments across different Linux distributions. The repository has migrated from Docker to Podman:

- **Podman images** for various Ubuntu/Debian/Manjaro versions (primary)
- **Docker images** for legacy compatibility (deprecated)
- Shell scripts for container management
- X11 forwarding support for graphical applications
- Audio support via ALSA and PulseAudio

## Build Commands

### Podman Images (Primary)
Build Podman images using the standard podman build command:

```bash
# Build with user-specific arguments
podman build --build-arg USER_NAME=$USER --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t <image_tag> -f <podmanfile> .

# Example for Ubuntu 24.04
podman build --build-arg USER_NAME=$USER --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t ubuntu24_04_dev_image:1 -f podman/podmanfiles/ubuntu24_04_dev_image.podmanfile .
```

### Docker Images (Deprecated)
Build Docker images using the legacy docker setup (not maintained):

```bash
# Legacy Docker build (deprecated)
docker build --build-arg USER_NAME=$USER --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t <image_tag> -f docker/dockerfiles/<dockerfile> .
```

### Shell Scripts
The shell scripts are executable and should be run directly:

```bash
# Podman scripts (primary)
chmod +x podman/podman_start_with_x.sh
./podman/podman_start_with_x.sh -i ubuntu24_04_dev_image:1 -u $USER -o "--net=host" --rm

# Docker scripts (deprecated)
chmod +x docker/docker_start_with_x.sh
./docker/docker_start_with_x.sh -i ubuntu24_04_dev_image:1 -u $USER -o "--net=host" --rm
```

## Testing

This repository does not have formal test suites. Testing is done by:

1. Building Podman images successfully
2. Running containers and verifying functionality
3. Testing X11 forwarding with graphical applications
4. Verifying audio support with ALSA/PulseAudio

To test a single Podmanfile build:
```bash
podman build --build-arg USER_NAME=testuser --build-arg UID=1000 --build-arg GID=1000 -t test_image -f podman/podmanfiles/<podmanfile> .
```

## Code Style Guidelines

### Shell Scripts (.sh files)
- Use `#!/bin/bash` shebang
- Use `set -e` for error handling
- Use `set +e`/`set -e` blocks when commands might fail intentionally
- Function names use snake_case: `print_usage()`
- Variable names use UPPER_CASE for constants/environment variables
- Use 4-space indentation (no tabs)
- Quote variables: `"$VAR"` not `$VAR`
- Use `[[ ]]` for conditional tests instead of `[ ]`

### Containerfiles (Podmanfiles/Dockerfiles)
- Start with build instruction comment:
  ```dockerfile
  # Build with:
  # podman build --build-arg USER_NAME=$USER --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t <container_image_tag> -f <this_file_name> .
  ```
- Use specific base image versions (e.g., `ubuntu:24.04`)
- Set ENV variables early:
  ```dockerfile
  ENV LANG en_US.UTF-8 
  ENV LC_ALL en_US.UTF-8
  ENV DEBIAN_FRONTEND=noninteractive
  ```
- Use ARG for build-time arguments
- Combine related RUN commands with `&&` for efficiency
- Use proper user management with UID/GID matching host system

### File Organization
- **Podman scripts**: Go in `podman/` directory
- **Docker scripts**: Go in `docker/` directory (deprecated)
- **Podmanfiles**: Go in `podman/podmanfiles/` directory
- **Dockerfiles**: Go in `docker/dockerfiles/` directory (deprecated)
- Use descriptive naming: `<distro>_<version>_<purpose>.podmanfile` or `.dockerfile`
- Example: `ubuntu24_04_dev_image.podmanfile`

### Error Handling
- Shell scripts should use `set -e` for strict error handling
- Check for required parameters before execution
- Provide usage functions with `-h/--help` support
- Gracefully handle missing optional features

### Documentation
- Include usage examples in shell script comments
- Document container build requirements in containerfile headers
- Update README.md with new features or breaking changes
- Include parameter descriptions in help text

### Security
- Use `--rm` flag for auto-cleanup when appropriate
- Avoid running containers as root when possible
- Use read-only mounts for sensitive directories (e.g., `.ssh:ro`)
- Follow principle of least privilege for container capabilities
- Podman runs rootless by default (enhanced security)

### Naming Conventions
- **Podman images**: `<distro>_<version>_<purpose>:<version_number>`
- **Docker images**: Same format (deprecated)
- **Shell scripts**: `<purpose>_<optional>.sh` (e.g., `podman_start_with_x.sh`)
- **Variables**: `UPPER_CASE` for environment/constants, `lower_case` for local variables

### Import/Source Guidelines
- Shell scripts should not source other files (keep self-contained)
- Containerfiles should use official base images
- Avoid external dependencies unless absolutely necessary

## Podman-Specific Guidelines

### Rootless Operation
- Podman runs rootless by default - no need for sudo
- File permissions work better with host UID/GID mapping
- Audio and X11 forwarding work without special privileges

### Build Context
- Use `.podmanfile` extension to distinguish from Dockerfiles
- Build commands are compatible with Docker but use `podman` instead
- Podman supports Dockerfile format natively

### Runtime Differences
- Use `podman run` instead of `docker run`
- Podman has better systemd integration
- Podman supports pods for container groups
- No daemon required - more lightweight

## Common Patterns

### User Management in Containerfiles
```dockerfile
ARG USER_NAME=testuser
ARG UID=1000
ARG GID=1000

# Delete existing user/group if they exist
RUN if id -u $UID >/dev/null 2>&1; then \
        userdel -r $(getent passwd $UID | cut -d: -f1); \
    fi
RUN if getent group $GID >/dev/null 2>&1; then \
        groupdel $(getent group $GID | cut -d: -f1); \
    fi

# Create user with host UID/GID
RUN groupadd -g $GID -o $USER_NAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $USER_NAME -p '*'
RUN usermod -aG sudo $USER_NAME
USER $USER_NAME
```

### Parameter Parsing in Shell Scripts
```bash
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--image)
            PODMAN_IMAGE="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done
```

### X11 and Audio Support Pattern
```bash
# X11 forwarding
-e DISPLAY=$DISPLAY \
-v /tmp/.X11-unix:/tmp/.X11-unix \
--device /dev/dri \

# Audio support
--group-add $(getent group audio | cut -d: -f3) \
--device /dev/snd \
```

## Migration from Docker

When working with this repository:

1. **Prefer Podman**: Use `podman/` directory and files for new development
2. **Docker compatibility**: Docker setup exists but is deprecated
3. **Command substitution**: Replace `docker` with `podman` in most cases
4. **File extensions**: Use `.podmanfile` for new container files
5. **Rootless benefits**: Podman runs without root by default

## License

This project is licensed under GPL v3. All new code should include appropriate license headers.