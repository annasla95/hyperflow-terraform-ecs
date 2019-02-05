## set region
provider "aws" {
  region = "${var.ecs_region}"
}

##First instance for hosting master container
resource "aws_instance" "hyperflowmaster" {
  ami                    = "${var.ecs_ami_id}"
  instance_type               = "${var.launch_config_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.app.name}"

  vpc_security_group_ids = ["${aws_security_group.sg-hyperflow.id}"]
  tags {
    Name = "terraform-hyperflowmaster"
  }

  key_name="${var.key_pair_name}"
  user_data = "#!/bin/bash\necho ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config && docker run --net=host -p 3001:3001 -e DISK_DEVICE='xvda1' -e INTERFACE='eth0' -e METRIC_COLLECTOR='${local.influx_db_url}'  ${var.ec2_status_reporter} &"
}

## LaunchConfig
## definition for ec2 instances in autoscaling group
resource "aws_launch_configuration" "ecs-test-hyperflow-alc" {
  name = "${var.ecs_cluster_name}-LaunchConfig"
  security_groups = [
    "${aws_security_group.sg-hyperflow.id}",
  ]

  key_name = "${var.key_pair_name}"
  image_id                    = "${var.ecs_ami_id}"
  instance_type               = "${var.launch_config_instance_type}"
  associate_public_ip_address = false
  iam_instance_profile = "${aws_iam_instance_profile.app.name}"
  user_data = "#!/bin/bash\necho ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config && docker run --net=host -p 3001:3001 -e DISK_DEVICE='xvda1' -e INTERFACE='eth0'  -e METRIC_COLLECTOR='${local.influx_db_url}'  ${var.ec2_status_reporter} &"

  lifecycle {
    create_before_destroy = true
  }
}

## ECS Cluster
resource "aws_ecs_cluster" "hyperflow_cluster" {
  name = "${var.ecs_cluster_name}"
}

resource "aws_instance" "prometheus-pushgateway" {
  ami             = "ami-0f9cf087c1f27d9b1"
  instance_type   = "t2.micro"
  key_name        = "${var.key_pair_name}"
  security_groups = [
    "${aws_security_group.hyperflow-prometheus-pushgateway.name}"
  ]
  tags {
    Name = "prometheus-pushgateway"
  }

  provisioner "file" {
    source      = "conf/install_docker.sh"
    destination = "/tmp/install_docker.sh"

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file(var.ssh_private_key_path)}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install_docker.sh",
      "/tmp/install_docker.sh",
      "sudo docker run -d -p 9091:9091 prom/pushgateway",
    ]
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file(var.ssh_private_key_path)}"
    }
  }
}

resource "aws_instance" "prometheus-grafana" {
  ami             = "ami-0f9cf087c1f27d9b1"
  instance_type   = "t2.micro"
  key_name        = "${var.key_pair_name}"
  security_groups = [
    "${aws_security_group.hyperflow-prometheus-grafana.name}"
  ]
  tags {
    Name = "prometheus-grafana"
  }

  provisioner "file" {
    source      = "conf/install_docker.sh"
    destination = "/tmp/install_docker.sh"

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file(var.ssh_private_key_path)}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install_docker.sh",
      "/tmp/install_docker.sh",
      "git clone https://github.com/annasla95/hyperflow-grafana.git",
      "cd hyperflow-grafana-prometheus/",
      "sudo HYPERFLOW_HOST=${aws_instance.hyperflowmaster.public_ip} PROMETHEUS_GATEWAY_HOST=${aws_instance.prometheus-pushgateway.public_ip} docker-compose up -d",
    ]
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file(var.ssh_private_key_path)}"
    }
  }
}

resource "aws_instance" "influx-grafana" {
  ami             = "ami-0f9cf087c1f27d9b1"
  instance_type   = "t2.micro"
  key_name        = "${var.key_pair_name}"
  security_groups = [
    "${aws_security_group.hyperflow-influx-grafana.name}"
  ]
  tags {
    Name = "influx-grafana"
  }

  provisioner "file" {
    source      = "conf/install_docker.sh"
    destination = "/tmp/install_docker.sh"

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file(var.ssh_private_key_path)}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install_docker.sh",
      "/tmp/install_docker.sh",
      "git clone https://github.com/krystianpawlik/hyperflow-grafana.git --recurse-submodules",
      "cd hyperflow-grafana/",
      "sudo docker-compose up -d",
    ]
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file(var.ssh_private_key_path)}"
    }
  }
}