## Plan: 5-Day K8s & Observability Scale Bootcamp

**TL;DR**
A 5-day hands-on roadmap to build, deploy, scale, and break a microservices architecture on an auto-scaling AWS EKS cluster via Terraform. This plan integrates a production-grade observability pipeline (OpenTelemetry, Prometheus, Grafana) to mirror real-world telemetry tracking during chaos engineering, directly backing up high-scale resilience and MTTR resume claims.

**Steps**

**Phase 1: Day 1 - Theory, Architecture & Local Demo**
1. Document Kubernetes core concepts (Pods, Deployments, Services, HPA, DaemonSets) in `Kubernetes/docs/concepts-k8s.md`.
2. Document AWS cloud & Terraform concepts (EKS, Node Groups, VPCs, State, Modules) in `Kubernetes/docs/concepts-infra.md`.
3. Document Observability concepts (OpenTelemetry Collectors, Prometheus scraping, Grafana dashboards) in `Kubernetes/docs/concepts-o11y.md`.
4. Generate Mermaid diagrams mapping the microservices to the OpenTelemetry pipeline and AWS topology in `Kubernetes/docs/architecture.md`.
5. Install `kubectl`, `minikube` (or Docker Desktop), and `helm` locally.

**Phase 2: Day 2 - K8s Infrastructure via Terraform**
1. Install `aws-cli` and `terraform`, configure AWS IAM.
2. Author Terraform modules in `Kubernetes/terraform/` to provision:
   - AWS VPC and Subnets.
   - Amazon EKS Cluster (2 initial nodes).
   - Helm Provider resources (to manage basic cluster add-ons natively via TF).
3. Configure `kubectl` to point to the remote EKS cluster.
4. Deploy the AWS Load Balancer Controller for Ingress routing.

**Phase 3: Day 3 - Microservices & The Observability Stack**
1. Scaffold 3 interconnected microservices (e.g., Frontend API, Orders Backend, Inventory Cache) in `Kubernetes/src/`. Instrument their code with the **OpenTelemetry SDK**.
2. Deploy the **kube-prometheus-stack** via Helm (installs Prometheus, Grafana, Alertmanager).
3. Deploy the **OpenTelemetry Collector** as a Kubernetes DaemonSet to receive metrics/traces from the microservices and export them to Prometheus.
4. Access Grafana and create a custom dashboard visualizing request rates, error rates, and durations (RED metrics).

**Phase 4: Day 4 - Auto-Scaling Configuration**
1. Install `metrics-server` on the EKS cluster.
2. Configure a `HorizontalPodAutoscaler` (HPA) to dynamically scale the microservice pods based on CPU/Memory utilization crossing 50%.
3. Configure **Cluster Autoscaler** (or AWS Karpenter) to automatically provision new EC2 instances when pending pods overwhelm existing nodes.
4. Validate scaling limits and permissions using Terraform.

**Phase 5: Day 5 - Chaos, Load Testing & MTTR Verification**
1. Write a load testing script (using `k6` or `Locust`) in `Kubernetes/load-test/` to generate sustained traffic.
2. Build a **Fault Testing Harness**: script deliberate infrastructure failures (e.g., terminating EC2 instances, crashing the Orders API pod, filling disk space).
3. Execute the Chaos load test.
4. **The Ultimate Verification**: Use your deployed Grafana dashboards to *actually watch* the failure happen in real-time, observe the error-rate alert trigger, watch Kubernetes auto-heal/scale the nodes, and measure the exact Mean Time To Recovery (MTTR) as the dashboards return to green.

**Relevant files**
- `Kubernetes/docs/architecture.md` — Architecture & Mermaid diagrams.
- `Kubernetes/docs/concepts-*.md` — K8s, AWS, and Observability definitions.
- `Kubernetes/terraform/` — Infrastructure provisioning for VPC and EKS.
- `Kubernetes/src/` — Source code and Dockerfiles for the microservices.
- `Kubernetes/manifests/observability/` — OTel Collector and Prometheus configs.
- `Kubernetes/manifests/apps/` — Microservices K8s YAMLs and Helm charts.
- `Kubernetes/load-test/chaos-script.sh` — Load generation and Fault testing harness.

**Verification**
1. `terraform apply` stands up the entire environment cleanly.
2. Microservices successfully send data to OTel Collector -> Prometheus -> Grafana.
3. Node death and pod crashes are visually logged in Grafana with measurable recovery times.
4. **Critical**: Run `terraform destroy` when done to completely clean up AWS resources.

**Decisions**
- **Architecture**: A multi-tier microservice model proves real-world routing, service discovery, and inter-service networking.
- **Failures Scope**: Focused specifically on infrastructure failures (node death, system component failure) mapped to MTTR metrics.
- **Platform**: Terraform over `eksctl` to maximize utility for a Resume/CV.