# Threat Hunt Lab
O Threat Hunt Lab é um ambiente pré-configurado que combina o MITRE Caldera para simulações avançadas de ataques cibernéticos com o Splunk para monitoramento, análise de logs e resposta a incidentes. Construído com Docker e Docker Compose, este projeto traz uma solução fácil de implantar para quem, como eu, quer simular um ambiente real de ataque e defesa. Também para equipas de segurança testarem táticas de Red Team e Blue Team em um único laboratório integrado.

**Notas de atualização:**
*22-fev-2024*
Este é apenas um *Minimum Viable Product (MVP)* com uma estrutura mínima para testes. Algumas configurações adicionais (como redes personalizadas, volumes, limites de arquivos, etc.), embora úteis em um projeto maior, poderiam complicar o trabalho. Farei pequenos incrementos diários, conforme avanço com o projeto.


## Estrutura do Projeto
``` text
threat-hunt-lab/
├── caldera/
│   ├── Dockerfile        # Dockerfile para construir a imagem do Caldera
│   └── (arquivos clonados do repositório Caldera)
├── docker-compose.yml    # Configuração para rodar Splunk e Caldera
└── volumes/
    ├── splunk-data/      # Dados e logs persistentes do Splunk
    └── caldera-logs/     # Logs persistentes do Caldera
```

## Pré-Requisitos
Certifique-se de ter o Docker e o Docker Compose instalados com os seguintes comandos (exemplo para Ubuntu):

**Docker**
``` bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
```
- Verificação: `docker --version`

**Docker Compose**
``` bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```
- Verificação: `docker-compose --version`

*Nota:
Consulte a documentação oficial do Docker para lidar com especificidades não mencionadas anteriormente.*
---
## Configuração do Laboratório
### Preparação das Imagens
1. Splunk
O Splunk foi preparado utilizando a imagem oficial disponível no Docker Hub. Para usá-lo neste laboratório:

- Imagem utilizada: `splunk/splunk:9.1.2`.
- Como preparar: O `docker-compose.yml` deste repositório já configura e baixa a imagem automaticamente ao rodar os contêineres. Não é necessário nenhum passo manual antes disso.

2. Caldera
O MITRE Caldera não possui uma imagem oficial no Docker Hub, portanto será necessário construir a imagem localmente. O repositório oficial do Caldera fornece um `Dockerfile` e um `docker-compose.yml` que podem ser usados para essa construção.

**Preparar a imagem do Caldera:**

1. Clone o repositório do Caldera:
``` bash
git clone --recursive --branch 5.0.0 https://github.com/mitre/caldera.git caldera
```

2. Construa a imagem:
``` bash
cd caldera
docker build . -t caldera:latest
```
- Isso usa o `Dockerfile` oficial do Caldera.
- O argumento `--build-arg WIN_BUILD=true` é opcional (inclua apenas se precisar de suporte a builds Windows no plugin Sandcat).

3. Retorne à raiz do projeto:
``` bash
cd ..
```
### Rodando os Contêineres
Com a imagem do Caldera construída e o Splunk configurado no docker-compose.yml, inicie o laboratório:

1. Suba os contêineres:
``` bash
docker-compose up
```
- **Splunk:** Disponível em http://localhost:8000 (usuário: `admin`, senha: `<DefinaUmaSenha>`).
- **Caldera:** Disponível em http://localhost:8888 (usuário: `admin`, senha: `admin`).
2. Verifique os logs:
- Logs aparecem no terminal.
- Logs persistentes ficam em `./volumes/splunk-data` e `./volumes/caldera-logs`.

3. Desligue o ambiente:
``` bash
docker-compose down
```
---

*Notas:
Certifique-se de que as portas usadas no `docker-compose.yml` (como 8000 e 8888) estejam livres.*
