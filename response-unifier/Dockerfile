# caddy builder
FROM abiosoft/caddy:builder as builder
ARG version="1.0.3"
ARG plugins="realip"
ARG enable_telemetry="true"
RUN go get -v github.com/abiosoft/parent
RUN VERSION=${version} PLUGINS=${plugins} ENABLE_TELEMETRY=${enable_telemetry} /bin/sh /usr/bin/builder.sh
# main container
FROM alpine:3.10
LABEL maintainer "Dave Williams <dave@dave.io>"
ARG version="1.0.3"
LABEL caddy_version="$version"
ENV ACME_AGREE="true"
ENV ENABLE_TELEMETRY="$enable_telemetry"
RUN apk add --no-cache \
  ca-certificates \
  curl \
  mailcap \
  openssh-client \
  tar \
  tzdata
RUN mkdir /conf && mkdir /tls
COPY --from=builder /install/caddy /usr/bin/caddy
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins
EXPOSE 80 443 2015
VOLUME /conf
VOLUME /tls
WORKDIR /srv
COPY --from=builder /go/bin/parent /bin/parent
ENTRYPOINT ["/bin/parent", "caddy"]
CMD ["--conf", "/conf/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]
