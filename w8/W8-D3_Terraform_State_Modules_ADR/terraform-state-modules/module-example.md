# Terraform Module Example

Suggested module structure:

```text
modules/
  network/
    main.tf
    variables.tf
    outputs.tf
  app/
    main.tf
    variables.tf
    outputs.tf
environments/
  dev/
    main.tf
    backend.tf
    terraform.tfvars
```

## Module Rules

- Keep modules focused on one responsibility.
- Expose only necessary outputs.
- Use variables for environment-specific values.
- Pin provider and module versions.
- Do not commit secrets or generated state files.

