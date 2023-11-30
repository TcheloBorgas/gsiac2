resource "azurerm_resource_group" "rg-staticsite" {
  provider = azurerm.cloud
  name     = "GS-IaC-nw"
  location = "eastus"
}


resource "azurerm_virtual_network" "vnet" {
  provider            = azurerm.cloud
  name                = "vnet-name"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg-staticsite.location
  resource_group_name = azurerm_resource_group.rg-staticsite.name
}

resource "azurerm_subnet" "subnet1" {
  provider            = azurerm.cloud
  name                = "subnet1-name"
  resource_group_name = azurerm_resource_group.rg-staticsite.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet2" {
  provider            = azurerm.cloud
  name                = "subnet2-name"
  resource_group_name = azurerm_resource_group.rg-staticsite.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_storage_account" "storage_account" {
  provider                 = azurerm.cloud
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg-staticsite.name
  location                 = azurerm_resource_group.rg-staticsite.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  static_website {
    index_document     = "index.html"
    error_404_document = "error.html"
  }
}
 
resource "azurerm_storage_blob" "index" {
  provider               = azurerm.cloud
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = "../../app/index.html"
}

resource "azurerm_storage_blob" "error" {
  provider               = azurerm.cloud
  name                   = "error.html"
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = "../../app/error.html"
}


# Recursos de Grupo de Segurança de Rede
resource "azurerm_network_security_group" "nsg1" {
  provider            = azurerm.cloud
  name                = "nsg1-name"
  location            = azurerm_resource_group.rg-staticsite.location
  resource_group_name = azurerm_resource_group.rg-staticsite.name
}

resource "azurerm_network_security_group" "nsg2" {
  provider            = azurerm.cloud
  name                = "nsg2-name"
  location            = azurerm_resource_group.rg-staticsite.location
  resource_group_name = azurerm_resource_group.rg-staticsite.name
}

# Regras de Grupo de Segurança de Rede
resource "azurerm_network_security_rule" "nsg1_rule" {
  provider                     = azurerm.cloud
  name                         = "HTTP"
  priority                     = 100
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "80"
  source_address_prefix        = "*"
  destination_address_prefix   = "*"
  resource_group_name          = azurerm_resource_group.rg-staticsite.name
  network_security_group_name  = azurerm_network_security_group.nsg1.name
}

resource "azurerm_network_security_rule" "nsg2_rule" {
  provider                     = azurerm.cloud
  name                         = "SSH"
  priority                     = 100
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "22"
  source_address_prefix        = "*"
  destination_address_prefix   = "*"
  resource_group_name          = azurerm_resource_group.rg-staticsite.name
  network_security_group_name  = azurerm_network_security_group.nsg2.name
}

# Associação de Sub-rede ao Grupo de Segurança de Rede
resource "azurerm_subnet_network_security_group_association" "subnet1_nsg" {
  provider            = azurerm.cloud
  subnet_id           = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

resource "azurerm_subnet_network_security_group_association" "subnet2_nsg" {
  provider            = azurerm.cloud
  subnet_id           = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.nsg2.id
}

# Recurso: Máquina Virtual (exemplo para uma VM)
resource "azurerm_linux_virtual_machine" "vm" {
  provider            = azurerm.cloud
  name                = "vm-example"
  resource_group_name = azurerm_resource_group.rg-staticsite.name
  location            = azurerm_resource_group.rg-staticsite.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  network_interface_ids = [azurerm_network_interface.example.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Recurso: Interface de Rede para a VM
resource "azurerm_network_interface" "example" {
  provider            = azurerm.cloud
  name                = "nic-example"
  location            = azurerm_resource_group.rg-staticsite.location
  resource_group_name = azurerm_resource_group.rg-staticsite.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    // Atribua o grupo de segurança de rede, se necessário
    // network_security_group_id = azurerm_network_security_group.nsg1.id
  }
}

# Recurso: Balanceador de Carga Público
resource "azurerm_public_ip" "lb_pip" {
  provider            = azurerm.cloud
  name                = "lb-pip-example"
  location            = azurerm_resource_group.rg-staticsite.location
  resource_group_name = azurerm_resource_group.rg-staticsite.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "example" {
  provider            = azurerm.cloud
  name                = "lb-example"
  location            = azurerm_resource_group.rg-staticsite.location
  resource_group_name = azurerm_resource_group.rg-staticsite.name
  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

# Saída para o endereço IP público do balanceador de carga
output "lb_public_ip" {
  value = azurerm_public_ip.lb_pip.ip_address
}
