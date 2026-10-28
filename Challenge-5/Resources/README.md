# AI Model Weights Directory

This directory holds local offline GGUF model weights for on-device inference using `llama.cpp`.

## Standard Model
- **Filename**: `Llama-3.2-1B-Instruct-Q4_K_M.gguf`
- **Size**: ~770 MB
- **Source**: Llama-3.2-1B-Instruct 4-bit Quantized (`Q4_K_M`)
- **Version Tracking**: Tracked via **Git LFS** (`.gitattributes`)

## Git LFS Setup
Model ini di-track menggunakan **Git LFS** agar tidak ditolak oleh limit upload standard Git:
1. Pastikan Git LFS terpasang di Mac: `brew install git-lfs`
2. Inisialisasi: `git lfs install`
3. Tarik file model: `git lfs pull`
