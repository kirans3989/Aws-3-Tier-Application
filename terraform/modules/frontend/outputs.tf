output "alb_dns_name" {
  value = aws_lb.web.dns_name
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.main.domain_name
}