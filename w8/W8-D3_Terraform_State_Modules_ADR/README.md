# W8 Day C - Terraform State, Modules, Best Practices

Date: 2026-06-03

## Topics

- Terraform state purpose.
- Remote state with S3.
- State locking with DynamoDB.
- Module structure.
- Best practices for naming, variables, outputs, and environment separation.
- ADR preparation.

## Key Notes

Terraform state is sensitive because it records infrastructure mappings and can contain values from resources. For team usage, state should not be stored only on one laptop. A remote backend such as S3 plus DynamoDB locking helps teams avoid state conflicts.

## Recommended Layout

```text
terraform/
  environments/
    dev/
    staging/
    prod/
  modules/
    network/
    compute/
```

## Evidence Checklist

- [ ] Explain why local state is risky for teams.
- [ ] Draft S3 backend configuration.
- [ ] Draft module structure.
- [ ] Write ADR for backend decision.
- [ ] Prepare 2-3 mentor questions.

