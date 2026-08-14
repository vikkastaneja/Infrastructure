# Target AWS EKS & Observability Architecture

This diagram illustrates the flow of internet traffic to our microservices, and how telemetry data is scraped from those services into our observability platform.

```mermaid
flowchart TB
    Internet((Internet Users))
    
    subgraph AWS["AWS Cloud"]
        ALB[AWS Application Load Balancer]
        
        subgraph EKS["Amazon EKS Cluster"]
            Ingress[Kubernetes Ingress]
            
            subgraph Apps["Namespace: apps"]
                svc_front[Frontend Service]
                pod_front1(Frontend Pod)
                pod_front2(Frontend Pod)
                
                svc_back[Backend Service]
                pod_back1(Backend Pod)
                pod_back2(Backend Pod)
                
                Ingress --> svc_front
                svc_front --> pod_front1
                svc_front --> pod_front2
                
                pod_front1 --> svc_back
                pod_front2 --> svc_back
                
                svc_back --> pod_back1
                svc_back --> pod_back2
            end
            
            subgraph O11y["Namespace: observability"]
                otel[OpenTelemetry Collector DaemonSet]
                prom[(Prometheus StatefulSet)]
                grafana[Grafana Dashboard]
                
                pod_front1 -. "Metrics/Traces" .-> otel
                pod_back1 -. "Metrics/Traces" .-> otel
                
                otel -->|"Exports Data"| prom
                prom -->|"Queries Data"| grafana
            end
        end
    end
    
    Internet -->|"HTTP/S"| ALB
    ALB --> Ingress
```
