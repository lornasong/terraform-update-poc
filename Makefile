init:
	terraform init

ws:
	terraform workspace new update-testing

apply:
	terraform apply -var-file="update.tfvars"

cleanup:
	if [ -d "terraform.tfstate.d" ]; then rm -r terraform.tfstate.d; fi
	if [ -d ".terraform" ]; then rm -r .terraform; fi
	if [ -d "resources" ]; then rm -r resources; fi
