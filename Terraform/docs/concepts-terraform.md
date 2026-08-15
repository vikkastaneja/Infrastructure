# Terraform Infrastructure-as-Code Concepts

## 1. Providers
* **What it is:** Plugins that Terraform uses to translate its code into API calls for a specific platform (AWS, Azure, Kubernetes, etc.).
* **Where it is used:** We use the `aws` provider to build the VPC and EKS cluster, the `kubernetes` provider to configure the cluster, and the `helm` provider to install our observability stack natively via Terraform.

## 2. State (.tfstate)
* **What it is:** A JSON file where Terraform maps real-world cloud resources to your configuration files. 
* **Where it is used:** This is how Terraform keeps track of what it has already built. It’s what allows running `terraform destroy` to accurately clean up every single resource it created without leaving orphaned infrastructure behind.

## 3. Modules
* **What it is:** Self-contained packages of Terraform configurations that bundle multiple resources together. 
* **Where it is used:** Instead of writing thousands of lines of code to build a secure VPC and an EKS cluster from scratch, we use the official AWS `vpc` and `eks` community modules to build proven, production-grade infrastructure with just a few lines of code.

## 4. Resources vs. Data Sources
* **What it is:** A `resource` tells Terraform to *create* something new. A `data` source tells Terraform to *fetch information* about something that already exists.
* **Where it is used:** We use resources to create our Node Groups, but we might use a data source to fetch the latest Amazon Linux AMI ID to use for those nodes.

## 5. Terraform Execution Flow

This diagram illustrates how Terraform takes your declarative code, compares it against the locally saved state, and uses the Provider to make API calls to AWS.

```mermaid
flowchart LR
    Dev([Developer]) -->|Writes| Code["Terraform Code<br/>(*.tf files)"]
    Code --> CLI["Terraform CLI<br/>(init, plan, apply)"]
    
    CLI <-->|Reads / Updates| State[("State File<br/>(terraform.tfstate)")]
    
    CLI -->|Invokes| Provider["AWS Provider<br/>Plugin"]
    Provider -->|Makes API Calls| AWS["AWS Cloud<br/>(Provisions VPC, EKS)"]
```

