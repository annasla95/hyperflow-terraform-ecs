locals {
  influx_db_url = "http://${aws_instance.influx-grafana.public_ip}:8086/hyperflow_tests"
  prometheus_pushgateway_url = "http://${aws_instance.prometheus-pushgateway.public_ip}:9091"
}