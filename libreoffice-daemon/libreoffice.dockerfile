# Use a lightweight base image such as Alpine Linux
FROM alpine:latest

# Install the necessary dependencies for LibreOffice and Java
RUN apk add --no-cache openjdk11-jre libreoffice libreoffice-base

# Install any additional fonts (optional)
RUN apk add --no-cache msttcorefonts-installer fontconfig \
    ttf-freefont ttf-opensans ttf-inconsolata \
    ttf-liberation ttf-dejavu && \
    update-ms-fonts && \
    fc-cache -f && rm -rf /var/cache/apk/*

# Copy the script to run LibreOffice as a daemon (e.g. software to listen for commands on a port)
COPY start-libreoffice-daemon.sh /usr/local/bin/libreoffice-daemon

# Open a port if your daemon will be listening on any port
EXPOSE 8100

# Define the entry point for the container
ENTRYPOINT ["libreoffice-daemon"]
