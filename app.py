from flask import Flask, render_template, request, jsonify
import torch
from torchvision import transforms
from PIL import Image
import os
from fruit_info import fruit_info

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = 'static/uploads'

# ── Load MobileNetV2 TorchScript ──────────────────────────────────────────────
MODEL_PATH = "fruit_mobilenet_v2.pt"
model = torch.jit.load(MODEL_PATH)
model.eval()

# ── Class names must match the order used during training ─────────────────────
CLASS_NAMES = [
    'apple',
    'banana',
    'kiwi',
    'mango',
    'orange',
    'pineapple',
    'pomegranate',
    'strawberries',
    'watermelon'
]

# ── Preprocessing pipeline for MobileNetV2 (224×224 + normalization) ──────────
preprocess = transforms.Compose([
    transforms.Resize((224,224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485,0.456,0.406], [0.229,0.224,0.225])
])

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/about')
def about():
    return "<h2>About FruitNourish</h2><p>MobileNetV2-powered fruit nutrition app.</p>"

@app.route('/prediction')
def prediction():
    return render_template('prediction.html')

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify(error="No file uploaded"), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify(error="Empty filename"), 400

    # ensure upload folder exists
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    filename = file.filename
    save_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    file.save(save_path)

    # open & preprocess
    img = Image.open(save_path).convert('RGB')
    x = preprocess(img).unsqueeze(0)  # add batch dim

    # model inference
    with torch.no_grad():
        logits = model(x)
        probs = torch.softmax(logits, dim=1)[0]
        idx = probs.argmax().item()
        confidence = probs[idx].item()

    fruit = CLASS_NAMES[idx]
    info = fruit_info.get(fruit, {})
    nutrients = info.get('nutrients', {})
    benefits = info.get('diseases', [])

    return jsonify(
        fruit=fruit,
        confidence=confidence,
        nutrition=nutrients,
        benefits=benefits
    )

if __name__ == '__main__':
    app.run(debug=True)
