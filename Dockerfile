# Учебный стенд: Ubuntu с systemd и установленным nginx.
# Общий для всех заданий; менять его не нужно.
FROM ubuntu:24.04

ENV container=docker \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      systemd systemd-sysv \
      nginx \
      curl procps nano \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Юниты, которые в контейнере не нужны и только мешают загрузке systemd
RUN systemctl mask \
      systemd-udevd.service systemd-udev-trigger.service \
      getty.target console-getty.service \
      systemd-firstboot.service \
 && systemctl enable nginx

EXPOSE 80

# systemd корректно завершается по SIGRTMIN+3, а не по SIGTERM
STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
