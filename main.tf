
locals {
  environments         = toset(["dev", "qa", "prd"])
  cost_allocation_tags = toset(["Env"])
}

# cost_allocation_tag
resource "aws_ce_cost_allocation_tag" "main" {
  for_each = local.cost_allocation_tags
  tag_key  = each.value
  status   = "Active"
}

module "key" {
  source = "./modules/key"
}

module "terraform_state" {
  for_each    = local.environments
  source      = "./modules/terraform-state"
  name_prefix = var.state_name_prefix
  env         = each.value
  kms_key_id  = module.key.kms_key_id
}
