# W8 Reflection

## What I Learned

- Terraform helps describe infrastructure using code and a repeatable workflow.
- The plan step is important because it shows intended changes before apply.
- Terraform state must be protected, especially in team environments.
- Kubernetes organizes workloads through Pods, Deployments, and Services.
- Probes help Kubernetes decide when an app is ready or unhealthy.
- ConfigMap and Secret separate configuration from container images.

## What I Practiced

- Created a Terraform local provider example for the basic workflow.
- Drafted Kubernetes Pod, Service, ConfigMap, Secret, Deployment, and NetworkPolicy manifests.
- Prepared an ADR for Terraform remote state using S3 and DynamoDB locking.
- Built a starting lab folder for a mini Kubernetes platform on minikube.

## Current Gaps

- Need to run Terraform commands and paste evidence output.
- Need to start minikube and apply lab manifests.
- Need to capture `kubectl get all -n mini-platform` output.
- Need to confirm whether mentor expects screenshots, command logs, or both.

## Questions For Mentor

1. For W8 evidence, is command output in markdown enough or do we need screenshots?
2. Should Terraform remote state resources be created manually first or through a bootstrap module?
3. Should the lab include ingress, or is Service plus port-forward enough for W8?

