# scramble-infra

Infrastructure for the Scramble game, managed with Terraform and GitOps (FluxCD).

---

## 📁 Folder Structure
<pre lang="text">
scramble-infra/
├── .github/
│   └── workflows/
│       └── terraform.yml            # CI for Terraform apply to prod
│
├── terraform/
│   ├── modules/                     # Reusable infra modules
│   │   ├── vpc/                     # AWS VPC setup
│   │   ├── eks/                     # EKS cluster config
│   │   ├── ecr/                     # Creates ECR repo (used by Medusa app repo)
│   │   └── s3-state/                # Remote backend infra
│   │
│   └── prod/                        # Live environment
│       ├── backend.tf               # Remote backend config
│       ├── main.tf                  # Assembles modules
│       ├── variables.tf             # Variable definitions
│       └── versions.tf              # Terraform/provider versions
│
├── flux/
│   ├── base/                        # Cluster-agnostic K8s manifests
│   │   └── medusa/                  # K8s deployment infra (no app code)
│   │       ├── deployment.yaml      # Pulls image from ECR
│   │       ├── service.yaml         # K8s Service
│   │       └── hpa.yaml             # Horizontal pod autoscaler
│   │
│   └── prod/                        # Kustomize overlay for EKS
│       ├── kustomization.yaml       # Flux sync entrypoint
│       └── image-automation/
│           ├── image-repo.yaml      # Watches ECR pushed from app repo
│           └── image-update.yaml    # Patches Deployment with new image tag
│
└── README.md
</pre>



---

## 🔧 Tools

- **Terraform** — for bootstrapping cloud infrastructure (EKS, VPC, ECR, etc.)
- **FluxCD** — for GitOps-driven Kubernetes workload delivery
- **GitHub Actions** — CI/CD automation for Terraform

---

## Flow Summary

1. Terraform creates infrastructure including EKS + ECR + S3 backend.
2. Flux is installed into the EKS cluster via Terraform.
3. Flux watches this repo’s `flux/prod/` folder.
4. Medusa app images pushed to ECR (from app repo) are auto-deployed by Flux.

---

## Remote State

- S3 bucket with versioning enabled
- DynamoDB table for state locking