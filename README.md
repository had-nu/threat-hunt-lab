# Threat Hunt Lab

**Laboratório integrado de simulação de ameaças com Splunk e MITRE Caldera**

[![Docker](https://img.shields.io/badge/Docker-2CA5E0?style=flat&logo=docker&logoColor=white)](https://www.docker.com)
[![Splunk](https://img.shields.io/badge/Splunk-000000?style=flat&logo=splunk&logoColor=white)](https://www.splunk.com)
[![MITRE Caldera](https://img.shields.io/badge/MITRE%20Caldera-2CA5E0?style=flat&logo=github&logoColor=white)](https://github.com/apache/caldera)
[![Caldera Version](https://img.shields.io/badge/Caldera-v5.3.0+-blue)](https://github.com/apache/caldera/releases)
[![Splunk Version](https://img.shields.io/badge/Splunk-10.4.2-blue)](https://hub.docker.com/r/splunk/splunk/tags)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Project Status](https://img.shields.io/badge/Status-Active-brightgreen)](https://github.com/had-nu/threat-hunt-lab)

Este é um ambiente Docker pré-configurado para simular ataques (Caldera) e monitorar/responder com o Splunk. Ideal para testes de Red Team/Blue Team, threat hunting e detecção baseada em MITRE ATT&CK.

---

## Estrutura do Projeto

```text
threat-hunt-lab/
├── .env                    # Variáveis de ambiente (senhas) - NÃO commitado
├── .env.example            # Template para .env
├── docker-compose.yml      # Orquestração dos serviços
├── caldera/
│   └── conf/
│       └── default.yml     # Configuração padrão do Caldera
└── volumes/                # Dados persistentes (gitignored)
    ├── splunk-data/
    ├── splunk-etc/
    ├── caldera-logs/
    ├── caldera-conf/
    └── caldera-plugins/
```

---

## Quick Start (Início Rápido)

### Pré-Requisitos

- **Docker Engine** 20.10+ e **Docker Compose** v2+ (plugin `docker compose`)
- **RAM**: Mínimo 8 GB (recomendado 16 GB)
- **CPU**: 4+ cores
- **Portas livres**: 8000, 8088, 8089 (Splunk) • 8888 (Caldera)

> **Ubuntu/Debian**: `sudo apt update && sudo apt install docker.io docker-compose-plugin`
> **Arch Linux**: `sudo pacman -Syu docker docker-compose`
> **Fedora (repositório nativo)**: `sudo dnf install docker docker-compose-plugin`
> **Fedora (Docker CE oficial)**: `sudo dnf -y install dnf-plugins-core && sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo && sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`

Após instalar em qualquer distro, habilite o serviço, adicione seu usuário ao grupo `docker` e verifique:

```bash
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker  # aplica o novo grupo sem precisar logout (ou faça logout/login)
docker --version && docker compose version
```

---

### 1. Clone e Configure

```bash
# Clone o repositório
git clone https://github.com/had-nu/threat-hunt-lab.git
cd threat-hunt-lab

# Configure variáveis de ambiente (OBRIGATÓRIO)
cp .env.example .env
# Edite .env e defina senhas fortes:
# SPLUNK_PASSWORD=SuaSenhaForte123!
# CALDERA_ADMIN_PASSWORD=OutraSenhaForte456!
```

### 2. Suba o Laboratório

```bash
# Inicia em background (detached)
docker compose up -d

# Acompanhe logs de inicialização
docker compose logs -f
```

### 3. Acesse as Interfaces

| Serviço | URL | Credenciais Padrão |
|---------|-----|-------------------|
| **Splunk Web** | http://localhost:8000 | `admin` / `$SPLUNK_PASSWORD` |
| **Splunk HEC** | http://localhost:8088 | Token: `$SPLUNK_HEC_TOKEN` (se definido) |
| **Splunk Mgmt** | https://localhost:8089 | `admin` / `$SPLUNK_PASSWORD` |
| **Caldera** | http://localhost:8888 | `admin` / `$CALDERA_ADMIN_PASSWORD` |

> **Primeira inicialização**: Splunk leva ~2-3 min para aceitar licença e indexar. Caldera ~30-60s.

---

### 4. Verifique Status

```bash
# Status dos containers
docker compose ps

# Health checks
docker compose exec splunk /opt/splunk/bin/splunk status
curl -s http://localhost:8888/api/v2/version | jq .
```

---

### 5. Pare o Ambiente

```bash
# Para containers (mantém dados)
docker compose down

# Para containers + REMOVE volumes (dados perdidos!)
docker compose down -v
```

---

## Configuração Avançada

### Variáveis de Ambiente (`.env`)

```bash
# OBRIGATÓRIAS
SPLUNK_PASSWORD=SenhaForte123!          # 8+ chars, upper, lower, number, special
CALDERA_ADMIN_PASSWORD=SenhaForte456!   # Senha admin do Caldera

# OPCIONAIS
SPLUNK_HEC_TOKEN=meu-token-hec          # Para ingestão via HTTP Event Collector
# SPLUNK_LICENSE_URI=https://license:8000  # Se tiver license master
# TRAEFIK_DOMAIN=threathunt.local       # Para TLS via Traefik (ver docker-compose.yml)
```

### Portas Expostas

| Porta | Serviço | Protocolo | Descrição |
|-------|---------|-----------|-----------|
| 8000 | Splunk Web | TCP | Interface web principal |
| 8088 | Splunk HEC | TCP | HTTP Event Collector |
| 8089 | Splunk Mgmt | TCP | Management API (REST) |
| 8888 | Caldera Web/API | TCP | Interface e API REST |
| 7010 | Caldera WS | TCP | WebSocket C2 (opcional) |
| 7011 | Caldera TCP | TCP | Raw TCP C2 (opcional) |
| 7012 | Caldera UDP | UDP | UDP C2 (opcional) |

> **Segurança**: Por padrão, apenas 8000, 8088, 8089 (Splunk) e 8888 (Caldera) são expostos no host. Portas C2 (7010-7012) ficam apenas na rede interna `threatlab-network`. Para expor, edite `docker-compose.yml`.

### Rede Isolada

Todos os containers rodam na rede `threatlab-network` (subnet `172.28.0.0/16`), isolados do host e outros containers.

---

## Operações Comuns

### Logs

```bash
# Todos os logs (follow)
docker compose logs -f

# Apenas Splunk
docker compose logs -f splunk

# Apenas Caldera
docker compose logs -f caldera

# Últimas 100 linhas
docker compose logs --tail=100 splunk
```

### Acesso ao Shell

```bash
# Splunk
docker compose exec splunk /bin/bash

# Caldera
docker compose exec caldera /bin/bash

# Splunk CLI
docker compose exec splunk /opt/splunk/bin/splunk search "index=_internal | head 5"
```

### Backup e Restore

```bash
# Backup volumes (para diretório local)
mkdir -p backups/$(date +%F)
docker run --rm -v threatlab-splunk-data:/data -v $(pwd)/backups/$(date +%F):/backup alpine tar czf /backup/splunk-data.tar.gz -C /data .
docker run --rm -v threatlab-caldera-conf:/data -v $(pwd)/backups/$(date +%F):/backup alpine tar czf /backup/caldera-conf.tar.gz -C /data .

# Restore (exemplo Splunk)
docker run --rm -v threatlab-splunk-data:/data -v $(pwd)/backups/2026-01-15:/backup alpine tar xzf /backup/splunk-data.tar.gz -C /data
```

### Atualização de Imagens

```bash
# Pull latest images
docker compose pull

# Recreate containers com novas imagens
docker compose up -d --force-recreate

# Limpeza de imagens antigas
docker image prune -f
```

---

## Hardening de Segurança (Produção)

### 1. TLS/SSL com Traefik (Recomendado)

Descomente a seção `traefik` no `docker-compose.yml` e configure:

```bash
# No .env
TRAEFIK_DOMAIN=threathunt.seudominio.com

# Certifique-se que DNS A aponta para este host
# Traefik obtém certs Let's Encrypt automaticamente
```

### 2. Firewall (UFW exemplo)

```bash
# Apenas portas necessárias
sudo ufw allow 8000/tcp   # Splunk Web
sudo ufw allow 8088/tcp   # Splunk HEC
sudo ufw allow 8888/tcp   # Caldera
sudo ufw enable
```

### 3. Senhas e Secrets

- **NUNCA** use senhas padrão em produção
- Use secrets do Docker Swarm/K8s ou vault externo
- Rode `docker compose exec splunk /opt/splunk/bin/splunk edit user admin -password 'NovaSenhaForte!' -auth admin:SenhaAtual`

### 4. Splunk HEC Token

Gere token seguro:
```bash
# No Splunk Web: Settings > Data Inputs > HTTP Event Collector > New Token
# Ou via CLI:
docker compose exec splunk /opt/splunk/bin/splunk http-event-collector create threatlab -uri https://localhost:8089 -auth admin:$SPLUNK_PASSWORD
```

### 5. Caldera API Keys

Regere API keys no primeiro login:
1. Acesse http://localhost:8888
2. Login com `admin` / `$CALDERA_ADMIN_PASSWORD`
3. Vá em **Settings > API Keys** > **Generate New Key**
4. Atualize `caldera/conf/default.yml` ou crie `caldera/conf/local.yml`

---

## Primeiros Passos no Laboratório

### Splunk: Ingestão de Logs do Caldera

1. No Splunk Web: **Settings > Data Inputs > HTTP Event Collector > New Token**
   - Name: `caldera`
   - Enable SSL: Sim (se usar Traefik)
   - Index: `main` (ou crie `threathunt`)
2. Copie o **Token** gerado
3. No Caldera: **Settings > Reporting > Splunk** > configure host/token

### Caldera: Primeira Operação

1. Acesse http://localhost:8888
2. Login: `admin` / sua senha
3. Vá em **Plugins > Training** > complete o curso "Adversary Emulation"
4. Crie um **Adversary Profile** baseado em ATT&CK
5. Deploy um **Agent** (Sandcat/Manx) em VM alvo
6. Execute uma **Operation** e observe logs no Splunk

---

## Troubleshooting

| Problema | Solução |
|----------|---------|
| **Porta 8000 em uso** | `sudo lsof -i :8000` → mude no `docker-compose.yml` |
| **Splunk não inicia** | `docker compose logs splunk` → verifique licença/senha |
| **Caldera 500 error** | `docker compose logs caldera` → verifique `conf/default.yml` |
| **Permissão negada volumes** | `sudo chown -R 1000:1000 volumes/` (UID Splunk/Caldera) |
| **Sem memória** | Aumente `deploy.resources.limits.memory` no compose |
| **Caldera não vê plugins** | `docker compose exec caldera ls /usr/src/app/plugins` → reinicie |

---

## Versões Utilizadas

| Componente | Versão | Fonte |
|------------|--------|-------|
| Splunk Enterprise | 10.4.2 | `splunk/splunk:10.4.2` (Docker Hub) |
| MITRE Caldera | 5.3.0+ (latest) | `ghcr.io/mitre/caldera:latest` (GHCR) |
| Traefik (opcional) | v3.0 | `traefik:v3.0` (Docker Hub) |

> **Nota**: Splunk 10.x requer `SPLUNK_GENERAL_TERMS=--accept-sgt-current-at-splunk-com`. Para LTS, use `splunk/splunk:9.4.3`.

---

## Contribuindo

1. Fork o repositório
2. Crie branch: `git checkout -b feature/minha-feature`
3. Commit: `git commit -m 'feat: minha feature'`
4. Push: `git push origin feature/minha-feature`
5. Abra Pull Request

---

## Licença

Este projeto está licenciado sob a **Apache License 2.0**. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## Referências

- [Splunk Docker Docs](https://github.com/splunk/docker-splunk)
- [Caldera Documentation](https://caldera.readthedocs.io/)
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [Caldera GitHub (Apache)](https://github.com/apache/caldera)
- [Splunk General Terms](https://www.splunk.com/en_us/legal/splunk-general-terms.html)

---

> **Última atualização**: Agosto 2026 — Versões: Splunk 10.4.2, Caldera 5.3.0+