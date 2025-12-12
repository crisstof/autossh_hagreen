#!/usr/bin/with-contenv bashio

HOSTNAME=$(bashio::config 'hostname')
SSH_PORT=$(bashio::config 'ssh_port')
USERNAME=$(bashio::config 'username')
REMOTE=$(bashio::config 'remote_forwarding')
INTERVAL=$(bashio::config 'server_alive_interval')
COUNT_MAX=$(bashio::config 'server_alive_count_max')

bashio::log.info "Configuration:"
bashio::log.info "  Hostname: ${HOSTNAME}"
bashio::log.info "  Port SSH: ${SSH_PORT}"
bashio::log.info "  User: ${USERNAME}"
bashio::log.info "  Remote forwarding: ${REMOTE}"

# Dossier pour les clés
mkdir -p /data/.ssh
chmod 700 /data/.ssh

# Générer une clé si absente
if ! bashio::fs.file_exists "/data/.ssh/id_ed25519"; then
  bashio::log.info "Aucune clé trouvée, génération d'une clé ED25519..."
  ssh-keygen -t ed25519 -f /data/.ssh/id_ed25519 -N "" -C "ha-custom-autossh@$(date +%F)"
  bashio::log.warning "Ajoute cette clé publique dans ~/.ssh/authorized_keys sur ton VPS :"
  bashio::log.warning "$(cat /data/.ssh/id_ed25519.pub)"
fi

chmod 600 /data/.ssh/id_ed25519

bashio::log.info "Démarrage du tunnel AutoSSH..."

exec autossh -M 0 -N \
  -o "ServerAliveInterval=${INTERVAL}" \
  -o "ServerAliveCountMax=${COUNT_MAX}" \
  -o "ExitOnForwardFailure=yes" \
  -o "StrictHostKeyChecking=accept-new" \
  -R "${REMOTE}" \
  -i /data/.ssh/id_ed25519 \
  -p "${SSH_PORT}" \
  "${USERNAME}@${HOSTNAME}"
