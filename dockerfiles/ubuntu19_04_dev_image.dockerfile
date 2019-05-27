# Build with:
# docker build --build-arg USER_NAME=$USER --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t <docker_image_tag> -f <this_file_name> .

FROM ubuntu:19.04

ARG USER_NAME=testuser
ARG UID=1000
ARG GID=1000

RUN apt update 
RUN apt install -y sudo
RUN apt install -y dbus-x11
RUN apt install -y build-essential
RUN apt install -y cmake
RUN apt install -y locales

RUN groupadd -g $GID -o $USER_NAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $USER_NAME -p '*'
RUN usermod -aG sudo $USER_NAME
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER $USER_NAME
