#!/usr/bin/env python3
"""
[DEPRECATED FOR PRODUCTION]
LFM3-VL-2B Local Inference & HTTP Bridge Server

NOTE: Challenge-5 runs LFM3-VL-2B 100% natively on-device in Swift via VLMEngine.swift
using llama.cpp mtmd and Metal GPU acceleration on physical iOS devices and TestFlight.
This script is preserved for optional standalone offline Python scripting/benchmarking only.

Provides:
1. HTTP API at POST /v1/analyze for iOS Simulator / Mac app to extract rich fashion keywords.
2. CLI mode: `python3 qwen_vl_server.py --image path/to/fashion.jpg` to test extraction directly.

Requirements:
    pip install mlx-vlm (or transformers torch pillow)
"""

import os
import sys
import json
import base64
import io
import argparse
from http.server import HTTPServer, BaseHTTPRequestHandler
from PIL import Image

SYSTEM_PROMPT = """You are an objective visual clothing analyst.
Analyze the user's reference fashion image(s) and extract the exact visual clothing details in a zero-shot manner.
Do not hallucinate or use predefined examples. Do not output generic scene words (such as people, adult, clothing, closet, or interior).
Extract ONLY what is visibly present in the image.

Output valid JSON matching this schema:
{
  "genreVibe": "<Detected fashion genre, aesthetic, or style vibe>",
  "persona": "<Detected stylistic persona or attitude>",
  "fit": "<Detected fit and silhouette proportions>",
  "cuts": ["<Detected garment cut, neckline, collar, hemline, or sleeve>"],
  "materials": ["<Detected fabric, weave, or tactile texture>"],
  "patterns": ["<Detected surface pattern or finish>"],
  "colors": "<Detected dominant colors, palette temperature, and contrast>"
}
"""

def extract_style_from_image(image_paths_or_images):
    """Runs inference using mlx-vlm (fastest on Apple Silicon) or transformers."""
    try:
        from mlx_vlm import load, generate
        from mlx_vlm.prompt_utils import apply_chat_template
        from mlx_vlm.utils import load_config
        
        model_name = "LiquidAI/LFM3-VL-2B-MLX-6bit"
        print(f"Loading {model_name} via MLX...")
        model, processor = load(model_name)
        config = load_config(model_name)
        
        prompt = apply_chat_template(
            processor,
            config,
            prompt=SYSTEM_PROMPT + "\nAnalyze the clothing in the attached image(s):",
            num_images=len(image_paths_or_images)
        )
        
        output = generate(
            model,
            processor,
            prompt=prompt,
            image=image_paths_or_images,
            max_tokens=256,
            temperature=0.0,
            verbose=False
        )
        
        # Parse JSON from response
        clean_output = output.strip()
        if "```json" in clean_output:
            clean_output = clean_output.split("```json")[1].split("```")[0].strip()
        elif "```" in clean_output:
            clean_output = clean_output.split("```")[1].split("```")[0].strip()
            
        return json.loads(clean_output)
    except Exception as e:
        print(f"MLX-VLM error/fallback: {e}")
        return {
            "genreVibe": "",
            "persona": "",
            "fit": "",
            "cuts": [],
            "materials": [],
            "patterns": [],
            "colors": ""
        }

class VLMRequestHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/v1/analyze":
            self.send_response(404)
            self.end_headers()
            return
            
        content_length = int(self.headers.get("Content-Length", 0))
        post_data = self.rfile.read(content_length)
        
        try:
            req_json = json.loads(post_data.decode("utf-8"))
            base64_images = req_json.get("images", [])
            
            pil_images = []
            for b64 in base64_images:
                img_bytes = base64.b64decode(b64)
                pil_images.append(Image.open(io.BytesIO(img_bytes)))
                
            result = extract_style_from_image(pil_images)
            
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(result).encode("utf-8"))
        except Exception as e:
            self.send_response(500)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode("utf-8"))

def main():
    parser = argparse.ArgumentParser(description="Qwen2.5-VL-3B-Instruct Style Analyzer Server")
    parser.add_argument("--port", type=int, default=8080, help="Server port (default: 8080)")
    parser.add_argument("--image", type=str, help="Test extraction on a single image file")
    args = parser.parse_args()
    
    if args.image:
        print(f"Analyzing {args.image}...")
        img = Image.open(args.image)
        res = extract_style_from_image([img])
        print(json.dumps(res, indent=2))
        return
        
    server = HTTPServer(("0.0.0.0", args.port), VLMRequestHandler)
    print(f"🚀 Qwen2.5-VL-3B Bridge Server listening on 0.0.0.0:{args.port} (Accessible locally at http://127.0.0.1:{args.port}/v1/analyze and on Wi-Fi at http://192.168.1.3:{args.port}/v1/analyze)")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server...")
        server.server_close()

if __name__ == "__main__":
    main()

