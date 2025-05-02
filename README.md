# Projeto 2 AWS-Docker

## Introdução 

Este projeto tem como objetivo a implementação de uma infraestrutura na AWS para hospedar uma aplicação WordPress utilizando contêineres Docker, garantindo alta disponibilidade, escalabilidade e gerenciamento eficiente dos recursos. A solução inclui a instalação e configuração do Docker em instâncias EC2, com a automação do processo via script de inicialização. A aplicação WordPress é executada em contêineres, com o banco de dados MySQL gerenciado pelo Amazon RDS. Além disso, o projeto contempla a configuração do Amazon EFS para o armazenamento de arquivos estáticos compartilhados entre instâncias EC2, e o uso de um Load Balancer da AWS para distribuir o tráfego, assegurando disponibilidade e resiliência.

---

### **Passo 1: Criação da VPC**
1. Acesse o **Console da AWS**.
2. Navegue até **VPC** no menu de serviços.
3. Clique em **"Create VPC"** (ou **"Criar VPC"** em português).
4. Preencha os seguintes campos:
   - **Name tag**: Dê um nome para a sua VPC, como `wordpress-vpc`.
   - **IPv4 CIDR block**: Defina o bloco de IPs da sua VPC. Por exemplo, `10.0.0.0/16` (abrange IPs de 10.0.0.0 a 10.0.255.255).
   - **IPv6 CIDR block**: Se não for usar IPv6, deixe como **None**.
   - **Tenancy**: Escolha **Default**, a menos que precise de instâncias dedicadas.
5. Clique em **"Create VPC"**.

---

### **Passo 2: Criação de Subnets**
Agora vamos criar sub-redes para dividir a VPC em zonas de disponibilidade (Availability Zones).

1. Navegue até **Subnets** no menu lateral.
2. Clique em **"Create Subnet"**.
3. Preencha os seguintes campos:
   - **Name tag**: Nome da sub-rede, como `wordpress-subnet-public`.
   - **VPC**: Selecione a VPC criada no passo anterior (`wordpress-vpc`).
   - **Availability Zone**: Escolha uma zona, como `us-east-1a`.
   - **IPv4 CIDR block**: Atribua um bloco menor, como `10.0.1.0/24`.
4. Clique em **"Create Subnet"**.
5. Repita o processo para criar uma **sub-rede privada**:
   - Nome: `wordpress-subnet-private`.
   - Availability Zone: Escolha outra zona, como `us-east-1b`.
   - IPv4 CIDR block: Por exemplo, `10.0.2.0/24`.

---

### **Passo 3: Configuração da Internet Gateway**
1. No menu lateral, clique em **Internet Gateways**.
2. Clique em **"Create Internet Gateway"**.
3. Nomeie o gateway, como `wordpress-igw`.
4. Clique em **"Attach to VPC"** e selecione a VPC criada (`wordpress-vpc`).

---

### **Passo 4: Configuração de Tabelas de Rotas**
1. Navegue até **Route Tables**.
2. Crie uma tabela de rotas pública:
   - Nome: `wordpress-public-route`.
   - VPC: Selecione `wordpress-vpc`.
3. Adicione uma rota para a internet:
   - **Destination**: `0.0.0.0/0`.
   - **Target**: Selecione o **Internet Gateway** (`wordpress-igw`).
4. Associe a tabela à sub-rede pública:
   - Clique em **"Subnet Associations"**.
   - Selecione `wordpress-subnet-public`.

---

### **Passo 5: Rota para Sub-rede Privada**
1. Crie outra tabela de rotas para a sub-rede privada (se necessário no futuro, pode utilizar NAT Gateway):
   - Nome: `wordpress-private-route`.
   - VPC: Selecione `wordpress-vpc`.
2. Associe a tabela à sub-rede privada:
   - Clique em **"Subnet Associations"**.
   - Selecione `wordpress-subnet-private`.

---


Vamos detalhar os passos **1.3 - Associar Tabelas de Rotas** e **1.4 - Criar o Internet Gateway e o NAT Gateway**.

---

### **Passo 1.3: Associar Tabelas de Rotas**
As tabelas de rotas definem como o tráfego de rede é roteado dentro da VPC. Aqui você configurará uma tabela para a **sub-rede pública** e outra para a **sub-rede privada**.

#### **Tabela de Rotas Pública**
Esta tabela de rotas será usada para a **sub-rede pública**. Ela permite que recursos (como o Load Balancer ou o NAT Gateway) nesta sub-rede sejam acessíveis diretamente pela internet.

1. **Criar a Tabela de Rotas Pública**:
   - No console da AWS, vá para o serviço **VPC** → **Route Tables**.
   - Clique em **Create Route Table**.
   - **Nome**: `wordpress-public-route`.
   - **VPC**: Escolha a VPC que você criou (`wordpress-vpc`).
   - Clique em **Create Route Table**.

2. **Editar Rotas**:
   - Após criar a tabela, selecione a tabela `wordpress-public-route`.
   - Na aba **Routes**, clique em **Edit routes**.
   - Adicione uma rota:
     - **Destination (Destino)**: `0.0.0.0/0` (toda a internet).
     - **Target (Alvo)**: Selecione o **Internet Gateway** associado à sua VPC.
   - Clique em **Save changes**.

3. **Associar a Sub-rede Pública**:
   - Na tabela de rotas `wordpress-public-route`, vá para a aba **Subnet associations**.
   - Clique em **Edit subnet associations**.
   - Selecione a sub-rede pública (`wordpress-subnet-public`).
   - Clique em **Save changes**.

---

#### **Tabela de Rotas Privada**
Esta tabela de rotas será usada para a **sub-rede privada**. Ela permite que as instâncias nessa sub-rede acessem a internet de forma indireta usando o **NAT Gateway**.

1. **Criar a Tabela de Rotas Privada**:
   - No console da AWS, vá para **Route Tables**.
   - Clique em **Create Route Table**.
   - **Nome**: `wordpress-private-route`.
   - **VPC**: Escolha a VPC que você criou (`wordpress-vpc`).
   - Clique em **Create Route Table**.

2. **Editar Rotas**:
   - Após criar a tabela, selecione a tabela `wordpress-private-route`.
   - Na aba **Routes**, clique em **Edit routes**.
   - Adicione as seguintes rotas:
     - **Destination (Destino)**: `10.0.0.0/16` (ou o CIDR da sua VPC).
       - **Target (Alvo)**: `local` (rota padrão para comunicação dentro da VPC).
     - **Destination (Destino)**: `0.0.0.0/0`.
       - **Target (Alvo)**: Selecione o **NAT Gateway** criado na sub-rede pública.
   - Clique em **Save changes**.

3. **Associar a Sub-rede Privada**:
   - Na tabela de rotas `wordpress-private-route`, vá para a aba **Subnet associations**.
   - Clique em **Edit subnet associations**.
   - Selecione a sub-rede privada (`wordpress-subnet-private`).
   - Clique em **Save changes**.

---

### **Passo 1.4: Criar o Internet Gateway e o NAT Gateway**
Esses componentes são necessários para permitir que recursos específicos na VPC possam rotear tráfego para a internet.

#### **Internet Gateway**
O Internet Gateway é usado para conectar a VPC à internet e fornecer acesso direto a recursos em sub-redes públicas.

1. **Criar o Internet Gateway**:
   - No console da AWS, vá para **VPC** → **Internet Gateways**.
   - Clique em **Create Internet Gateway**.
   - **Nome**: `wordpress-igw`.
   - Clique em **Create Internet Gateway**.

2. **Associar o Internet Gateway à VPC**:
   - Selecione o Internet Gateway `wordpress-igw`.
   - Clique em **Actions** → **Attach to VPC**.
   - Escolha a VPC `wordpress-vpc` e clique em **Attach Internet Gateway**.

---

#### **NAT Gateway**
O NAT Gateway permite que instâncias em sub-redes privadas acessem a internet para atualizações ou downloads, mas impede que elas sejam acessadas diretamente da internet.

1. **Criar o NAT Gateway**:
   - No console da AWS, vá para **VPC** → **NAT Gateways**.
   - Clique em **Create NAT Gateway**.
   - **Subnet**: Selecione a sub-rede pública (`wordpress-subnet-public`).
   - **Elastic IP**: Aloque um novo Elastic IP ou use um existente.
   - Clique em **Create NAT Gateway**.

2. **Associar o NAT Gateway à Tabela de Rotas Privada**:
   - Volte para a tabela de rotas `wordpress-private-route`.
   - Na aba **Routes**, clique em **Edit routes**.
   - Adicione uma rota:
     - **Destination (Destino)**: `0.0.0.0/0`.
     - **Target (Alvo)**: Selecione o NAT Gateway recém-criado.
   - Clique em **Save changes**.

---

### **Resumo**
- **Sub-rede pública**: Usa o Internet Gateway para acesso direto à internet.
- **Sub-rede privada**: Usa o NAT Gateway para acesso indireto à internet.


Sim, é recomendável criar um **Security Group específico para o Load Balancer (ALB)**. Isso ajuda a separar as regras de segurança do Load Balancer e das instâncias EC2, tornando a configuração mais organizada e segura. 

---

### **Configuração do Security Group para o Load Balancer**
Aqui está como você deve configurar o **Security Group do ALB**:

#### 1. **Criar um Security Group**
1. Vá para o console da AWS e abra o serviço **EC2**.
2. No menu lateral, clique em **Security Groups**.
3. Clique em **Create Security Group**.
4. Configure os seguintes detalhes:
   - **Nome**: `wordpress-alb-sg`.
   - **Descrição**: Security Group para o Load Balancer do WordPress.
   - **VPC**: Selecione a mesma VPC onde o Load Balancer e as instâncias EC2 estão configurados (`wordpress-vpc`).

#### 2. **Adicionar Regras de Entrada (Inbound Rules)**
Essas regras permitem que o Load Balancer receba tráfego externo na porta 80 (HTTP) e 443 (HTTPS):

- **Regra 1 (HTTP)**:
  - **Tipo**: HTTP
  - **Protocolo**: TCP
  - **Porta**: 80
  - **Origem**: `0.0.0.0/0` (permitir tráfego de qualquer lugar).

- **Regra 2 (HTTPS)**:
  - **Tipo**: HTTPS
  - **Protocolo**: TCP
  - **Porta**: 443
  - **Origem**: `0.0.0.0/0` (permitir tráfego de qualquer lugar).

> **Nota**: Se você quiser restringir o acesso a uma faixa de IP específica (como para um intranet ou uma rede restrita), substitua `0.0.0.0/0` pela faixa de IP desejada.

#### 3. **Adicionar Regras de Saída (Outbound Rules)**
O Load Balancer precisa se comunicar com as instâncias EC2 para rotear as requisições. Por padrão, o tráfego de saída é permitido para qualquer destino, então não há necessidade de modificar as regras de saída.

---

### **Configuração do Security Group para as Instâncias EC2**
As instâncias EC2 que estão atrás do Load Balancer devem aceitar tráfego **somente do Load Balancer**. Configure o **Security Group das Instâncias EC2** com as seguintes regras:

#### Regras de Entrada (Inbound Rules):
- **Regra 1 (HTTP)**:
  - **Tipo**: HTTP
  - **Protocolo**: TCP
  - **Porta**: 80
  - **Origem**: O **Security Group do Load Balancer** (`wordpress-alb-sg`).

- **Regra 2 (SSH)**:
  - **Tipo**: SSH
  - **Protocolo**: TCP
  - **Porta**: 22
  - **Origem**: Seu IP público (ex.: `203.0.113.25/32`).

#### Regras de Saída (Outbound Rules):
- Permita todo o tráfego de saída (`0.0.0.0/0`) para permitir que as instâncias acessem a internet via NAT Gateway.

---

### **Resumo**
- **Load Balancer**: Um Security Group (`wordpress-alb-sg`) que permite tráfego HTTP/HTTPS de qualquer lugar.
- **Instâncias EC2**: Um Security Group que permite tráfego somente do **Security Group do Load Balancer**.

Após configurar o Security Group do Load Balancer, você pode associá-lo ao ALB durante a criação ou edição do Load Balancer. Me avise se precisar de ajuda com isso! 😊
