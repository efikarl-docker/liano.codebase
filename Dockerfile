FROM archlinux

ARG     THE_USER=efika
ARG     THE_PSWD=efika
RUN pacman --noconfirm -Syu git curl unzip\
 && useradd -mU ${THE_USER} && usermod -aG wheel ${THE_USER} && echo "root:root" | chpasswd && echo "${THE_USER}:${THE_PSWD}" | chpasswd

USER    ${THE_USER}:${THE_USER}
WORKDIR /home/${THE_USER}
ENV     WORKSPACE                       ./ws
ENV     BASESPACE                       ./bs
ENV     GITHUB_MIRROR                   "https://hub.fastgit.org"
COPY    codebase.sh                     .
COPY    entrypoint.sh                   .

ENTRYPOINT [ "./entrypoint.sh" ]
