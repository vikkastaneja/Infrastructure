# Resilient Kubernetes & Observability Platform (AWS EKS)

This repository contains a full-stack, production-grade Kubernetes environment deployed via Terraform. It is designed to act as an advanced proof-of-concept (PoC) for multi-tier microservice deployments, dynamic auto-scaling, and high-fidelity observability using an OpenTelemetry and Grafana stack.

The primary goal of this repository is to demonstrate an environment capable of surviving structured chaos engineering and infrastructure failure (e.g., the "Thundering Herd" IoT recovery scenario) while measuring Mean Time To Recovery (MTTR) with precision.

## Architecture Highlights
* **Infrastructure as Code:** 100% Terraform-driven provisioning of AWS VPCs, subnets, and Amazon EKS.
* **Microservices:** A 3-tier Python/Node application architecture.
* **Auto-Scaling:** Configured with Horizontal Pod Autoscalers (HPA) for workload scaling and Cluster Autoscaler (CA) for underlying EC2 node scaling.
* **Observability Pipeline:** Microservices instrumented with the OpenTelemetry SDK. Logs, metrics, and traces are aggregated by an OpenTelemetry Collector DaemonSet and exported to a Prometheus/Grafana stack for RED (Rate, Errors, Duration) metric visualization.
* **Chaos Engineering:** Includes a custom `k6` load testing harness to simulate high-traffic IoT scenarios and intentional node/pod disruption.

## Project Structure

```text
├── docs/                 # Ecosystem Definitions and Mermaid Architecture Diagrams
├── terraform/            # IaC for AWS VPC, EKS, and baseline IAM Roles
├── src/                  # Source code & Dockerfiles for the microservices
├── manifests/
│   ├── apps/             # K8s Deployments, Services, Ingress, and HPA for workloads
│   └── observability/    # OTel Collector, kube-prometheus-stack Helm configs
└── load-test/            # k6 scripts for traffic generation and chaos testing
```

## Getting Started

1. **Prerequisites:**
   * Docker / Minikube (for local testing)
   * `kubectl`
   * `helm`
   * `aws-cli` (configured with IAM user credentials)
   * `terraform`

2. **Deployment**
   Navigate to the `terraform/` directory to stand up the cluster:

   ```bash
   cd terraform
   terraform init
   terraform apply -auto-approve
   ```

   Update your local kubeconfig to point to the new remote cluster:

   ```bash
   aws eks update-kubeconfig --region <your-region> --name <cluster-name>
   ```

3. **Deploying Workloads & Observability**
   Apply the baseline observability tools:

   ```bash
   helm repo add prometheus-community https://github.io
   # ... full scripts located in manifests/observability
   ```

   Apply the microservices:

   ```bash
   kubectl apply -f manifests/apps/
   ```

4. **Chaos Testing**
   Run the simulated load test and infrastructure failure scripts:

   ```bash
   cd load-test
   ./chaos-script.sh
   ```

5. **Teardown**
   CRITICAL: Prevent runaway AWS billing when terminating the test environment.

   ```bash
   cd terraform
   terraform destroy -auto-approve
   ```
