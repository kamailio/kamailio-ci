ARG ARCH=x86_64
FROM scratch
ARG ARCH

ADD ${ARCH}/kamailio_img.tar.gz /

ENTRYPOINT ["kamailio", "-DD", "-E"]
