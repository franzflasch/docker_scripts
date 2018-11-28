# Build with:
# docker build --build-arg USER_NAME=$USER --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t <docker_image_tag> -f <this_file_name> .

FROM debian:9

ARG USER_NAME=testuser
ARG UID=1000
ARG GID=1000

RUN apt-get update && apt-get install -y sudo dbus-x11 build-essential cmake locales git
RUN apt-get install -y gnome-terminal

# fix locales
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen

RUN groupadd -g $GID -o $USER_NAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $USER_NAME -p '*'
RUN usermod -aG sudo $USER_NAME
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER $USER_NAME

# Install bash agnoster theme
RUN cd $HOME && git clone https://github.com/powerline/fonts.git fonts && cd fonts && ./install.sh && rm -rf $HOME/fonts
RUN cd $HOME && mkdir -p .bash/themes/agnoster-bash && git clone https://github.com/franzflasch/agnoster-bash.git .bash/themes/agnoster-bash

RUN echo 'export THEME=$HOME/.bash/themes/agnoster-bash/agnoster.bash\n\
if [[ -f $THEME ]]; then\n\
export DEFAULT_USER=`whoami`\n\
source $THEME\n\
fi\n'\
>> $HOME/.bashrc
