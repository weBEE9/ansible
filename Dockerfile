# reference: https://github.com/chusiang/ansible-managed-node.dockerfile/blob/master/alpine-3.7/Dockerfile

FROM alpine:3.7

RUN apk update

RUN apk add --no-cache \
    sudo \
    bash \
    bash-completion \
    curl \
    wget \
    openssh \
    python \
    python3

# setting sshd
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# gerenrate ssh host key
RUN ssh-keygen -A
ENV NOTVISIBLE="in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# create new user
#
# username: docker
# password: docker
RUN adduser -s /bin/bash -D docker && \
    echo "docker:docker" | chpasswd
# add sudo permission to docker user
RUN echo 'docker ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# setting ssh public key
# Setting ssh public key.
RUN wget https://raw.githubusercontent.com/chusiang/ansible-jupyter.dockerfile/master/files/ssh/id_rsa.pub \
    -O /tmp/authorized_keys && \
    mkdir /home/docker/.ssh && \
    mv /tmp/authorized_keys /home/docker/.ssh/ && \
    chown -R docker:docker /home/docker/.ssh/ && \
    chmod 644 /home/docker/.ssh/authorized_keys && \
    chmod 700 /home/docker/.ssh

EXPOSE 22

CMD [ "/usr/sbin/sshd", "-D" ]