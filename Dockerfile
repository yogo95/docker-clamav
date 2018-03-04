FROM alpine:3.7

LABEL maintainer="NEGRO Y CASTRO, Eric <yogo95@zrim-everythng.eu>"

RUN rm -rf /var/cache/apk/* && \
    rm -rf /tmp/* && \
    apk update && \
    apk upgrade && \
    apk --update --update-cache add --no-cache \
    bash wget \
    clamav-daemon \
    clamav-libunrar \
    freshclam && \
    #
    # Clean
    #
    rm -f /var/cache/apk/* && \
    #
    # Set access to lib directory
    #
    mkdir -p /var/lib/clamav && \
    chown -R clamav:clamav /var/lib/clamav && \
    mkdir -p /usr/share/clamav/database && \
    mkdir /var/run/clamav && \
    chown clamav:clamav /var/run/clamav && \
    chmod 750 /var/run/clamav && \
    #
    # Configure ClamAV
    #
    sed -i 's/^\#\?Foreground .*$/Foreground yes/g' /etc/clamav/clamd.conf && \
    sed -i 's/^\#\?User .*$/User clamav/g' /etc/clamav/clamd.conf && \
    sed -i 's/^\#\?TCPSocket .*$/TCPSocket 3310/g' /etc/clamav/clamd.conf && \
    sed -i 's/^\#\?Foreground .*$/Foreground yes/g' /etc/clamav/freshclam.conf

# initial update of av databases
RUN wget -T 9999999 -O /usr/share/clamav/database/main.cvd http://database.clamav.net/main.cvd && \
    wget -O /usr/share/clamav/database/daily.cvd http://database.clamav.net/daily.cvd && \
    wget -O /usr/share/clamav/database/bytecode.cvd http://database.clamav.net/bytecode.cvd

COPY docker-cmd.sh /docker-cmd.sh
RUN chmod a+x /docker-cmd.sh

EXPOSE 3130

CMD ["/docker-cmd.sh", "-s"]
