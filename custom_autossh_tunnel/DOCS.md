# Custom AutoSSH Tunnel

Cet addon crée un tunnel SSH inverse (reverse tunnel) persistant entre votre Home Assistant et votre VPS.

## Installation

1. Ajoutez ce dépôt dans Home Assistant :
   - Allez dans **Paramètres** → **Modules complémentaires** → **Boutique**
   - Menu (⋮) → **Dépôts**
   - Ajoutez : `https://github.com/crisstof/autossh_hagreen`

2. Installez l'addon **Custom AutoSSH Tunnel**

3. Configurez l'addon (voir ci-dessous)

## Configuration

### Exemple de configuration

```yaml
hostname: "www.hagreen.tairopgc.com"
ssh_port: 2222
username: "haos"
remote_forwarding: "127.0.0.1:8081:192.168.1.40:8123"
server_alive_interval: 30
server_alive_count_max: 3
```

### Options

| Option | Description | Exemple |
|--------|-------------|---------|
| `hostname` | Adresse de votre VPS | `www.hagreen.tairopgc.com` |
| `ssh_port` | Port SSH du VPS | `2222` |
| `username` | Utilisateur SSH sur le VPS | `haos` |
| `remote_forwarding` | Format: `REMOTE_IP:REMOTE_PORT:LOCAL_IP:LOCAL_PORT` | `127.0.0.1:8081:192.168.1.40:8123` |
| `server_alive_interval` | Keepalive en secondes | `30` |
| `server_alive_count_max` | Tentatives avant déconnexion | `3` |

## Premier démarrage

1. **Démarrez l'addon** pour générer la clé SSH

2. **Consultez les logs** de l'addon - vous verrez la clé publique à copier

3. **Sur votre VPS**, ajoutez la clé publique :
   ```bash
   # Connectez-vous à votre VPS
   ssh votre-user@www.hagreen.tairopgc.com -p 2222
   
   # Créez le fichier authorized_keys si nécessaire
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   touch ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   
   # Ajoutez la clé publique (copiée depuis les logs)
   echo 'ssh-ed25519 AAAA... ha-autossh@2024-12-12' >> ~/.ssh/authorized_keys
   ```

4. **Redémarrez l'addon** - le tunnel devrait se connecter

## Configuration du VPS

Sur votre VPS, éditez `/etc/ssh/sshd_config` :

```bash
# Autoriser les tunnels inverses
GatewayPorts yes

# Ou pour n'autoriser que localhost (plus sécurisé)
# GatewayPorts clientspecified

# Keepalive
ClientAliveInterval 30
ClientAliveCountMax 3
```

Redémarrez SSH :
```bash
sudo systemctl restart sshd
```

## Accès à Home Assistant

Une fois le tunnel établi, accédez à Home Assistant via votre VPS :

```
http://www.hagreen.tairopgc.com:8081
```

## Vérification

Sur votre VPS, vérifiez que le port écoute :

```bash
ss -tlnp | grep 8081
# Devrait afficher : LISTEN 0 128 127.0.0.1:8081
```

## Dépannage

### Le tunnel ne se connecte pas

1. Consultez les logs de l'addon
2. Vérifiez que le port SSH est accessible : `nc -zv www.hagreen.tairopgc.com 2222`
3. Vérifiez la clé publique dans `~/.ssh/authorized_keys` sur le VPS
4. Testez manuellement : `ssh -p 2222 haos@www.hagreen.tairopgc.com`

### Le tunnel se déconnecte souvent

- Augmentez `server_alive_interval` à 60
- Vérifiez la stabilité de votre connexion Internet

### Impossible d'accéder via le VPS

- Vérifiez que `GatewayPorts` est activé dans `/etc/ssh/sshd_config`
- Vérifiez le firewall du VPS : `sudo ufw allow 8081`

## Sécurité

- La clé privée est stockée dans `/data/.ssh/` (volume persistant)
- Utilisez un port SSH non-standard (pas 22) sur votre VPS
- Configurez fail2ban sur votre VPS
- Limitez l'accès SSH par IP si possible

## Support

Pour signaler un bug : https://github.com/crisstof/autossh_hagreen/issues