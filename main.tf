# ---------------------------------------------------------
# BLOCO DE CONFIGURAÇÃO DO TERRAFORM
# ---------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source   = "hashicorp/aws"   # Define que vamos usar o provedor oficial da AWS
      version  = "~> 5.92"         # Usa a versão 5.92 ou superior, mas sem mudar para 6.x
    }
  }

  required_version = ">= 1.13.5"   # Exige que o Terraform instalado seja pelo menos versão 1.13.5
}

# ---------------------------------------------------------
# PROVEDOR AWS
# ---------------------------------------------------------
provider "aws" {
  region = "us-east-2"             # Define a região da AWS (Ohio)
}

# ---------------------------------------------------------
# DATA SOURCE: VPC PADRÃO
# ---------------------------------------------------------
data "aws_vpc" "default" {
  default = true                   # Busca a VPC padrão da conta AWS
}

# ---------------------------------------------------------
# DATA SOURCE: AMI DO UBUNTU
# ---------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true               # Pega sempre a AMI mais recente

  filter {
    name   = "name"                # Filtra pelo nome da imagem
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
                                   # Padrão oficial das imagens do Ubuntu 24.04 (Noble)
  }

  owners = ["099720109477"]        # ID da Canonical (garante que é imagem oficial)
}

# ---------------------------------------------------------
# RECURSO: GRUPO DE SEGURANÇA (SECURITY GROUP)
# ---------------------------------------------------------
resource "aws_security_group" "permitir_ssh" {
  name        = "permitir_ssh"     # Nome do grupo de segurança
  description = "Permitir acesso SSH"
  vpc_id      = data.aws_vpc.default.id   # Associa à VPC padrão

  # Regras de entrada (ingress)
  ingress {
    description = "SSH"            # Descrição da regra
    from_port   = 22               # Porta inicial (22 = SSH)
    to_port     = 22               # Porta final (22 = SSH)
    protocol    = "tcp"            # Protocolo TCP
    cidr_blocks = ["0.0.0.0/0"]    # Permite acesso de qualquer IP (atenção: aberto para o mundo)
  }

  # Regras de saída (egress)
  egress {
    from_port   = 0                # Porta inicial (0 = todas)
    to_port     = 0                # Porta final (0 = todas)
    protocol    = "-1"             # -1 significa todos os protocolos
    cidr_blocks = ["0.0.0.0/0"]    # Permite saída para qualquer IP
  }
}

# ---------------------------------------------------------
# RECURSO: INSTÂNCIA EC2
# ---------------------------------------------------------
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id   # Usa a AMI do Ubuntu buscada acima
  instance_type = "t3.micro"               # Tipo da instância (pequena e barata, ideal para testes)
  key_name      = "teste CI CD" # Nome da chave SSH já cadastrada na AWS

  vpc_security_group_ids = [aws_security_group.permitir_ssh.id]
                                           # Associa o grupo de segurança criado

  tags = {
    Name = "Teste aws"                     # Tag para identificar a instância no console AWS
  }
}