# App Service infrastructure templates

Captured from the running environment on 2026-09-07. This task generated and
validated templates only: no Azure deployment, Terraform apply, or state import
was performed.

## Scope and current values

| Setting | Current value |
| --- | --- |
| Subscription | `ceb68e54-82cc-47aa-999a-18821f56cf54` |
| Tenant | `16b3c013-d300-468d-ac64-7eda0820b6d3` |
| Resource group | `rg-cc-vscode-comparison` |
| Region | `japanwest` |
| Plan | `cc-vscode-demo-plan-hf4i4u2mifhpi`, Linux B1, one instance |
| Web App | `cc-vscode-demo-web-hf4i4u2mifhpi` |
| Runtime and startup | Node.js 24 LTS, `node index.js` |
| Network | Public HTTPS, HTTP/2, minimum TLS 1.2 (app and SCM) |
| Other settings | Always On, client affinity, system-assigned identity |
| Publishing | FTPS disabled; FTP and SCM basic authentication disabled |
| Plan and app tags | `SecurityControl=Ignore` |

The resource group has no tags. The app has no VNet, database, external service
dependencies, custom domain, or data-plane role assignments. `/health` exists
in the application, but the App Service Health Check feature is not configured
in the live environment, so these templates do not enable it.

The two known application settings are `SCM_DO_BUILD_DURING_DEPLOYMENT=true` and
`WEBSITE_NODE_DEFAULT_VERSION=~24`. Their values came from the deployment source
and were confirmed unchanged by the Terraform import preview. Do not put secrets
in these files. Generated IP addresses, credentials, identity principal IDs,
deployment history, and platform-generated metadata are not template inputs.

## Files

- [main.bicep](main.bicep): existing resource-group scope; retains the original
  direct-resource structure, with explicit names and security settings.
- [main.bicepparam](main.bicepparam): current environment values.
- [subscription.bicep](subscription.bicep): creates the resource group and calls
  the same Bicep module, for a complete environment.
- [subscription.bicepparam](subscription.bicepparam): current values for that entry point.
- [terraform/main.tf](terraform/main.tf): resource group, plan, and Linux Web App.
- [terraform/variables.tf](terraform/variables.tf): reusable inputs.
- [terraform/versions.tf](terraform/versions.tf): AzureRM `~> 5.4.0`, Terraform 1.5+.
- [terraform/outputs.tf](terraform/outputs.tf): resource IDs, app name, HTTPS URL, identity ID.
- [terraform/current.tfvars.example](terraform/current.tfvars.example): current non-secret values.
- [terraform/imports.tf.example](terraform/imports.tf.example): optional adoption of existing resources.

Keep `terraform/.terraform.lock.hcl` in version control. It pins the verified
AzureRM 5.4.0 provider and its checksums. All provider documentation used here
comes from the public HashiCorp registry.

## Safety and ownership

- Use **one** management tool per environment. Do not alternately apply Bicep
  and Terraform to the same resources after adopting them into Terraform state.
- Both templates default public access to disabled and tags to empty. The
  current-environment examples explicitly reproduce the previously approved
  public access and policy-exception tag. That tag bypasses organizational
  controls: do not reuse it elsewhere without approval. Removing it may cause
  policy to disable access to both the app and deployment endpoint.
- B1 incurs ongoing charges, including when the Web App is stopped.
- Existing names identify the live environment. For an independent environment,
  change the resource group, plan name, and globally unique web app name.
- No remote state storage is created. Before shared use, configure an encrypted,
  access-controlled remote Terraform backend with locking. Local state and saved
  plans may contain secrets even when source files do not; never commit them.
- Automatic Azure resource-provider registration is disabled in Terraform to
  keep previews read-only. A new subscription must have `Microsoft.Web`
  registered by an authorized administrator before provisioning.

## Bicep

Run from the repository root with a current Azure CLI, Bicep, and an authenticated
identity authorized for the target subscription. These commands do not apply changes:

```bash
export AZURE_SUBSCRIPTION_ID=ceb68e54-82cc-47aa-999a-18821f56cf54
az bicep build --file infra/main.bicep --stdout > /dev/null
az bicep build-params --file infra/main.bicepparam --stdout > /dev/null
az bicep build --file infra/subscription.bicep --stdout > /dev/null
az bicep build-params --file infra/subscription.bicepparam --stdout > /dev/null

az deployment group what-if \
  --subscription "$AZURE_SUBSCRIPTION_ID" \
  --resource-group rg-cc-vscode-comparison \
  --template-file infra/main.bicep --parameters infra/main.bicepparam
```

For a separate environment, edit the subscription parameter file with new names,
review its public-access settings, then preview the complete environment:

```bash
az deployment sub what-if \
  --subscription "$AZURE_SUBSCRIPTION_ID" --location japanwest \
  --template-file infra/subscription.bicep \
  --parameters infra/subscription.bicepparam
```

Only after approving that preview, provisioning can be performed by replacing
`what-if` with `create`. The deployment location stores subscription deployment
metadata; the parameter `location` determines the resource region. Do not use
complete deployment mode. Names and locations are not safe migration switches
for an already populated environment.

## Terraform

Run from the repository root. Azure CLI authentication is used locally; no
client secret or access token is stored in variables.

```bash
terraform -chdir=infra/terraform init
terraform -chdir=infra/terraform fmt -check
terraform -chdir=infra/terraform validate
```

### Adopt the existing environment

Do not run a normal creation plan against existing names without import.
Enable the supplied import blocks and preview the result:

```bash
cp infra/terraform/imports.tf.example infra/terraform/imports.tf
terraform -chdir=infra/terraform plan \
  -var-file=current.tfvars.example -out=adopt.tfplan
```

Import blocks derive resource IDs from the variables; they cover the resource
group, plan, and app. Basic publishing policies are managed by the Web App
resource's two authentication flags, not separate Terraform resources.

Review every update as well as imports. Only an explicitly approved
`terraform -chdir=infra/terraform apply adopt.tfplan` records the imports in
state and performs any displayed changes. No apply was run during generation.
After successful adoption, remove the optional `imports.tf` file and retain
the state securely. Existing resource IDs and managed identity are preserved
when imported, not recreated.

### Create a separate environment

Leave `imports.tf` absent. Create a local variable file based on the example,
change all three resource names, and confirm subscription, region, SKU, quota,
and organizational policy requirements. Preview before provisioning:

```bash
terraform -chdir=infra/terraform plan -var-file=new.tfvars -out=new.tfplan
```

Apply the saved plan only after approval. A new system-assigned identity and
platform-assigned addresses are expected; they cannot be cloned from the old app.

## Application content

These templates provision infrastructure, not the application ZIP. Recreating
the infrastructure alone will not restore the running application content.
After an approved infrastructure deployment, use Azure CLI Entra authentication
to deploy the two files from `src`; basic publishing authentication stays off.
The following commands **publish application code**; they were not run in this task:

```bash
export AZURE_SUBSCRIPTION_ID=ceb68e54-82cc-47aa-999a-18821f56cf54
export RESOURCE_GROUP=rg-cc-vscode-comparison
export WEB_APP_NAME=cc-vscode-demo-web-hf4i4u2mifhpi
PACKAGE_DIR=$(mktemp -d)
pushd src
zip "$PACKAGE_DIR/app.zip" index.js package.json
popd
az webapp deploy --subscription "$AZURE_SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP" --name "$WEB_APP_NAME" \
  --type zip --src-path "$PACKAGE_DIR/app.zip"
curl --fail --show-error "https://${WEB_APP_NAME}.azurewebsites.net/health"
```

Change the names above when targeting another environment. `zip_deploy_file`
is deliberately not used in Terraform, keeping code delivery separate from
infrastructure and avoiding a dependency on basic publishing credentials.

## Verification and limitations

- Bicep templates and parameter files: compiled successfully.
- Live Bicep `what-if`: succeeded; no resource creates or deletes. It reports
  Modify for platform-generated `freeOfferExpirationTime` on the plan and
  site configuration fields omitted from the Web App's top-level read response.
  A separate `az webapp config show` confirmed the configured startup, TLS,
  FTP, worker, and WebSocket values already match. FTP/SCM policies: NoChange.
  Do not interpret this as a proven zero-diff deployment; review the preview.
- Terraform 1.15.4 / AzureRM 5.4.0: `fmt`, `init`, and `validate` passed.
- Live import preview: **3 to import, 0 to add, 1 to change, 0 to destroy**.
  The only planned update sets `ip_restriction_default_action` and
  `scm_ip_restriction_default_action` from unset to `Allow`, matching the live
  implicit Allow-all rules. No `ignore_changes` was added to conceal drift.
- This is an infrastructure snapshot, not a backup of app files or data.
  No deployment, Terraform apply, state import, or post-apply convergence test
  was performed. Always preview again because live configuration can change.

## References

- [Terraform style guide](https://developer.hashicorp.com/terraform/language/style)
- [AzureRM Linux Web App](https://registry.terraform.io/providers/hashicorp/azurerm/5.4.0/docs/resources/linux_web_app)
- [AzureRM Service Plan](https://registry.terraform.io/providers/hashicorp/azurerm/5.4.0/docs/resources/service_plan)
- [Terraform import blocks](https://developer.hashicorp.com/terraform/language/import)
- [Bicep what-if](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
- [App Service ZIP deployment](https://learn.microsoft.com/azure/app-service/deploy-zip)