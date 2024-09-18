
locals {
  environments         = ["dev", "qa", "prd"]
  cost_allocation_tags = ["Env"]
}

# cost_allocation_tag
resource "aws_ce_cost_allocation_tag" "main" {
  count   = length(local.cost_allocation_tags)
  tag_key = local.cost_allocation_tags[count.index]
  status  = "Active"
}

module "terraform-state" {
  source = "./modules/terraform-state"
  for_each = toset(local.environments)
  name_prefix = "apollo416-terraform-infra-state"
  env = each.value
}