FROM alpine:3.6
MAINTAINER 'Jussi Heinonen<jussi.heinonen@ft.com>'

#ADD sh/ /

# Install packages
RUN apk add -U py-pip && pip install --upgrade pip && \
    apk add bash curl && \
    pip install --upgrade awscli

# Clean
RUN rm -rf /var/cache/apk/*

CMD /bin/bash
