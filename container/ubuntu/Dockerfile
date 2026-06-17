#
# Dockerfile to quickly setup an Apple container machine.
#
# See also:
# - https://github.com/apple/container
# - https://rkiselenko.dev/blog/development-on-mac-with-acm/
#

FROM ubuntu:26.04

ENV container container
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies.
RUN apt update -y && apt upgrade -y && apt install -y --no-install-recommends \
      curl ca-certificates git sudo systemd init systemd-sysv openssh-server \
      binutils gpg vim libc6-dev libcurl4-openssl-dev libedit2 libgcc-s1 \
      unzip gnupg2 libgcc-13-dev libstdc++-13-dev libncurses-dev \
      libpython3-dev libsqlite3-0 libstdc++6 libxml2-dev libz3-dev \
      pkg-config tzdata zlib1g-dev net-tools iproute2 iputils-ping wget jq \
      build-essential \
      && apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup passwordless sudo for all users.
RUN echo 'ALL ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/nopasswd \
 && chmod 0440 /etc/sudoers.d/nopasswd

# Configure OpenSSH for local use only.
RUN mkdir -p /var/run/sshd \
 && ssh-keygen -A \
 && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/'                    /etc/ssh/sshd_config \
 && sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/'     /etc/ssh/sshd_config \
 && sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/'         /etc/ssh/sshd_config \
 && echo 'UseDNS no'               >> /etc/ssh/sshd_config \
 && echo 'GSSAPIAuthentication no' >> /etc/ssh/sshd_config \
 && systemctl enable ssh
COPY key.pub /etc/ssh/
RUN chmod a+rwx /etc/ssh/key.pub

RUN systemctl mask getty@.service systemd-logind.service \
      apt-daily.timer apt-daily-upgrade.timer fstrim.timer || true

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

EXPOSE 22
STOPSIGNAL SIGRTMIN+3
VOLUME [ "/sys/fs/cgroup" ]
CMD [ "/usr/sbin/init" ]
