FROM alpine:3.20.3

RUN apk update
RUN apk --no-cache add dnsmasq

COPY dnsmasq.conf /etc/dnsmasq.conf

EXPOSE 53 53/udp

ENTRYPOINT ["dnsmasq", "-k"]