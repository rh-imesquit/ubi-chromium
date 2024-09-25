# Stage 1: Build stage using AlmaLinux
FROM almalinux:9 AS builder

# Install necessary packages in a single layer
RUN yum update -y && \
    yum install -y epel-release && \
    yum install -y yum-utils && \
    yum config-manager --set-enabled crb && \
    yum install -y \
        xorg-x11-server-Xorg \
        xorg-x11-xauth \
        xorg-x11-xinit \
        xterm \
        openbox \
        tigervnc-server \
        dbus-x11 \
        chromium \
        gtk3 \
        libX11 \
        alsa-lib \
        nss \
        atk \
        libXtst \
        libXScrnSaver \
        libXcomposite \
        libXdamage \
        libXcursor \
        libXi \
        libXrandr \
        libXrender \
        pango \
        alsa-plugins-pulseaudio \
        cups-libs \
        util-linux \
        procps \
        dbus \
        --setopt=install_weak_deps=False \
        --exclude=*.i686 && \
    yum clean all && \
    rm -rf /var/cache/yum


# Create a non-root user called 'chromiumuser'
RUN useradd -m chromiumuser && \
    mkdir -p /tmp/.X11-unix && \
    chmod 1777 /tmp/.X11-unix && \
    touch /home/chromiumuser/.Xauthority && \
    chown chromiumuser:chromiumuser /home/chromiumuser/.Xauthority && \
    mkdir -p /run/dbus && \
    chown chromiumuser:chromiumuser /run/dbus && \
    mkdir -p /home/chromiumuser/.dbus && \
    chown -R chromiumuser:chromiumuser /home/chromiumuser/.dbus && \
    mkdir -p /home/chromiumuser/.config/openbox && \
    chown -R chromiumuser:chromiumuser /home/chromiumuser/.config/openbox && \
    mkdir -p /home/chromiumuser/.cache && \
    chown -R chromiumuser:chromiumuser /home/chromiumuser/.cache

# Copy the startup script
COPY startup_chromium.sh /home/chromiumuser/startup.sh

# Make the startup script executable and set ownership
RUN chmod +x /home/chromiumuser/startup.sh && \
    chown chromiumuser:chromiumuser /home/chromiumuser/startup.sh

# Stage 2: Runtime stage using UBI 9
FROM registry.access.redhat.com/ubi9/ubi:latest AS runtime

# Set the password using an environment variable
ENV VNC_PASSWORD=YourSecurePasswordHere


# Copy necessary files from the builder stage
COPY --from=builder /home/chromiumuser /home/chromiumuser
COPY --from=builder /usr/bin /usr/bin
COPY --from=builder /usr/lib64 /usr/lib64
COPY --from=builder /usr/libexec /usr/libexec
COPY --from=builder /usr/share /usr/share
COPY --from=builder /etc /etc
COPY --from=builder /run/dbus /run/dbus

# Copy X11 and Openbox themes
# COPY --from=builder /usr/share/X11 /usr/share/X11
# COPY --from=builder /usr/share/themes /usr/share/themes
# COPY --from=builder /etc/xdg/openbox /etc/xdg/openbox
COPY --from=builder /usr/lib/python3.9/site-packages/xdg /usr/lib/python3.9/site-packages/xdg

# Set permissions
RUN chown -R chromiumuser:chromiumuser /home/chromiumuser && \
    mkdir -p /tmp/.X11-unix && \
    chmod 1777 /tmp/.X11-unix && \
    chown chromiumuser:chromiumuser /home/chromiumuser/.Xauthority && \
    mkdir -p /run/dbus && \
    chown chromiumuser:chromiumuser /run/dbus
#    mkdir -p /home/chromiumuser/.vnc && \
#    echo "${VNC_PASSWORD}" | vncpasswd -f > /home/chromiumuser/.vnc/passwd && \
#    chown -R chromiumuser:chromiumuser /home/chromiumuser/.vnc && \
#    chmod 600 /home/chromiumuser/.vnc/passwd 


# Switch to the non-root user 'chromiumuser'
USER chromiumuser

# Set environment variable for DISPLAY
ENV DISPLAY=:1

# Expose the VNC port
EXPOSE 5901

# Set the default command to run the startup script
CMD ["/home/chromiumuser/startup.sh"]