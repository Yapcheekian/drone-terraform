provider "linode" {
  token = var.linode_token
}

resource "linode_instance" "instance" {
  count           = var.node_count
  region          = var.region
  label           = "${var.label_prefix}-${count.index + 1}"
  group           = var.linode_group
  type            = var.node_type
  authorized_keys = ["${chomp(file(var.ssh_public_key))}"]
  image           = "linode/ubuntu20.10"

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/init-files/"
    ]
    connection {
      host        = self.ip_address
      private_key = chomp(file(var.ssh_private_key))
      timeout     = "300s"
    }
  }
}
