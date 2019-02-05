output "hyperflow_master_address" {
  value = "${aws_instance.hyperflowmaster.public_dns}"
}

output "prometheus-pushgateway-public-ip" {
  value = "${aws_instance.prometheus-pushgateway.public_ip}"
}

output "prometheus-grafana-public-ip" {
  value = "${aws_instance.prometheus-grafana.public_ip}"
}

output "influx-grafana-public-ip" {
  value = "${aws_instance.influx-grafana.public_ip}"
}