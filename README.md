# Projeto 2 AWS-Docker

## Introdução 

Este projeto tem como objetivo a implementação de uma infraestrutura na AWS para hospedar uma aplicação WordPress utilizando contêineres Docker, garantindo alta disponibilidade, escalabilidade e gerenciamento eficiente dos recursos. A solução inclui:
- Instalação e configuração do Docker em instâncias EC2, com automação via script de inicialização.
- Execução da aplicação WordPress em contêineres, com banco de dados MySQL gerenciado pelo Amazon RDS.
- Configuração do Amazon EFS para armazenamento de arquivos estáticos compartilhados.
- Uso de Load Balancer da AWS para assegurar disponibilidade e resiliência.

---

## Sumário

- [Virtual Private Cloud (VPC)](#virtual-private-cloud-vpc)
- [Security Groups (SG)](#security-groups-sg)
- [Relational Database Services (RDS)](#relational-database-services-rds)
- [Elastic File System (EFS)](#elastic-file-system-efs)
- [Key Pairs (KP)](#key-pairs-kp)
- [Launch Template (LT)](#launch-template-lt)
- [Load Balancer (LB)](#load-balancer-lb)
- [Auto Scaling Group (ASG)](#auto-scaling-group-asg)

---

## Virtual Private Cloud (VPC)

1. Abra o painel principal da AWS e pesquise por `VPC`.
2. Clique em `Suas VPCs`.
3. Clique em `Criar VPC`.

![img](images/vpc1.png)
![img](images/vpc2.png)

4. Após conferir se está igual as imagens, clique em `Criar VPC`.
5. Assim fica o Mapa de Recursos da sua VPC.

![img](images/mapavpc.png)

---

## Security Groups (SG)

Primeiro iremos criar os Security Groups vazios, para depois configurá-los, pois um depende do outro para funcionar e portanto, todos devem estar criados para que possam se interligar.

1. Abra o painel principal da AWS e pesquise por `Grupos de Segurança`.
2. Clique em `Grupos de Segurança`.
3. Clique em `Criar grupo de segurança`.


# Configuração de Security Groups

## 1. Security Group da EC2

![img](images/ec2SG.png)

## 2. Security Group da RDS

![img](images/rdsSG.png)

## 3. Security Group da EFS

![img](images/efsSG.png)

## 4. Security Group da LB

![img](images/lbSG.png)

---

# Configuração de Regras de Segurança para os Grupos

## 1. Configuração do Security Group da EC2

1. Selecione o grupo de segurança do EC2, clique em "**Ações**" e "**Editar regras de entrada**".

2. Em "**Regras de entrada**", clique em "**Adicionar regra**". Adicione as seguintes regras:

    - **SSH**:
        - **Tipo**: SSH
        - **Porta**: 22
        - **Tipo de origem**: Meu IP

    - **HTTP**:
        - **Tipo**: HTTP
        - **Porta**: 80
        - **Tipo de origem**: personalizado
        - **Origem**: grupo de segurança `lbSG`

    - **NFS**:
        - **Tipo**: NFS
        - **Porta**: 2049
        - **Tipo de origem**: personalizado
        - **Origem**: grupo de segurança `efsSG`

3. Clique em "**Salvar regras**".

4. Verifique as "**Regras de saída**":

    - **All traffic**:
        - **Tipo**: Todo o tráfego
        - **Porta**: Tudo
        - **Tipo de destino**: 0.0.0.0/0

---

## 2. Configuração do Security Group do RDS

1. Selecione o grupo de segurança do RDS, clique em "**Ações**" e "**Editar regras de entrada**".

2. Em "**Regras de entrada**", clique em "**Adicionar regra**". Adicione a seguinte regra:

    - **MySQL/Aurora**:
        - **Tipo**: MySQL/Aurora
        - **Porta**: 3306
        - **Tipo de origem**: personalizado
        - **Origem**: grupo de segurança `ec2SG`

3. Clique em "**Salvar regras**".

4. Verifique as "**Regras de saída**":

    - **MySQL/Aurora**:
        - **Tipo**: MySQL/Aurora
        - **Porta**: 3306
        - **Tipo de destino**: grupo de segurança `ec2SG`

---

## 3. Configuração do Security Group do EFS

1. Selecione o grupo de segurança do EFS, clique em "**Ações**" e "**Editar regras de entrada**".

2. Em "**Regras de entrada**", clique em "**Adicionar regra**". Adicione a seguinte regra:

    - **NFS**:
        - **Tipo**: NFS
        - **Porta**: 2049
        - **Tipo de origem**: personalizado
        - **Origem**: grupo de segurança `ec2SG`

3. Clique em "**Salvar regras**".

4. Verifique as "**Regras de saída**":

    - **NFS**:
        - **Tipo**: NFS
        - **Porta**: 2049
        - **Tipo de destino**: grupo de segurança `ec2SG`

---

## 4. Configuração do Security Group do Load Balancer

1. Selecione o grupo de segurança do Load Balancer, clique em "**Ações**" e "**Editar regras de entrada**".

2. Em "**Regras de entrada**", clique em "**Adicionar regra**". Adicione a seguinte regra:

    - **HTTP**:
        - **Tipo**: HTTP
        - **Porta**: 80
        - **Tipo de origem**: 0.0.0.0/0

3. Clique em "**Salvar regras**".

4. Verifique as "**Regras de saída**":

    - **HTTP**:
        - **Tipo**: HTTP
        - **Porta**: 80
        - **Tipo de destino**: grupo de segurança `ec2SG`
---

## Relational Database Services (RDS)

1. Na barra de pesquisa do console AWS, procure por "**RDS**".

2. Na página inicial do serviço, clique em "**Criar banco de dados**". 

3. Selecione "**Criação padrão**".

4. Em "**Opções de mecanismo**", selecione o banco de dados "**MySQL**" e escolha a versão de mecanismo mais recente.

5. Em "**Modelos**", selecione "**Nível gratuito**".

6. Em "**Configurações**", dê um nome descritivo à instância do banco de dados.

7. Em "**Configurações de credenciais**", digite um nome de usuário para a instância do banco de dados. Esse será o ID do usuário principal do banco de dados.

8. Em "**Gerenciamento de credenciais**", selecione "**Autogerenciada**". Nessa opção você irá criar uma senha.

9. Em "**Configuração da instância**", selecione "**db.t3.micro**".

10. Em "**Armazenamento**", deixe igual da imagem.
    
![img](images/rds1.png)

#### 5.2 Configurações de Rede

1. Em "**Conectividade**", selecione "**Não se conectar a um recurso de computação do EC2**". Iremos configurar a conexão às instâncias do EC2 manualmente mais tarde.

2. Em "**Nuvem privada virtual (VPC)**", selecione a VPC criada para o projeto.

3. Em "**Grupo de sub-redes de banco de dados**", selecione a opção "**Criar novo grupo de sub-redes do banco de dados**".

4. Em "**Acesso público**", selecione a opção "**Não**".

5. Em "**Grupo de segurança de VPC (firewall)**", selecione a opção "**Selecionar existente**", e, em "**Grupos de segurança da VPC existentes**", selecione o **grupo de segurança do RDS** criado anteriormente.

6. Em "**Zona de disponibilidade**", selecione a opção "**Sem preferência**".

#### 5.3 Configurações de Autenticação 

1. Em "**Autenticação de banco de dados**", selecione a opção "**Autenticação de senha**".

#### 5.4 Configurações Adicionais

1. Em "**Nome do banco de dados inicial**", dê um nome descritivo ao banco de dados.

![img](images/rds2.png)


2. Mantenha as demais configurações (Criptografia, Logs, etc.) padrão.

3. Em "**Custos mensais estimados**", revise as informações e certifique-se de que o uso se enquadra no nível gratuito.

4. Se tudo estiver conforme configurado nas etapas anteriores, clique em "**Criar banco de dados**".
   
---

## Elastic File System (EFS)

1. Abra o painel principal da AWS e pesquise por `EFS`.
2. Clique em `File systems` > `Create file system`.
3. Nomeie como `FS-Project2` e selecione a VPC criada anteriormente.

**Configuração de Subnets**:
- Escolha as subnets privadas da VPC (ex.: `us-east-1a` e `us-east-1b`).
- Security Group: `efs_SG`.

Por fim, clique em `Create`.

> **Importante**: Anote o ID do EFS, pois será utilizado no UserData.

---

## Key Pairs (KP)

1. Abra o painel principal da AWS e pesquise por `Key pairs`.
2. Clique em `Create key pairs`.
3. Nomeie como `key-project2`, selecione `RSA` e `.pem`.

---

## Launch Template (LT)

1. Abra o painel principal da AWS e pesquise por `EC2`.
2. Clique em `Launch templates` > `Create launch template`.

**Configurações**:
- **Nome:** `MyTemplateWordPress`
- **AMI:** `Amazon Linux`.
- **Tipo de instância:** `t2.micro`.
- **Key Pair:** `key-project2`.
- **Security Group:** `ec2_SG`.

**UserData**:
```bash
#!/bin/bash
# Script de inicialização da instância
EFS_FILE_SYSTEM_ID="<seu_file_id_aqui>"
DB_HOST="<seu_host_do_banco_de_dados_aqui>"
DB_NAME="<seu_nome_do_banco_de_dados_aqui>"
DB_USER="<seu_usuario_do_banco_aqui>"
DB_PASSWORD="<sua_senha_do_banco_aqui>"

# Instalação e configuração do Docker
yum update -y
yum install -y docker
service docker start
systemctl enable docker
usermod -a -G docker ec2-user

# Docker Compose
curl -SL https://github.com/docker/compose/releases/download/v2.34.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Montagem do EFS
yum install -y amazon-efs-utils
mkdir -p /mnt/efs
mount -t efs ${EFS_FILE_SYSTEM_ID}:/ /mnt/efs
echo "${EFS_FILE_SYSTEM_ID}:/ /mnt/efs efs defaults,_netdev 0 0" >> /etc/fstab
```

Clique em `Create launch template`.

---

## Load Balancer (LB)

1. Abra o painel principal da AWS e pesquise por `Load Balancers`.
2. Clique em `Create load balancer` > `Classic Load Balancer`.
3. Configure como `Internet-facing` e selecione as subnets **públicas**.
4. Associe o Security Group: `lb_SG`.
5. Configure o `Ping Path` como `/wp-admin/install.php`.

Por fim, clique em `Create load balancer`.

---

## Auto Scaling Group (ASG)

1. Abra o painel principal da AWS e pesquise por `Auto scaling groups`.
2. Clique em `Create Auto Scaling group`.

**Configurações**:
- **Nome:** `ASG-Project2`.
- **Launch Template:** Selecione o template criado anteriormente.
- **VPC:** Selecione a criada anteriormente.
- **Subnets:** Escolha as subnets **privadas**.
- **Load Balancer:** Selecione o Load Balancer criado anteriormente.

**Configuração de Capacidade**:
- **Desired capacity:** `2`.
- **Min desired capacity:** `2`.
- **Max desired capacity:** `4`.

**Outras Configurações**:
- Habilite `Elastic Load Balancing health checks`.
- Configure o Health Check Grace Period conforme necessário (padrão: `300` segundos).
- Marque o checkbox para habilitar `group metrics collection within CloudWatch`.

Por fim, clique em `Create Auto Scaling group`.

---
