import os
import torch
import torchvision.models as models

os.makedirs("model", exist_ok=True)

# Load pre-trained model using modern Weights API
weights = models.MobileNet_V2_Weights.DEFAULT
model = models.mobilenet_v2(weights=weights)

# Set to evaluation mode
model.eval()

# Create dummy input matching standard image dimensions
dummy_input = torch.randn(1, 3, 224, 224)

# Export via TorchScript tracing
traced_model = torch.jit.trace(model, dummy_input)
traced_model.save("model/model.pt")
print("✅ Model saved to model/model.pt")