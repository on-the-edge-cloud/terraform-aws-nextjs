module "nextjs_ssr" {
  source = "./modules/nextjs-ssr"

  domain              = var.domain
  acm_certificate_arn = var.acm_certificate_arn
  environment         = var.environment
  resource_prefix     = var.resource_prefix
  app_directory       = var.app_directory
  deploy_artifacts    = var.deploy_artifacts
  force_destroy       = var.force_destroy
}