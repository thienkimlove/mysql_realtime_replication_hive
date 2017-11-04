FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive
ENV INITRD No
ENV LANG en_US.UTF-8
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:tieungao' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
RUN apt-get install --no-install-recommends -y mysql-server-5.6 mysql-common libmysqld-dev libmysqlclient-dev cmake vim  build-essential default-jdk libssl-dev wget

EXPOSE 80 443 3306 22 9160 9161 9162
CMD /usr/sbin/sshd -D
