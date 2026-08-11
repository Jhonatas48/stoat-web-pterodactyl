FROM node:26-alpine

ENV HOME=/home/container \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apk add --no-cache \
      bash git openssh-client python3 make g++ curl netcat-openbsd tini \
    && mkdir -p /opt/stoat-web-template/scripts /home/container \
    && npm install --global pnpm@11.3.0 \
    && pnpm --version

COPY scripts/ /opt/stoat-web-template/scripts/
RUN chmod +x /opt/stoat-web-template/scripts/*.sh

WORKDIR /home/container
STOPSIGNAL SIGTERM
ENTRYPOINT ["/sbin/tini", "-g", "--"]
CMD ["bash", "/home/container/scripts/start.sh"]
