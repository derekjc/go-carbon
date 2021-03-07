FROM golang:1.15-alpine as builder

ENV GOCARBON_VERSION=0.15.6
ENV GOPATH=/opt/go

RUN \
  apk update  --no-cache && \
  apk upgrade --no-cache && \
  apk add g++ git make musl-dev cairo-dev

WORKDIR ${GOPATH}

RUN \
  export PATH="${PATH}:${GOPATH}/bin" && \
  mkdir -p \
    /var/log/go-carbon && \
  git clone https://github.com/go-graphite/go-carbon.git

WORKDIR ${GOPATH}/go-carbon

RUN \
  export PATH="${PATH}:${GOPATH}/bin" && \
  git checkout "tags/v${GOCARBON_VERSION}" 2> /dev/null ; \
  version=$(git describe --tags --always | sed 's/^v//') && \
  echo "build version: ${version}" && \
  make && \
  mv go-carbon /tmp/go-carbon

# ------------------------------ RUN IMAGE --------------------------------------
FROM alpine:3.13.2

COPY --from=builder /tmp/go-carbon                         /usr/bin/go-carbon

COPY conf/ /etc/go-carbon/
COPY entrypoint.sh /

RUN \
  apk update --no-cache && \
  apk upgrade --no-cache && \
  apk add    --no-cache --virtual .build-deps \
    cairo \
    shadow \
    tzdata \
    libc6-compat \
    ca-certificates \
    su-exec \
    tini \
  && /usr/sbin/useradd \
    --system \
    -U \
    -s /bin/false \
    -c "User for Graphite daemon" \
    carbon && \
  mkdir \
    /var/log/go-carbon && \
  chown -R carbon:carbon /var/log/go-carbon && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/*

WORKDIR /

ENTRYPOINT [ "/sbin/tini", "--" ]

ENV HOME /root

EXPOSE 2003 2003/udp 2004 8080 8081

VOLUME [ "/var/lib/graphite/whisper" ]

CMD ["/entrypoint.sh"]