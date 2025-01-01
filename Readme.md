# CI/CD for Flask Contact App in Kubernetes Cluster

This guide provides instructions for setting up a CI/CD pipeline for deploying a Flask Contact App in a Kubernetes cluster with a Load Balancer.

---

## Prerequisites

### Required Tools
Ensure the following applications are installed on your system:

- **AWS CLI**
- **Docker**
- **Terraform**
- **kubectl**
- **Ansible**
- **Helm**
- **Git**
- Other dependencies required to run the above tools

### Repository
Clone the GitHub repository:
```bash
https://github.com/glazedonuts616/MajorProject.git
```

---

## Setup Instructions

### 1. AWS Configuration
- Add your AWS private key credentials to the `.aws` folder on your machine.
- Configure AWS CLI with your credentials:
```bash
aws configure
```

### 2. Update AWS Key Name
Modify the `aws_instance` key name in the Terraform configuration to match the name of your AWS key file.

---

## Steps to Deploy

### Step 1: Terraform Setup
1. Navigate to the Terraform directory:
   ```bash
   cd MajorProject/terraform/
   ```
2. Initialize and apply Terraform configurations:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Step 2: Ansible Configuration
1. Navigate to the Ansible directory:
   ```bash
   cd MajorProject/terraform/tf_ec2_ansible/
   ```
2. Update `inventory.ini` with the location of your AWS key file.
3. Run the Ansible playbook:
   ```bash
   ansible-playbook -i inventory.ini ec2_ansible.yaml
   ```

### Step 3: Connect to EC2
- SSH into your newly created EC2 instance:
  ```bash
  ssh -i "path-to-your-key" ubuntu@Your-EIP-Address
  ```

### Step 4: Jenkins Setup
1. Access Docker logs to retrieve the Jenkins admin password:
   ```bash
   docker logs jenkins-container-name
   ```
2. Open Jenkins in your browser using the EC2 IP address and port 8080:
   ```
   http://Your-EIP-Address:8080
   ```
3. Enter the admin password and install the following plugins:
   - EKS Token
   - EC2
   - Git
   - Kubernetes
   - Pipeline (Groovy and Grid View)
   - Amazon Web Services

4. Add necessary credentials in Jenkins:
   - **EKS Token Credentials**
   - **AWS Credentials**
   - **GitHub Credentials**
   - **GitHub Webhook Credentials**

### Step 5: Deploy Kubernetes Cluster
1. Navigate to the EKS Terraform configuration:
   ```bash
   cd MajorProject/terraform/eks_cluster/
   ```
2. Initialize and apply the configuration:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

---

## Final Steps

### Jenkins Pipeline Configuration
1. Access Jenkins at the EC2 instance IP (port 8080).
2. Add the `Jenkinsfile` to your pipeline configuration.
3. Update the `Jenkinsfile` with the correct Kubernetes cluster endpoint URL.
4. Configure the pipeline to synchronize with the GitHub repository via webhook.
5. Build the pipeline in Jenkins.

### Application Access
- Flask Contact App: `http://LoadBalancer-DNS-Name:5052`
- MongoDB: `http://LoadBalancer-DNS-Name:8081`

### Verification
- Confirm GitHub and Jenkins webhook integration.
- Verify successful pipeline execution and deployment.

---

## Notes
- Ensure printers are up to date and connected to the server (if applicable).
- Use the DNS name provided by the Load Balancer to access the services.

---

**It's been real!**  
**Yoni**
