# Use a lightweight base image such as Alpine Linux
FROM alpine:latest

# we need make and linux-headers to compile gdb
RUN apk add --no-cache make
RUN apk add --no-cache linux-headers
RUN apk add --no-cache texinfo
RUN apk add --no-cache gcc
RUN apk add --no-cache g++
RUN apk add --no-cache gfortran
# install gdb
# RUN apk add --no-cache gdb
RUN mkdir gdb-build ;\
    cd gdb-build;\
    wget http://ftp.gnu.org/gnu/gdb/gdb-14.1.tar.xz;\
    tar -xvf gdb-14.1.tar.xz;\
    cd gdb-14.1;\
    ./configure --prefix=/usr;\
    make;\
    make -C gdb install;\
    cd ..;\
    rm -rf gdb-build/;

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
