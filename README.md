# terraform-update-research
Research on the flow when updating a terraform module source, terraform variables

The first module creates the following local-file resources:
 - resources/<filename>.old
 - resources/<filename>.same
 - resources/<filename>-v1.diff

A second module creates the following local-fie resources in v2:
 - resources/<filename>.same
 - resources/<filename>-v2.diff
 - resources/<filename>.new

This is intended to cover the 4 possible cases of a resource when a Terraform
module source is changed from the first to second module:
 a. A resource is in the first module but no longer in the second module (.old)
 b. A resource is not in the first module but in the second module (.new)
 c. A resource is in the first and second module and are the same (.same)
 d. A resource is in the first and second module but different (.diff)

Note, using a change in module as an example to capture the possible cases.
Variations of these cases can also happen due to other types of changes:
 - Changes in values in .tfvars files
 - Same module but different versions
 - Different provider instances (not as applicable for local provider)


When switching from the first to second module, the action needed to be taken on resources of case b (.new) is straight-forward: create the resources. The action
for resources of case c (.same) are also relatively straight-forward: keep the
existing resources as is.

However, the action needed to be taken on resources of case a (.old) and
case c (.diff) can depend on the need of the person updating the module:
 - Case a (.old)
     - delete the resource (default) (Scenario: Do Nothing)
     - keep the resource and move it out of the Terraform state (custom)
     (Scenario: State Remove Old Resource)
 - Case c (.diff)
     - update the existing resource with the updated specifications (default)
     - keep existing resources as is and create a new resource with updated
     specifications (custom) (Scenario: State Remove Diff Resource)

This research is intended to investigate and understand what happens when we want to
make updates to our main Terraform manifest will cause changes in the resources.
It intends to try out different actions between updating a module.

**Scenario: Do nothing**

1. Terraform init `make init`
1. Create workspace `make ws`
1. Apply the first module: `make apply`
1. Observe files in resources directory: web-v1.diff, web.old, web.same
1. Modify main.tf module source from "./modules/localv1" = > "./modules/localv2"
1. `make init` (skipping this step will lead to an error: "Error: Module source has changed")
1. Apply the second module: `make apply`
    - .diff is marked as replacement (destroyed and recreated)
    - .new is marked as create
    - .old is marked as delete
1. Observe files in resources directory: web-v2.diff, web.new, web.same
1. Cleanup `make cleanup`
1. Change main.tf module source back to "./modules/localv1"

Conclusion: When there is no cleanup between changing modules, this successfully
proceeds with default Terraform resource action

**Scenario: Delete statefile**

1. Terraform init `make init`
1. Create workspace `make ws`
1. Apply the first module: `make apply`
1. Observe files in resources directory: web-v1.diff, web.old, web.same
1. Modify main.tf module source from "./modules/localv1" = > "./modules/localv2"
1. _Delete terraform.tfstate.d/update-testing/terraform.tfstate_
1. `make init`
1. Apply the second module: `make apply`
    - v2.diff is marked as create
    - .new is marked as create
    - .same is marked as create
1. Observe files in resources directory: web-v1.diff, web-v2.diff, web.new,
web.same, web.old
1. Cleanup `make cleanup`
1. Change main.tf module source back to "./modules/localv1"

Conclusion: When the statefile is cleaned-up between changing modules, this orphans
the existing Terraform resources. Even resources that are the same across modules
are created again (and how this duplication is handled depends on the provider).
Cleaning up the statefile (only) should only be used when deleting the Terraform task
and not used while updating to a new module. Currently not seeing a need to support
a cleanup-statefile option when updating

**Scenario: Terraform Destroy**

1. Terraform init `make init`
1. Create workspace `make ws`
1. Apply the first module: `make apply`
1. Observe files in resources directory: web-v1.diff, web.old, web.same
1. _Terraform destroy `terraform destroy -var-file="update.tfvars`_
1. Modify main.tf module source from "./modules/localv1" = > "./modules/localv2"
1. `make init`
1. Apply the second module: `make apply`
    - v2.diff is marked as create
    - .new is marked as create
    - .same is marked as create
1. Observe files in resources directory: web-v2.diff, web.new, web.same
1. Cleanup `make cleanup`
1. Change main.tf module source back to "./modules/localv1"

Conclusion: Destroying between module change ends up with the same result as
doing nothing except for the .diff may be different depending on the provider.
In doing nothing, .diff could be handled as an update or as a delete and create.
While doing a destroy, .diff is handled as a delete and create regardless of
provider. Currently not seeing a need to support destroy option when updating

**Scenario: State Remove Old Resource**

1. Terraform init `make init`
1. Create workspace `make ws`
1. Apply the first module: `make apply`
1. Observe files in resources directory: web-v1.diff, web.old, web.same
1. _Terraform state show `terraform state list`_
1. _Terraform state rm `terraform state rm 'module.local.local_file.old_file["web"]'`_
1. Modify main.tf module source from "./modules/localv1" = > "./modules/localv2"
1. `make init`
1. Apply the second module: `make apply`
    - v2.diff is marked as replaced
    - .new is marked as create
1. Observe files in resources directory: web.old, web-v2.diff, web.new, web.same
1. Cleanup `make cleanup`
1. Change main.tf module source back to "./modules/localv1"

Conclusion: Removing .old from the statefile successfully retained the old
resource and prevented it from being destroyed. Currently seeing that supporting
a remove-from-statefile option.

**Scenario: State Remove Diff Resource**

1. Terraform init `make init`
1. Create workspace `make ws`
1. Apply the first module: `make apply`
1. Observe files in resources directory: web-v1.diff, web.old, web.same
1. _Terraform state show `terraform state list`_
1. _Terraform state rm `terraform state rm 'module.local.local_file.diff_file["web"]'`_
1. Modify main.tf module source from "./modules/localv1" = > "./modules/localv2"
1. `make init`
1. Apply the second module: `make apply`
    - v2.diff is marked as create
    - .new is marked as create
    - .old is marked as delete
1. Observe files in resources directory: web-v1.diff, web-v2.diff, web.new, web.same
1. Cleanup `make cleanup`
1. Change main.tf module source back to "./modules/localv1"

Conclusion: Removing .diff from the statefile successfully retained a copy of the
original resource and prevented it from being destroyed. A new copy with updated
specifications was created. Currently (again) seeing that supporting a
remove-from-statefile option.
