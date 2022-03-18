variable "image_name" {
  default = "hvijay-20220127151804"
}

variable "instance_name" {
  default = "hvijay-cvo-sn"
}

variable "instance_zone" {
  default = "us-east-1"
}

variable "ssh_key_name" {
  default = "yanbeikeyo"
}

variable "instance_profile_name" {
  default = "bx2-8x32"
}

variable "volume_profile_name" {
  default = "custom"
}

variable "vpc_name" {
  default = "netapp-hcl-openlab-vpc"
}

variable "security_group_name" {
  default = "props-earthling-percolate-sage"
}

variable "subnet_name" {
  default = "netapp-hcl-subnet1"
}

variable "data_volumes" {
  type     = list(string)
  default  = ["vdata1"]
}

data "ibm_is_vpc" "vpc" {
    name = var.vpc_name
}

data "ibm_is_security_group" "sg1" {
    name = var.security_group_name
}

data "ibm_is_subnet" "subnet1" {
    name = var.subnet_name
}

data "ibm_is_image" "debian-10-amd64" {
    name = var.image_name
}

data "ibm_is_ssh_key" "ssh_key_id" {
    name = var.ssh_key_name
}

resource "ibm_is_instance_template" "cvo_sn_template2" {
  name      = "hvijay-cvo-sn-template"
  vpc       = data.ibm_is_vpc.vpc.id
  zone      = var.instance_zone
  metadata_service_enabled = true
  keys      = [data.ibm_is_ssh_key.ssh_key_id.id]
  image     = data.ibm_is_image.debian-10-amd64.id
  profile   = var.instance_profile_name

  primary_network_interface {
      name            = "eth0"
      subnet          = data.ibm_is_subnet.subnet1.id
      security_groups = [data.ibm_is_security_group.sg1.id]
  }
  network_interfaces {
      name            = "eth1"
      subnet          = data.ibm_is_subnet.subnet1.id
      security_groups = [data.ibm_is_security_group.sg1.id]
  }
  network_interfaces {
      name            = "eth2"
      subnet          = data.ibm_is_subnet.subnet1.id
      security_groups = [data.ibm_is_security_group.sg1.id]
  }
  network_interfaces {
      name            = "eth3"
      subnet          = data.ibm_is_subnet.subnet1.id
      security_groups = [data.ibm_is_security_group.sg1.id]
  }
  network_interfaces {
      name            = "eth4"
      subnet          = data.ibm_is_subnet.subnet1.id
      security_groups = [data.ibm_is_security_group.sg1.id]
  }

  volume_attachments {
      name                             = "core"
      delete_volume_on_instance_delete = true
      volume_prototype {
          iops = 3000
          profile = "custom"
          capacity = 100
      }
  }
  volume_attachments {
      name                             = "rootfs"
      delete_volume_on_instance_delete = true
      volume_prototype {
          iops = 6000
          profile = "custom"
          capacity = 400
      }
  }
  user_data = "bootarg.exclude_disks=vtbd3,vtbd4"
}

resource "ibm_is_instance" "sn_instance2" {
  name                = var.instance_name
  metadata_service_enabled = true
  instance_template   = ibm_is_instance_template.cvo_sn_template2.id
}

resource "ibm_is_volume" "data_volumes2" {
  count    = length(var.data_volumes)
  name     = var.data_volumes[count.index]
  profile  = var.volume_profile_name
  zone     = var.instance_zone
  iops     = 6000
  capacity = 200
}

resource "ibm_is_instance_volume_attachment" "data_vols_att1" {
  instance = ibm_is_instance.sn_instance2.id

  count    = length(var.data_volumes)
  name     = var.data_volumes[count.index]
  volume = ibm_is_volume.data_volumes2[count.index].id

  delete_volume_on_attachment_delete = false
  delete_volume_on_instance_delete = true
}
