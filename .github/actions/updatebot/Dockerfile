FROM debian

RUN apt-get update
RUN apt-get install -y wget nix-bin

COPY run.sh /run.sh

ENTRYPOINT ["/run.sh"]
