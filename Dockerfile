FROM debian:bullseye

RUN apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
						ca-certificates \
						inetutils-ping libcap2-bin sniproxy curl psmisc apache2-utils \
	&& rm -rf /var/lib/apt/lists/*

COPY --chown=nobody:nogroup ./AdGuardHome /opt/AdGuardHome
COPY --chown=nobody:nogroup sniproxy.conf /etc/sniproxy.conf
COPY --chown=nobody:nogroup run.sh /run.sh

RUN setcap 'cap_net_bind_service=+eip' /opt/AdGuardHome/AdGuardHome

# 53     : TCP, UDP : DNS
# 80     : TCP      : SNIProxy
# 443    : TCP      : SNIProxy
# 8080   : TCP      : AdGuardHome
EXPOSE 53/tcp 53/udp 80/tcp 443/tcp 8080/tcp

VOLUME ["/opt/AdGuardHome"]

ENTRYPOINT ["/run.sh"]
