# Threat Hunt Lab  
**Laboratório integrado de simulação de ameaças com Splunk e MITRE Caldera**  

[![Docker](https://img.shields.io/badge/Docker-2CA5E0?style=flat&logo=docker&logoColor=white)](https://www.docker.com) 
[![Splunk](https://img.shields.io/badge/Splunk-000000?style=flat&logo=splunk&logoColor=white)](https://www.splunk.com)
[![MITRE Caldera](https://img.shields.io/badge/MITRE%20Caldera-2CA5E0?style=flat&logo=github&logoColor=white)](https://github.com/mitre/caldera)
[![Caldera Version](https://img.shields.io/badge/Caldera-v5.0.0-blue)](https://github.com/mitre/caldera/releases/tag/v5.0.0)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Project Status](https://img.shields.io/badge/Status-Active-brightgreen)](https://github.com/mitre/caldera)

Este é um ambiente Docker pré-configurado para simular ataques (Caldera) e monitorar/responder com o Splunk. Ideal para testes de Red Team/Blue Team.

---

## Estrutura do Projeto
```text
threat-hunt-lab/
├── .env                    # Variáveis de ambiente (senhas)
├── docker-compose.yml      # Orquestração dos serviços
├── caldera/
│   └── Dockerfile          # Build personalizado do Caldera
└── volumes/
    ├── splunk-data/        # Dados persistentes do Splunk
    └── caldera-logs/       # Logs do Caldera
```
## Começando
### Pré-Requisitos
Certifique-se de ter o Docker e o Docker Compose instalados com os seguintes comandos (exemplo para Ubuntu):

- Docker e Docker Compose instalados.
- Portas 8000 (Splunk) e 8888 (Caldera) liberadas.

*Nota:
Consulte a [documentação oficial do Docker](https://docs.docker.com/engine/install/ubuntu/) para lidar com especificidades não mencionadas anteriormente.*

---

### Configuração do Laboratório
1. Clone o repositório:
``` bash
git clone https://github.com/had-nu/threat-hunt-lab.git
cd threat-hunt-lab
```
2. Configure senhas no `.env`:
``` bash
echo "SPLUNK_PASSWORD=SenhaForte123" > .env
```
### Construção do ambiente
1. Splunk
O `docker-compose.yml` deste repositório já configura e baixa a imagem oficial do Splunk do Docker Hub automaticamente ao rodar os contêineres. Não é necessário nenhum passo manual antes disso.
- Imagem utilizada: `splunk/splunk:9.1.2`.

2. Caldera
O MITRE Caldera não possui uma imagem oficial no Docker Hub, portanto será necessário construir a imagem localmente. Entretanto, o repositório oficial do Caldera fornece um `Dockerfile` que pode ser usado para essa construção.

**Para construir o Caldera:**

1. Clone o repositório do Caldera e construa a imagem:
``` bash
git clone --recursive --branch 5.0.0 https://github.com/mitre/caldera.git caldera
docker build ./caldera docker build . --build-arg WIN_BUILD=true -t caldera:latest
cd ..
```
- Isso usa o `Dockerfile` oficial do Caldera.
- O argumento `--build-arg WIN_BUILD=true` é opcional (inclua apenas se precisar de suporte a builds Windows no plugin Sandcat).

### Rodando os Contêineres
Com a imagem do Caldera construída e o Splunk configurado via docker-compose.yml, inicie o laboratório:

1. Suba os contêineres:
``` bash
docker-compose up
```
- **Splunk:** Disponível em http://localhost:8000 (usuário: `admin`, senha: `<DefinaUmaSenha>`).
- **Caldera:** Disponível em http://localhost:8888 (usuário: `admin`, senha: `admin`).
2. Verifique os logs:
- Logs aparecem no terminal.
- Logs persistentes ficam em `./volumes/splunk-data` e `./volumes/caldera-logs`.

---

3. Parando o ambiente:
``` bash
docker compose down  # Mantém os volumes
docker compose down -v  # Remove volumes
```
---

### Solução de Problemas
- Portas em conflito: Se necessário, altere as portas no `docker-compose.yml`.
- Erros de build: Verifique se o Caldera foi clonado recursivamente.
- Erros de permissão: Se está no Linux sem privilégios de super usuário, lembre-se de incluir o `sudo`.
- Atualizar senhas: Após alterar senhas no `.env` lembre-se de reiniciar o serviço.

---

### Comandos Docker essenciais
**Comandos Docker Compose**
1. Iniciar os serviços em segundo plano:
``` bash
docker-compose up -d # cria e inicia os containers do Splunk e Caldera em modo detached.
```
2. Parar e remover containers (mantendo volumes de dados):
``` bash
docker-compose down
```
3. Parar e remover tudo (containers + volumes):
``` bash
docker-compose down -v # dados persistentes serão apagados.
```
4. Visualizar logs em tempo real:
``` bash
docker-compose logs -f # para "follow".
```
5. Reiniciar um serviço específico:
``` bash
docker-compose restart splunk
```

**Comandos Docker**
1. Listar containers em execução:
``` bash
docker ps # exibe apenas containers ativos.
```
2. Listar todos os containers (ativos e parados):
``` bash
docker ps -a # mostra todos os containers, incluindo os parados.
```
3. Visualizar logs de um container:
``` bash
docker logs splunk-threatlab
```
4. Acessar o terminal de um container:
``` bash
docker exec -it splunk-threatlab /bin/bash
```
5. Remover uma imagem:
``` bash
docker rmi splunk/splunk:9.1.2 # remove a imagem do Splunk (após parar containers dependentes).
```
6. Limpar recursos não utilizados:
``` bash
docker system prune -a # remove containers, imagens e volumes não utilizados (use com cuidado).
```

**Gerenciamento de Volumes**
1. Listar todos os volumes criados pelo Docker:
``` bash
docker volume ls
```
2. Inspecionar um volume:
``` bash
docker volume inspect threat-hunt-lab_splunk-data
```

