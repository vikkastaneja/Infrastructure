# Terraform Execution Steps (Day 2)

## Why run `terraform plan` instead of testing locally?
Terraform code is tightly bound to the specific Provider (e.g., `aws`, `kubernetes`). You cannot write Terraform code to spin up a local Minikube cluster and then simply "convert" it to AWS—the underlying resource blocks and APIs are completely different. 

To safely test Terraform code targeting AWS without accidentally spending money or breaking things, we use the `terraform plan` command. This creates a "dry run" map by communicating with AWS APIs to determine exactly what *would* be created, allowing us to validate the execution logic locally before running `terraform apply`.

*(Note: While tools like LocalStack can simulate AWS locally in Docker, their support for advanced services like Managed EKS is often limited to paid enterprise tiers. Running `terraform plan` against a real AWS account is the industry standard for safe dry-run validation).*

## Step 1: Scaffold the Directory Structure
To maintain a modular, production-ready structure, we separate the networking (VPC) from the compute (EKS).

**Commands Run:**
```bash
mkdir -p Terraform/modules/vpc
mkdir -p Terraform/modules/eks
touch Terraform/main.tf Terraform/variables.tf Terraform/providers.tf
```

## Step 2: Configure the Provider
The `providers.tf` file locks in the required AWS provider version and specifies the region we are deploying to.

**Code added to `Terraform/providers.tf`:**
```hcl
terraform {
  required_version = ">= 1.3.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

## Step 3: Define Global Variables
The `variables.tf` file ensures we do not hardcode values like the region or cluster name across multiple files.

**Code added to `Terraform/variables.tf`:**
```hcl
variable "aws_region" {
  description = "The AWS region to deploy the EKS cluster into"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "o11y-scale-cluster"
}
```

Now we define the actual AWS resources we want to build. 

Instead of writing thousands of lines of raw Terraform resource blocks from scratch, we are going to use the official Terraform AWS modules for VPC and EKS. This is the industry standard for production environments because it automatically handles complex security group rules, routing tables, and node group configurations for us.

### Step 4: Define the VPC Module
First, we need the network where EKS will live. We will give the VPC a massive CIDR block (`10.0.0.0/16`) and carve out 3 public subnets and 3 private subnets across 3 Availability Zones for high availability.

**What you need to do:**
Open `main.tf` and paste this code:

```hcl
data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Crucial tags for Kubernetes to know which subnets to use for internal vs external load balancers
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}
```

### Step 5: Define the EKS Module
Next, we define the Kubernetes cluster. We will tell it to deploy into the VPC we just created, and we will define a Managed Node Group containing 2 initial EC2 worker nodes.

**What you need to do:**
In `main.tf`, append this code to the bottom of the file (below the VPC block):

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  # The cluster endpoint needs to be accessible so we can run kubectl commands from our laptop
  cluster_endpoint_public_access  = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  eks_managed_node_groups = {
    initial = {
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 5
      desired_size = 2
    }
  }

  # This grants the creator of the cluster (you) admin access automatically
  enable_cluster_creator_admin_permissions = true
}
```

Now, we will run the `plan` command to see the magic happen!

Awesome! You now have a complete, production-grade Terraform configuration that will build an entire networking layer and a Kubernetes cluster.

### Step 3: Setup AWS
Since we are doing a dry run, you need a valid set of AWS credentials. 

**Option 1: If you already have AWS credentials (Access Key & Secret Key) for a sandbox/personal account:**
You need to export them into your terminal session before running Terraform. Run these commands (replace the placeholder text with your actual keys):
```bash
export AWS_ACCESS_KEY_ID="AKIAxxxxxxxxxxxxxxxx"
export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export AWS_REGION="us-west-2"
```
After running those, try `terraform plan` again.

**Option 2: If you do not have an AWS account or do not want to use real credentials for this learning exercise:**
We can trick Terraform into doing a partial syntax validation without talking to the actual AWS API. This won't give us the full deep dependency graph, but it will prove your Terraform code is structurally perfect.

**What you need to do (for Option 2):**
1. Open `providers.tf`.
2. Update the `provider "aws"` block to look exactly like this (we are adding the `skip_` flags to tell it not to verify credentials):

```hcl
provider "aws" {
  region                      = var.aws_region
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}
```
3. Run `terraform plan` again.

### Step 4: Initialize and Plan

We need to initialize Terraform (so it downloads the AWS provider and the public VPC/EKS modules) and then run our non-destructive `plan` to validate the code.

**What you need to do:**
1. Open your terminal in VS Code.
2. Navigate into your Terraform directory:
   ```bash
   cd Terraform
   ```
3. Initialize the workspace:
   ```bash
   terraform init
   ```
4. Run the plan to see what AWS resources it wants to create:
   ```bash
   terraform plan
   ```

*(Note: In order for `terraform plan` to work, you must have your AWS credentials configured locally on your machine, usually via `aws configure` or by exporting `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in your terminal).*

Run those commands. If `terraform plan` executes successfully, it will print out a massive list of resources ending with something like: `Plan: 52 to add, 0 to change, 0 to destroy.`

Let me know what output you get!

## Addendum

Testing terraform locally is a phenomenally good instinct for a platform engineer. 

However, **Terraform works differently than Docker or Kubernetes.**
*   With Kubernetes, a `Deployment` YAML is largely identical whether it runs on your laptop (Minikube) or in the cloud (AWS EKS).
*   With Terraform, the code is strictly bound to the **Provider**. 

If you write Terraform code to deploy a local Kubernetes cluster (like using the `kind` or `minikube` providers), the code uses completely different resources, arguments, and logic than the code required to build an AWS EKS cluster. 
For example:
*   Local TF: `resource "minikube_cluster" "main" { ... }`
*   AWS TF: `module "eks" { source = "terraform-aws-modules/eks/aws" ... }`

**You cannot simply write it locally and "convert" it to AWS.** You would have to rewrite 100% of the code from scratch.

### How do Platform Engineers test Terraform locally without breaking AWS?

Since you can't build AWS resources locally, we use a different workflow to validate Terraform before hitting the giant red "Apply" button:

1.  **`terraform init`**: Validates that all your syntax is correct and downloads the required provider plugins (like the AWS plugin).
2.  **`terraform plan` (The Magic Command):** This is your local testing safety net. When you run this, Terraform talks to AWS, evaluates your code, and prints out an exact "dry run" map of everything it *would* create, modify, or destroy. It does this *without actually building or spending a single dime.* You review the plan on your laptop. 
3.  **`terraform apply`**: Only executed when you are 100% satisfied with the `plan`.

### A Free AWS Alternative (LocalStack)
There *is* a tool called **LocalStack** which simulates AWS on your laptop (it spins up a fake AWS VPC, fake S3, etc., inside Docker). However, LocalStack's support for EKS is notoriously limited and requires a paid Pro license for advanced features. For our goal (building a true, scaleable EKS cluster for your resume), standard Terraform `plan` against a real AWS account is the industry standard.

### Let's Proceed Safely
Since we will use `terraform plan` to validate everything for free before we build, let's proceed with setting up the AWS provider structure!
