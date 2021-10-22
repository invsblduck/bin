docker run --rm \
    --name=unifi-controller \
    -e PUID="$(id -u)" \
    -e PGID="$(id -g)" \
    -p 0.0.0.0:3478:3478/udp \
    -p 0.0.0.0:10001:10001/udp \
    -p 0.0.0.0:8080:8080 \
    -p 0.0.0.0:8443:8443 \
    -p 0.0.0.0:1900:1900/udp \
    -v /data/unifi/config:/config \
    lscr.io/linuxserver/unifi-controller
