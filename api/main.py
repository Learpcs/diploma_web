from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import yaml
import os
import sys
import traceback
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

sys.path.append(r'C:/Users/Administrator/Desktop/projects/multi-lang projects/diploma/diploma_ml/Src')
import torch
import numpy as np
from text_to_arpabet import sentence_to_arpabet
import whisper

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# Test endpoint
@app.get("/")
async def root():
    return {"message": "API is running"}

# Load ARPAbet-to-ID mapping from config.yaml
CONFIG_PATH = os.path.join(os.path.dirname(__file__), '../../diploma_ml/Config/config.yaml')
with open(CONFIG_PATH, 'r') as f:
    config = yaml.safe_load(f)
ARPABET_TO_ID = config.get('arpabet', {})

# Load Whisper model
WHISPER_MODEL_PATH = os.path.join(os.path.dirname(__file__), '../../diploma_ml/Model/whisper/whisper_ctc_phoneme_v1_loss0.0000.pth')
WHISPER_MODEL_PATH = os.path.abspath(WHISPER_MODEL_PATH)

# Initialize Whisper model
model = whisper.load_model("base.en")
# Load state dict and remove 'model.' prefix from keys
state_dict = torch.load(WHISPER_MODEL_PATH, map_location=torch.device('cpu'))
new_state_dict = {k.replace('model.', ''): v for k, v in state_dict.items()}
model.load_state_dict(new_state_dict)
model.eval()

def extract_phonemes_from_audio(audio_bytes: bytes) -> list:
    # Save audio bytes to temporary file
    temp_path = "temp_audio.wav"
    try:
        with open(temp_path, "wb") as f:
            f.write(audio_bytes)
        
        # Transcribe audio using Whisper
        result = model.transcribe(temp_path)
        text = result["text"].strip()
        logger.info(f"Transcribed text: {text}")
        
        # Convert text to ARPAbet phonemes
        phonemes = sentence_to_arpabet(text)
        if phonemes is None:
            raise HTTPException(status_code=400, detail="Could not convert text to phonemes")
            
        # Split phonemes into list and convert to IDs
        phoneme_list = phonemes.split()
        phoneme_ids = []
        for phoneme in phoneme_list:
            phoneme_id = ARPABET_TO_ID.get(phoneme)
            if phoneme_id is not None:
                phoneme_ids.append(phoneme_id)
        
        logger.info(f"Extracted phoneme IDs: {phoneme_ids}")
        return phoneme_ids
    except Exception as e:
        logger.error(f"Error in extract_phonemes_from_audio: {str(e)}")
        logger.error(traceback.format_exc())
        raise
    finally:
        # Clean up temporary file
        if os.path.exists(temp_path):
            os.remove(temp_path)

@app.post("/phoneme-sequence")
async def phoneme_sequence(file: UploadFile = File(...)):
    try:
        logger.info(f"Received file: {file.filename}, content_type: {file.content_type}")
        
        if not file.content_type.startswith('audio/'):
            raise HTTPException(status_code=400, detail='File must be an audio type')
        
        audio_bytes = await file.read()
        if not audio_bytes:
            raise HTTPException(status_code=400, detail='No audio data received')
            
        logger.info(f"Received audio data size: {len(audio_bytes)} bytes")
        
        if len(audio_bytes) <= 44:  
            raise HTTPException(status_code=400, detail='Audio data too short, please speak longer')
            
        phoneme_ids = extract_phonemes_from_audio(audio_bytes)
        
        return JSONResponse(content={"phoneme_sequence": phoneme_ids})
    except Exception as e:
        logger.error(f"Error in phoneme_sequence endpoint: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e)) 