provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# Grupo de Recursos
resource "azurerm_resource_group" "rg_staticsite" {
  name     = "GS-IaC2"
  location = "eastus"
}

# Rede Virtual
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-name"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_staticsite.location
  resource_group_name = azurerm_resource_group.rg_staticsite.name
}

# Sub-rede 1
resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1-name"
  resource_group_name  = azurerm_resource_group.rg_staticsite.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Sub-rede 2
resource "azurerm_subnet" "subnet2" {
  name                 = "subnet2-name"
  resource_group_name  = azurerm_resource_group.rg_staticsite.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Conta de Armazenamento
resource "azurerm_storage_account" "storage_account" {
  name                     = "storacc${random_string.random_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg_staticsite.name
  location                 = azurerm_resource_group.rg_staticsite.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  static_website {
    index_document     = "index.html"
    error_404_document = "error.html"
  }
}

resource "random_string" "random_suffix" {
  length  = 12
  special = false
  upper   = false
  numeric  = false
}

# Blobs para o site estático
resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = "../../app/index.html"
}

resource "azurerm_storage_blob" "error" {
  name                   = "error.html"
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = "../../app/error.html"
}

# Grupos de Segurança de Rede
resource "azurerm_network_security_group" "nsg1" {
  name                = "nsg1-name"
  location            = azurerm_resource_group.rg_staticsite.location
  resource_group_name = azurerm_resource_group.rg_staticsite.name
}

resource "azurerm_network_security_group" "nsg2" {
  name                = "nsg2-name"
  location            = azurerm_resource_group.rg_staticsite.location
  resource_group_name = azurerm_resource_group.rg_staticsite.name
}

# Regras de Grupo de Segurança de Rede
resource "azurerm_network_security_rule" "nsg1_rule" {
  name                         = "HTTP"
  priority                     = 100
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "80"
  source_address_prefix        = "*"
  destination_address_prefix   = "*"
  resource_group_name          = azurerm_resource_group.rg_staticsite.name
  network_security_group_name  = azurerm_network_security_group.nsg1.name
}

resource "azurerm_network_security_rule" "nsg2_rule" {
  name                         = "SSH"
  priority                     = 100
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "22"
  source_address_prefix        = "*"
  destination_address_prefix   = "*"
  resource_group_name          = azurerm_resource_group.rg_staticsite.name
  network_security_group_name  = azurerm_network_security_group.nsg2.name
}

# Associação de Sub-rede ao Grupo de Segurança de Rede
resource "azurerm_subnet_network_security_group_association" "subnet1_nsg" {
  subnet_id                  = azurerm_subnet.subnet1.id
  network_security_group_id  = azurerm_network_security_group.nsg1.id
}

resource "azurerm_subnet_network_security_group_association" "subnet2_nsg" {
  subnet_id                  = azurerm_subnet.subnet2.id
  network_security_group_id  = azurerm_network_security_group.nsg2.id
}

# VMs e Interfaces de Rede (ajuste conforme necessário, adicione mais VMs se necessário)

# Balanceador de Carga
resource "azurerm_public_ip" "lb_pip" {
  name                = "lb-pip-example"
  location            = azurerm_resource_group.rg_staticsite.location
  resource_group_name = azurerm_resource_group.rg_staticsite.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "example" {
  name                = "lb-example"
  location            = azurerm_resource_group.rg_staticsite.location
  resource_group_name = azurerm_resource_group.rg_staticsite.name
  sku                 = "Standard"
  
  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

# Saída para o endereço IP público do balanceador de carga
output "lb_public_ip" {
  value = azurerm_public_ip.lb_pip.ip_address
}
