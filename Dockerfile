ARG BUILD_FROM
FROM $BUILD_FROM

# Install autossh + client SSH
RUN apk add --no-cache autossh openssh-client

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD [ "/run.sh" ]