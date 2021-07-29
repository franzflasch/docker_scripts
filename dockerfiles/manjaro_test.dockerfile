# Build with:
# docker build --build-arg USER_NAME=$USER --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t <docker_image_tag> -f <this_file_name> .

FROM manjarolinux/base:latest

ENV LANG en_US.UTF-8 
ENV LC_ALL en_US.UTF-8

ARG USER_NAME=testuser
ARG UID=1000
ARG GID=1000

RUN pacman -Syu --noconfirm sudo git fish base-devel trizen wget

RUN userdel builder
RUN groupadd -g $GID -o $USER_NAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $USER_NAME -p '*'
RUN groupadd sudo
RUN usermod -aG sudo $USER_NAME
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER $USER_NAME

# Install oh-my-bash with agnoster theme
RUN cd $HOME && git clone https://github.com/powerline/fonts.git fonts && cd fonts && ./install.sh && rm -rf $HOME/fonts
RUN bash -c "$(wget https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh -O -)"
RUN sed -i 's/^OSH_THEME/#&/' /home/$USER_NAME/.bashrc
RUN sed -i '1iDEFAULT_USER="non-existing-user"' /home/$USER_NAME/.bashrc
RUN sed -i '1iOSH_THEME="agnoster"' /home/$USER_NAME/.bashrc

