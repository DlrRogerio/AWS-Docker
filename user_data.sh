#!/bin/bash

# ---------------------- CONFIGURAÇÕES INICIAIS ------------------------

# Identificador do sistema de arquivos EFS da AWS
EFS_ID="fs-xxxxxxxx"  # Substitua pelo seu File System ID

# Informações de conexão com o banco de dados
MYSQL_HOST="database.example.com"
MYSQL_DATABASE="wordpress_db"
MYSQL_USER="wp_user"
MYSQL_PASS="strong_password_here"

# Caminhos e versões
COMPOSE_VER="v2.34.0"
APP_DIR="/home/ec2-user/wordpress-app"
MOUNT_PATH="/mnt/aws-efs"

# ---------------------- INSTALAÇÃO DE DEPENDÊNCIAS --------------------

# Atualiza os pacotes do sistema
yum update -y

# Instala a AWS CLI (útil para operações com serviços da AWS)
yum install -y aws-cli

# Instala o Docker e ativa seu serviço
yum install -y docker
systemctl start docker
systemctl enable docker

# Adiciona o usuário padrão ao grupo Docker (evita uso do sudo)
usermod -aG docker ec2-user

# Instala o Docker Compose em sua versão especificada
curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# --------------------- MONTAGEM DO ARMAZENAMENTO EFS ------------------

# Instala utilitários do EFS
yum install -y amazon-efs-utils

# Cria o diretório onde o EFS será montado
mkdir -p "${MOUNT_PATH}"

# Faz a montagem do EFS no diretório criado
mount -t efs "${EFS_ID}":/ "${MOUNT_PATH}"

# Garante que a montagem persista após reinicializações
echo "${EFS_ID}:/ ${MOUNT_PATH} efs defaults,_netdev 0 0" >> /etc/fstab

# Ajusta as permissões para que o usuário www-data (id 33) tenha controle
chown -R 33:33 "${MOUNT_PATH}"

# ------------------------ CRIAÇÃO DO PROJETO --------------------------

# Cria o diretório do projeto e navega até ele
mkdir -p "${APP_DIR}"
cd "${APP_DIR}"

# Cria o arquivo docker-compose.yml com o serviço WordPress
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    container_name: wp_app
    environment:
      WORDPRESS_DB_HOST: ${MYSQL_HOST}
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASS}
    ports:
      - "80:80"
    volumes:
      - ${MOUNT_PATH}:/var/www/html
EOF

# ------------------------ EXECUÇÃO DO CONTAINER ------------------------

# Inicia o container do WordPress em segundo plano
docker-compose up -d
