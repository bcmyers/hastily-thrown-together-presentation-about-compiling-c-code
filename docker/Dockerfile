FROM ubuntu:jammy

################################################################################
# basic
################################################################################

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV TZ=Etc/UTC

RUN set -eux ; \
    apt-get update ; \
    apt-get upgrade -y ; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        curl \
        git \
        gnupg \
        locales \
        man-db \
        sudo \
        tzdata \
        wget ; \
    yes | unminimize ; \
    rm /etc/localtime ; \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime ; \
    dpkg-reconfigure -f noninteractive tzdata ;\
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen ; \
    locale-gen ; \
    dpkg-reconfigure -f noninteractive locales

RUN set -eux ; \
    useradd -m -s /bin/bash brian.myers ; \
    usermod -a -G sudo brian.myers ; \
    echo "brian.myers:password" | chpasswd

################################################################################
# python
################################################################################

RUN set -eux ; \
    apt-get update ; \
    apt-get upgrade -y ; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        curl \
        libbz2-dev \
        libffi-dev \
        liblzma-dev \
        libncursesw5-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        libxmlsec1-dev \
        llvm \
        make \
        tk-dev \
        wget \
        xz-utils \
        zlib1g-dev

USER brian.myers

RUN set -eux ; \
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv ; \
    export PYENV_ROOT="$HOME/.pyenv" ; \
    export PATH="$PYENV_ROOT/bin:$PATH" ; \
    eval "$(pyenv init -)" ; \
    git clone https://github.com/pyenv/pyenv-virtualenv.git "$(pyenv root)/plugins/pyenv-virtualenv" ; \
    git clone https://github.com/pyenv/pyenv-virtualenvwrapper.git "$(pyenv root)/plugins/pyenv-virtualenvwrapper" ; \
    pyenv install 3.8.12 ; \
    pyenv install 3.10.6 ; \
    pyenv global 3.8.12

RUN set -eux ; \
    export PYENV_ROOT="$HOME/.pyenv" ; \
    export PATH="$PYENV_ROOT/bin:$PATH" ; \
    eval "$(pyenv init -)" ; \
    pip install --upgrade pip ; \
    pip install \
        virtualenv \
        virtualenvwrapper \
        wheel

################################################################################
# rust
################################################################################

USER brian.myers

ENV CARGO_HOME=/home/brian.myers/.cargo
ENV RUSTUP_HOME=/home/brian.myers/.rustup

ARG RUST_VERSION=1.63.0
ARG RUSTUP_VERSION=1.25.1
ARG RUSTUP_SHA256=5cc9ffd1026e82e7fb2eec2121ad71f4b0f044e88bca39207b3f6b769aaa799c
RUN set -eux ; \
    cd /tmp ; \
    curl -L -o rustup-init "https://static.rust-lang.org/rustup/archive/$RUSTUP_VERSION/x86_64-unknown-linux-gnu/rustup-init" ; \
    hash=$(sha256sum rustup-init | awk '{ print $1 }') ; \
    [ "$hash" = "$RUSTUP_SHA256" ] || exit 1 ; \
    chmod +x rustup-init; \
    ./rustup-init \
        -y \
        --profile default \
        --default-toolchain "$RUST_VERSION" \
        --default-host x86_64-unknown-linux-gnu ; \
    chmod -R a+w "$RUSTUP_HOME" "$CARGO_HOME" ; \
    rm -rf /tmp/*

################################################################################
# neovim
################################################################################

USER root

RUN set -eux ;\
    apt-get update ; \
    apt-get upgrade -y ; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        autoconf \
        automake \
        cmake \
        curl \
        doxygen \
        g++ \
        gettext \
        libtool \
        libtool-bin \
        ninja-build \
        pkg-config \
        unzip

RUN set -eux ; \
    cd /tmp ;\
    git clone https://github.com/neovim/neovim ; \
    cd neovim ; \
    git checkout v0.7.2 ; \
    make CMAKE_BUILD_TYPE=RelWithDebInfo ; \
    make install ;\
    rm -rf /tmp/*

USER brian.myers

RUN set -eux ; \
    git clone --depth 1 https://github.com/wbthomason/packer.nvim \
        ~/.local/share/nvim/site/pack/packer/start/packer.nvim

################################################################################
# rust programs
################################################################################

RUN set -eux ; \
    export PATH="$CARGO_HOME/bin:$PATH" ; \
    cargo install \
        exa \
        just \
        ripgrep

################################################################################
# prompt
################################################################################

RUN set -eux ; \
    export PATH="$CARGO_HOME/bin:$PATH" ; \
    cd /tmp ; \
    git clone https://github.com/bcmyers/prompt.git ; \
    cd prompt ; \
    cargo install --path . --root ~/.local ; \
    rm -rf /tmp/*

################################################################################
# dotfiles
################################################################################

USER root

RUN set -eux ;\
    apt-get update ; \
    apt-get upgrade -y ; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        stow

USER brian.myers

RUN set -eux ; \
    export PATH="$CARGO_HOME/bin:$PATH" ; \
    cd /home/brian.myers ; \
    git clone https://github.com/bcmyers/dotfiles.git ; \
    cd dotfiles ; \
    rm -rf ~/.bashrc ~/.hushlogin ~/.profile ; \
    just install

################################################################################
# ssh
################################################################################

USER root

RUN set -eux ; \
    apt-get update ; \
    apt-get upgrade -y ; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        openssh-server \
        supervisor

RUN set -eux ; \
    cd /etc/ssh ; \
    ssh-keygen -A ; \
    mkdir -p /run/sshd ; \
    mkdir -p /var/log/sshd ; \
    mkdir -p /var/log/supervisor

COPY files/sshd.conf /etc/supervisor/conf.d/sshd.conf
COPY files/sshd_config /etc/ssh/sshd_config
COPY files/supervisord.conf /etc/supervisor/supervisord.conf

################################################################################
# sudo
################################################################################

COPY files/sudoers /etc/sudoers

################################################################################
# other
################################################################################

RUN set -eux ; \
    apt-get update ; \
    apt-get upgrade -y ; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        binutils \
        clangd-13 \
        glibc-source \
        libc6-dbg \
        gdb \
        valgrind \
        zlib1g-dev

USER brian.myers
WORKDIR /home/brian.myers

EXPOSE 22
ENTRYPOINT sudo supervisord -c /etc/supervisor/supervisord.conf && /bin/bash
