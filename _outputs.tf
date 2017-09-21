output "alb_target_group" {
  value = "${module.public_layer.default_alb_target_group}"
}

output "alb_dns_name" {
  value = "${module.public_layer.alb_dns_name}"
}
