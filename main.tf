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

  provisioner "file" {
    source      = "${path.module}/init-files/"
    destination = "/root/init-files/"
    connection {
      host        = self.ip_address
      private_key = chomp(file(var.ssh_private_key))
      timeout     = "300s"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /root/init-files/setup-host.sh && /root/init-files/setup-host.sh"
    ]
    on_failure = continue
    connection {
      host        = self.ip_address
      private_key = chomp(file(var.ssh_private_key))
      timeout     = "600s"
    }
  }

  provisioner "local-exec" {
    command = "./wait_for_ssh root@${self.ip_address}"
  }

  provisioner "remote-exec" {
    inline = [
      "export HOST_IP=\"${self.ip_address}\"",
      "/usr/local/bin/docker-compose -f /root/init-files/drone-agent/docker-compose.yml up -d"
    ]
    connection {
      host        = self.ip_address
      private_key = chomp(file(var.ssh_private_key))
      timeout     = "600s"
    }
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "chmod +x /root/init-files/shutdown-agent.sh && /root/init-files/shutdown-agent.sh",
    ]
    on_failure = continue
    connection {
      host        = self.ip_address
      private_key = chomp(file(var.ssh_private_key))
      timeout     = "3600s"
    }
  }
}
