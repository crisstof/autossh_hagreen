#!/usr/bin/with-contenv bashio

set -e

# Récupérer la configuration
HOSTNAME=$(bashio::config 'hostname')
SSH_PORT=$(bashio::config 'ssh_port')
USERNAME=$(bashio::config 'username')
REMOTE=$(bashio::config 'remote_forwarding')
INTERVAL=$(bashio::config 'server_alive_interval')
COUNT_MAX=$(bashio::config 'server_alive_count_max')

bashio::log.info "========================================="
bashio::log.info "Configuration AutoSSH Tunnel"
bashio::log.info "========================================="
bashio::log.info "Hostname: ${HOSTNAME}"
bashio::log.info "Port SSH: ${SSH_PORT}"
bashio::log.info "Utilisateur: ${USERNAME}"
bashio::log.info "Remote forwarding: ${REMOTE}"
bashio::log.info "Server alive interval: ${INTERVAL}s"
bashio::log.info "Server alive count max: ${COUNT_MAX}"
bashio::log.info "========================================="

# Créer le dossier pour les clés SSH
SSH_DIR="/data/.ssh"
mkdir -p "${SSH_DIR}"
chmod 700 "${SSH_DIR}"

# Générer la clé ED25519 si elle n'existe pas
KEY_FILE="${SSH_DIR}/id_ed25519"
if [ ! -f "${KEY_FILE}" ]; then
    bashio::log.info "Génération d'une nouvelle clé ED25519..."
    ssh-keygen -t ed25519 -f "${KEY_FILE}" -N "" -C "ha-autossh@$(date +%F)"
    bashio::log.warning "========================================="
    bashio::log.warning "IMPORTANT: Clé publique générée !"
    bashio::log.warning "========================================="
    bashio::log.warning ""
    bashio::log.warning "Copiez cette clé sur votre VPS :"
    bashio::log.warning ""
    cat "${KEY_FILE}.pub"
    bashio::log.warning ""
    bashio::log.warning "Sur le VPS, exécutez (en tant que ${USERNAME}) :"
    bashio::log.warning "  mkdir -p ~/.ssh"
    bashio::log.warning "  chmod 700 ~/.ssh"
    bashio::log.warning "  echo '$(cat ${KEY_FILE}.pub)' >> ~/.ssh/authorized_keys"
    bashio::log.warning "  chmod 600 ~/.ssh/authorized_keys"
    bashio::log.warning ""
    bashio::log.warning "Puis redémarrez cet addon."
    bashio::log.warning "========================================="
    # Attendre pour que l'utilisateur puisse lire les logs
    sleep 10
else
    bashio::log.info "Clé SSH existante trouvée: ${KEY_FILE}"
fi

chmod 600 "${KEY_FILE}"
[ -f "${KEY_FILE}.pub" ] && chmod 644 "${KEY_FILE}.pub"

# Configuration SSH
SSH_CONFIG="${SSH_DIR}/config"
cat > "${SSH_CONFIG}" << EOF
Host tunnel
    HostName ${HOSTNAME}
    Port ${SSH_PORT}
    User ${USERNAME}
    IdentityFile ${KEY_FILE}
    StrictHostKeyChecking accept-new
    ServerAliveInterval ${INTERVAL}
    ServerAliveCountMax ${COUNT_MAX}
    ExitOnForwardFailure yes
    LogLevel INFO
EOF

chmod 600 "${SSH_CONFIG}"

# Variables d'environnement AutoSSH
export AUTOSSH_GATETIME=0
export AUTOSSH_POLL=60
export AUTOSSH_LOGFILE=/proc/1/fd/1

bashio::log.info "Démarrage du tunnel AutoSSH..."
bashio::log.info "Connexion à ${USERNAME}@${HOSTNAME}:${SSH_PORT}"
bashio::log.info "Tunnel configuré: ${REMOTE}"

# Démarrer AutoSSH avec monitoring désactivé (-M 0)
exec autossh -M 0 \
    -F "${SSH_CONFIG}" \
    -N \
    -R "${REMOTE}" \
    tunnel