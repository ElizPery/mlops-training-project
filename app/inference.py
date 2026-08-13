import os
import sys
from PIL import Image
import torch
import torchvision.models as models

def main():
    if len(sys.argv) < 2:
        print("Usage: python app/inference.py <path_to_image>")
        sys.exit(1)

    image_path = sys.argv[1]
    if not os.path.exists(image_path):
        print(f"Error: Image path '{image_path}' does not exist.")
        sys.exit(1)

    model_path = os.path.join("model", "model.pt")
    if not os.path.exists(model_path):
        print(f"Error: Model file '{model_path}' not found. Run export_model.py first.")
        sys.exit(1)

    # Load standard weights metadata for transformations & class categories
    weights = models.MobileNet_V2_Weights.DEFAULT
    transforms = weights.transforms()
    categories = weights.meta["categories"]

    # Load TorchScript model
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = torch.jit.load(model_path, map_location=device)
    model.eval()

    # Load & preprocess image
    img = Image.open(image_path).convert("RGB")
    input_tensor = transforms(img).unsqueeze(0).to(device)

    # Run inference without gradient tracking
    with torch.no_grad():
        outputs = model(input_tensor)
        probabilities = torch.nn.functional.softmax(outputs[0], dim=0)

    # Get Top-3 predictions
    top3_prob, top3_catid = torch.topk(probabilities, 3)

    print(f"--- Inference Results for: {image_path} ---")
    for i in range(3):
        class_id = top3_catid[i].item()
        confidence = top3_prob[i].item() * 100
        category_name = categories[class_id]
        print(f"Top-{i+1}: Class ID {class_id:3d} ({category_name}) -> Confidence: {confidence:.2f}%")

if __name__ == "__main__":
    main()