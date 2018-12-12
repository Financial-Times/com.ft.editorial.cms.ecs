FROM alpine:latest
MAINTAINER 'Jussi Heinonen<jussi.heinonen@ft.com>'

ADD key_rotator.py /

# Install packages
RUN apk update && apk upgrade && \
    apk add --no-cache openssl bash curl \
    python3 python3-dev py3-pip openssl-dev libffi-dev build-base && \
    pip3 install --upgrade pip && \
    pip3 install credstash requests && \
    pip3 uninstall -y pip && \
    apk del build-base python3-dev && \
    chmod 755 /key_rotator.py

# Clean
RUN rm -rf /var/cache/apk/*

CMD /key_rotator.py
