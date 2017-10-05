FROM alpine:3.6
MAINTAINER 'Jussi Heinonen<jussi.heinonen@ft.com>'

ADD echoes.sh /

RUN apk add -U bash && \
    chmod 755 /*.sh

# Clean
RUN rm -rf /var/cache/apk/*

EXPOSE 8080

CMD /bin/bash /echoes.sh
