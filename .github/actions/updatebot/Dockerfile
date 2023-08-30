FROM debian

RUN apt-get update

RUN apt-get install -y wget curl gnupg2 jq nix-bin

# plex
RUN curl -s https://downloads.plex.tv/plex-keys/PlexSign.key > /etc/apt/trusted.gpg.d/plex.asc && \
    echo deb [signed-by=/etc/apt/trusted.gpg.d/plex.asc] https://downloads.plex.tv/repo/deb public main > /etc/apt/sources.list.d/plexmediaserver.list

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
