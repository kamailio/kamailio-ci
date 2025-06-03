FROM alpine:latest as wrapper

RUN --mount=type=bind,source=.,target=/mnt set -eux; \
    apkArch="$(apk --print-arch)"; \
    echo "Building image for ${apkArch}"; \
    mkdir -p /tmp/root; \
    tar xz -C /tmp/root -f /mnt/${apkArch}/kamailio_img.tar.gz

FROM scratch

COPY --from=wrapper /tmp/root /

ENTRYPOINT ["kamailio", "-DD", "-E"]
