# Azure Cognitive Services Python Examples

These are examples I created and know to work, as many of the official ones are of "mixed quality".
Examples are simple and focused on one task or API

# Getting Started
All settings are expected to come from environmental variables. Copy the `.env.sample` file to `.env` and modify the keys, regions etc.

- Create a Python virtual-environment `python3 -m venv .venv`
- Install requirements `pip install -r requirements.txt`

Examples require Python 3.6 as a minimum

# Samples

## Computer Vision - Analyse/Describe Image

To run: 
```
python src/analyze-image.py input/goat.jpg
```