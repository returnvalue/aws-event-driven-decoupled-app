# AWS Event-Driven Decoupled Application (Terraform)

This repository demonstrates a production-grade asynchronous architecture provisioned using **Terraform**. It follows the **Event-Driven / Decoupled** pattern, a core requirement for the AWS Certified Solutions Architect - Associate (SAA-C03) exam.

## 🏗️ Architecture Overview

The application is designed to handle high volumes of data reliably by decoupling the producer of an event from the consumer. It consists of the following flow:

1.  **Event Ingress:** Messages are published to an **SNS Topic**, which acts as a broadcast hub.
2.  **Decoupling Layer:** An **SQS Queue** subscribes to the SNS Topic, providing a durable buffer that ensures no data is lost during traffic spikes or downstream downtime.
3.  **Serverless Processing:** An **AWS Lambda** function is automatically triggered by the SQS queue to process each message.
4.  **Durable Storage:** Processed event data is stored as JSON in an **S3 Bucket** for auditing and persistence.

## 🛠️ SAA-C03 Design Patterns Covered

- **Design Resilient Architectures (Domain 1):** Use of SQS as a buffer prevents data loss and ensures "Eventual Consistency" during failures.
- **Design High-Performing Architectures (Domain 3):** Fan-out pattern allows multiple subscribers to process the same event in parallel.
- **Design Secure Architectures (Domain 2):** 
    - **IAM Least Privilege:** The Lambda function has a dedicated execution role with permissions restricted to only the specific SQS and S3 resources it needs.
    - **Resource Policies:** The SQS queue uses a granular policy to only allow SendMessage actions from the specific SNS topic.

## 🚀 Technical Components

- **Messaging:** SNS Topic and SQS Queue with secure "Least Privilege" policies.
- **Compute:** Serverless AWS Lambda with Event Source Mapping triggers.
- **Storage:** S3 Bucket for persistent event storage.
- **Identity:** Fine-grained IAM Roles and Policies for compute security.
- **Infrastructure as Code:** 100% automated via Terraform with a state-managed lifecycle.

## 💻 Local Development

This project is optimized for testing using **LocalStack**.

### Prerequisites
- [Terraform](https://www.terraform.io/downloads)
- [Docker](https://www.docker.com/products/docker-desktop)
- [LocalStack](https://localstack.cloud/)

### Deployment
1. Start LocalStack: `docker-compose up -d`
2. Initialize Terraform: `terraform init`
3. Deploy Infrastructure: `terraform apply -auto-approve`
