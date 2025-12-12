ARG BUILD_FROM
FROM $BUILD_FROM

# Installer autossh, openssh-client et bash
RUN apk add --no-cache \
    autossh \
    openssh-client \
    bash

# Copier le script de démarrage
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]