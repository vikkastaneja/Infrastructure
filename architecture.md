# Full Stack Architecture
This diagram illustrates the complete, end-to-end architecture of the platform. It maps the provisioning layer (Terraform), the physical cloud layer (AWS), the container orchestration layer (Kubernetes), and the observability pipeline (OpenTelemetry/Grafana).

```mermaid
flowchart TB
    %% Provisioning Layer
    subgraph IaC ["Provisioning Layer"]
        TF["Terraform Code"]
    end

    %% AWS Cloud Layer
    subgraph Cloud ["AWS Cloud Environment"]
        VPC["AWS VPC & Subnets"]
        ALB["Application Load Balancer"]
        
        subgraph K8s ["Amazon EKS Cluster"]
            
            subgraph Apps ["Workloads (apps namespace)"]
                Front["Frontend API"]
                Back["Backend Orders Worker"]
                Cache[("Redis Cache")]
            end
            
            subgraph O11y ["Telemetry (observability namespace)"]
                OTel["OpenTelemetry Collector<br/>(DaemonSet)"]
                Prom[("Prometheus")]
                Grafana["Grafana UI"]
            end
            
        end
    end

    %% Users
    Users((Internet Users))
    Admin((SRE / Admin))

    %% Relationships and Data Flow
    TF == "Provisions" ==> VPC
    TF == "Bootstraps" ==> K8s
    
    Users -. "HTTP Traffic" .-> ALB
    ALB --> Front
    Front --> Back
    Back --> Cache
    
    %% Telemetry Flow
    Front -. "Traces/Metrics" .-> OTel
    Back -. "Traces/Metrics" .-> OTel
    OTel -->|Exports| Prom
    Prom -->|Queries| Grafana
    
    Admin -->|Views Dashboards| Grafana
```