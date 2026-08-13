# MLOps Training Project: Image Classification Inference

A production-ready PyTorch MLOps setup demonstrating model tracing (TorchScript), CLI inference, environment management, and containerization using Docker (**Fat** vs. **Slim Multi-Stage** builds).

## Project Structure

```text
mlops-training-project/
├── app/
│   └── inference.py          # PyTorch inference script
├── model/
│   └── model.pt              # Exported TorchScript MobileNetV2 model
├── screenshots/              # Screenshots for the report.md
├── scripts/
│   └── install_dev_tools.sh  # Bash script to check necessary dependencies
├── export_model.py           # Model tracing & export script
├── Dockerfile.fat            # Single-stage standard Docker image
├── Dockerfile.slim           # Multi-stage optimized Docker image
├── requirements.txt          # Pinned Python dependencies
├── report.md                 # Docker comparison and benchmarking report
├── README.md                 # Project documentation
├── example.jpg               # Image example for the inference
├── .gitignore
└── .dockerignore        
```

## Prerequisites

- Python: 3.13
- Docker Engine / Docker Desktop
- Dependencies: torch==2.7.0, torchvision==0.22.0, pillow==11.2.1

## Quickstart Guide

### 1. Environment preparation

Run Bash script to check and install dependencies:

```bash
chmod +x scripts/install_dev_tools.sh
./scripts/install_dev_tools.sh
```

### 2. Model export

Run the MobileNetV2 download and export script in TorchScript:

```bash
python3 export_model.py
```

### 3. Local verification launch

```bash
python3 app/inference.py example.jpg
```

## Assembling and running Docker images

### 1. Collection of images


```bash
# Fat image
docker build -f Dockerfile.fat -t ml-infer-fat:1.0 .

# Slim image
docker build -f Dockerfile.slim -t ml-infer-slim:1.0 .
```

### 2. Starting containers

```bash
# Run Fat container
docker run --rm -v "$(pwd)/example.jpg:/app/example.jpg" ml-infer-fat:1.0 example.jpg

# Run Slim container
docker run --rm -v "$(pwd)/example.jpg:/app/example.jpg" ml-infer-slim:1.0 example.jpg
```
