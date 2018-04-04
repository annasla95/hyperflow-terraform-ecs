## hyperflow

## region
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "hyperflowmaster" {

  ami                    = "${var.ecs_ami_id}"
  instance_type               = "${var.launch_config_instance_type}"
  
  iam_instance_profile = "${aws_iam_instance_profile.app.name}"

  vpc_security_group_ids = ["${aws_security_group.sg-hyperflow.id}"]
  tags {
    Name = "terraform-hyperflowmaster"
  }

  key_name="hyperfloweast1"

  user_data = "#!/bin/bash\necho ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config"

}

## LaunchConfig
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
  user_data = "#!/bin/bash\necho ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config"

  lifecycle {
    create_before_destroy = true
  }
}

## ECS Cluster
resource "aws_ecs_cluster" "hyperflow_cluster" {
  name = "${var.ecs_cluster_name}"
}
