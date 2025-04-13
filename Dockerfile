FROM debian:bookworm

# Create a build user with the same UID/GID as your macOS user, if you want
RUN useradd -m -u 1000 builder

RUN apt-get update && \
    apt-get install -y build-essential git bc curl bzip2 cpio unzip python3 rsync file libncurses-dev && \
    rm -rf /var/lib/apt/lists/*

USER builder
WORKDIR /home/builder

