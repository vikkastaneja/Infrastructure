 **Execution** phase of Day 1.

Our goal now is to validate that you can run a local Kubernetes cluster on your laptop, and deploy a basic workload to it using raw YAML manifests, before we attempt to do it in the cloud.

### Step 1: Start your Local Cluster

Since you are on macOS, the easiest way to get a local cluster running is usually Docker Desktop (if you have "Enable Kubernetes" checked in settings), or `minikube` / `kind`.

**What you need to do:**
1. Open your terminal in VS Code.
2. Check if Kubernetes is already running by typing:
   ```bash
   kubectl cluster-info
   ```
   If it returns a healthy control plane URL (like `https://127.0.0.1:6443`), you are good to go!
   If it fails, you need to start a local cluster. Assuming you have `minikube` installed, run:
   ```bash
   minikube start
   ```

### Step 2: Create the YAML Manifests

We're going to create a simple NGINX web server to prove the concepts of **Deployments** and **Services**.

**What you need to do:**
1. In your `Kubernetes` folder, create a new folder named `manifests`, and a subfolder named `basic` (`Kubernetes/manifests/basic/`).
2. Inside `Kubernetes/manifests/basic/`, create a file named `deployment.yaml` and paste this content:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
```

3. In the same folder, create a file named `service.yaml` and paste this content:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```
*(Notice how the `selector` in the Service perfectly matches the `labels` in the Deployment!)*

### Step 3: Deploy to Kubernetes

**What you need to do:**
Run these commands in your terminal:
```bash
# Tell Kubernetes to read your YAML files and actually create the resources
kubectl apply -f Kubernetes/manifests/basic/

# Verify the Pods are running (you should see 2 of them)
kubectl get pods

# Verify the Service was created
kubectl get svc
```

Execute these three steps and report back whatever you see in the terminal! Once this works, Day 1 is 100% complete.

### Summary of Execution

1. **`kubectl apply -f ...`** 
   - I sent my declarative YAML files to the K8s API server (the Control Plane).
   - The Control Plane evaluated the files, recognized I wanted a `Deployment` and a `Service`, and wrote that desired state into its `etcd` database.

2. **`kubectl get pods`**
   - The `Deployment` automatically spun up a `ReplicaSet`, which then immediately booted up exactly 2 Pods running NGINX (`nginx-deployment-69649bf675-lf664` and `...-z69zs`). 
   - Both Pods show `1/1 READY` and `Running`, proving the Data Plane successfully pulled the Docker image and executed the containers.

3. **`kubectl get svc`**
   - I verified the creation of `nginx-service`. It was assigned an internal cluster IP (`10.98.216.146`). 
   - Because I set `type: NodePort` in the YAML, it automatically mapped port 80 on the Pods to port `30080` on the physical Node (my local machine). 
   - *Result*: The service is actively balancing traffic between the 2 NGINX Pods.