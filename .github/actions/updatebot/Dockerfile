FROM debian

RUN apt-get update

# tarball_nix
RUN apt-get install -y wget nix-bin

# plex
RUN apt-get install -y curl gnupg2 && \
    curl -s https://downloads.plex.tv/plex-keys/PlexSign.key > /etc/apt/trusted.gpg.d/plex.asc && \
    echo deb [signed-by=/etc/apt/trusted.gpg.d/plex.asc] https://downloads.plex.tv/repo/deb public main > /etc/apt/sources.list.d/plexmediaserver.list

RUN apt-get update

COPY run.sh /run.sh

ENTRYPOINT ["/run.sh"]
