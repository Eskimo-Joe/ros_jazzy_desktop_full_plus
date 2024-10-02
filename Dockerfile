FROM ubuntu:noble

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get upgrade -y

RUN apt-get install -y \
    curl \
    git \
    gnupg2 \
    nano \
    python3 \
    vim \
    cargo \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y \
    locales \
    && locale-gen en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8

RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y tzdata \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

COPY config/ site_config/

ARG USERNAME=ros
ARG USER_UID=1001
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID ${USERNAME} \
    && useradd -s /bin/bash --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME}\
    && mkdir /home/${USERNAME}/.config && chown ${USER_UID}:${USER_GID} /home/$USERNAME/.config
    
RUN apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL =\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
COPY bashrc /home/$USERNAME/.bashrc

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

CMD ["bash"]

RUN apt-get update \
    && apt install -y software-properties-common \
    && add-apt-repository universe \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y ros-dev-tools \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y ros-jazzy-desktop-full \
    && echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc \
    && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

ENV ROS_DISTRO=jazzy
ENV ROS_IP=localhost

RUN apt-get update \
    && apt-get install -y python3-rosdep \
    clang \
    && rosdep init \
    && rosdep update \
    && rosdep fix-permissions \
    && mkdir ~/ws_rmw_zenoh/src -p \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ws_rmw_zenoh/src 

RUN git clone https://github.com/ros2/rmw_zenoh.git

WORKDIR /ws_rmw_zenoh

RUN apt-get update \
    && source /opt/ros/jazzy/setup.bash \
    &&rosdep update \
    && rosdep install --from-paths . --ignore-src --rosdistro jazzy -y \
    && colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /
