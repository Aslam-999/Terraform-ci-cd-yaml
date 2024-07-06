#Resource group name
resource "azurerm_resource_group" "rg" {
    name = "${var.rgname}"
    location = "${var.rglocation}"
  
}
#virtual network
resource "azurerm_virtual_network" "Vnet" {
   name = "${var.Vnetname}"
   address_space = ["${var.address}"]
   location = "${azurerm_resource_group.rg.location}"
   resource_group_name = "${azurerm_resource_group.rg.name}"
}
# Subnet
resource "azurerm_subnet" "Subnet" {
    name = "${var.subnet}"
    virtual_network_name = "${azurerm_virtual_network.Vnet.name}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    address_prefixes = ["${var.subnetaddress}"]
}
# Network Security Group

resource "azurerm_network_security_group" "NSG" {
  name = "${var.Nsgname}"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_network_security_rule" "NSGrule" {
  name                        = "AllowAnySSHInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.NSG.name}"

}
# Associate NSG with Subnet

resource "azurerm_subnet_network_security_group_association" "subNSG" {
    network_security_group_id = "${azurerm_network_security_group.NSG.id}"
    subnet_id = "${azurerm_subnet.Subnet.id}"

}
# Public IP Address  

resource "azurerm_public_ip" "Publicip" {
  name                = "Aslampip"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  allocation_method   = "Static"
}
# Network Interface

resource "azurerm_network_interface" "NIC" {
  name                = "AslamNIC"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "${azurerm_subnet.Subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.Publicip.id
  }
}
# Virtual Machine

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "${var.vmname}"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_DS1_v2"
  admin_username        = "${var.Vmusername}"
  admin_password        = "${var.vmpassword}" 
  network_interface_ids = [azurerm_network_interface.NIC.id]
  disable_password_authentication = "false" 

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
