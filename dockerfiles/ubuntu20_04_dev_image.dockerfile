# Build with:
# docker build --build-arg USER_NAME=$USER --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t <docker_image_tag> -f <this_file_name> .

FROM ubuntu:20.04

ENV LANG en_US.UTF-8 
ENV LC_ALL en_US.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

ARG USER_NAME=testuser
ARG UID=1000
ARG GID=1000

RUN apt update 
RUN apt install -y sudo
RUN apt install -y dbus-x11
RUN apt install -y build-essential cmake git fish
RUN apt install -y locales \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=en_US.UTF-8

RUN groupadd -g $GID -o $USER_NAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $USER_NAME -p '*'
RUN usermod -aG sudo $USER_NAME
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER $USER_NAME

RUN cd $HOME && git clone https://github.com/powerline/fonts.git fonts && cd fonts && ./install.sh && rm -rf $HOME/fonts

# Install bash agnoster theme
RUN cd $HOME && mkdir -p .bash/themes/agnoster-bash && git clone https://github.com/franzflasch/agnoster-bash.git .bash/themes/agnoster-bash
RUN echo 'export THEME=$HOME/.bash/themes/agnoster-bash/agnoster.bash\n\
if [[ -f $THEME ]]; then\n\
export DEFAULT_USER=`whoami`\n\
source $THEME\n\
fi\n'\
>> $HOME/.bashrc

# Install fish shell with agnoster theme
RUN cd $HOME && git clone https://github.com/oh-my-fish/oh-my-fish
RUN cd $HOME/oh-my-fish
RUN cd $HOME && fish oh-my-fish/bin/install --offline --noninteractive --yes
RUN fish -c "omf update"
RUN fish -c "omf install agnoster"
RUN mkdir -p $HOME/.config/fish
RUN echo "set -g theme_display_user yes" > $HOME/.config/fish/config.fish
RUN echo "set -g theme_hide_hostname no" >> $HOME/.config/fish/config.fish
RUN echo "set -g fish_prompt_pwd_dir_length 1" >> $HOME/.config/fish/config.fish

