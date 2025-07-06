from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import google.generativeai as genai
import os
import base64
import json
from typing import List
from pydantic import BaseModel
from datetime import datetime
import logging

# Configuration de l'application
app = FastAPI(title="PharmStock Backend", version="1.0.0", description="API pour gestion des stocks pharmaceutiques")

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"],  # En production, restreignez à vos domaines
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration de l'API Gemini
try:
    genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
    logger = logging.getLogger("pharmstock")
    logger.info("API Gemini configurée")
except Exception as e:
    logger = logging.getLogger("pharmstock")
    logger.error(f"Erreur configuration Gemini: {e}")

# Modèles Pydantic
class MedicationInfo(BaseModel):
    nom: str
    laboratoire: str
    date_peremption: str
    numero_lot: str
    nombre_unites: int
    confiance: float

class AnalysisResponse(BaseModel):
    medications: List[MedicationInfo]
    success: bool
    message: str

@app.get("/")
async def root():
    return {"message": "PharmStock Backend API", "version": "1.0.0", "status": "running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.post("/analyze-medication", response_model=AnalysisResponse)
async def analyze_medication(file: UploadFile = File(...)):
    try:
        if not file.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="Le fichier doit être une image")
        
        # Lire le contenu de l'image
        image_data = await file.read()
        image_base64 = base64.b64encode(image_data).decode('utf-8')
        
        # Prompt optimisé pour l'analyse
        prompt = """
        Analyse cette image de médicaments et extrais les informations suivantes pour chaque médicament visible :
        1. Nom du médicament (avec dosage si visible)
        2. Laboratoire pharmaceutique  
        3. Date de péremption (format DD/MM/YYYY)
        4. Numéro de lot
        5. Nombre d'unités encore présentes (ignore les cases vides des plaquettes)
        
        Retourne UNIQUEMENT un JSON valide au format :
        {
            "medications": [
                {
                    "nom": "nom du médicament",
                    "laboratoire": "nom du laboratoire", 
                    "date_peremption": "DD/MM/YYYY",
                    "numero_lot": "numéro de lot",
                    "nombre_unites": nombre_entier,
                    "confiance": score_entre_0_et_1
                }
            ]
        }
        
        Si une information n'est pas lisible, mets "Non identifié" pour les textes et 0 pour les nombres.
        """
        
        # Analyser avec Gemini
        model = genai.GenerativeModel('gemini-1.5-flash')
        image_part = {"mime_type": file.content_type, "data": image_base64}
        response = model.generate_content([prompt, image_part])
        
        # Parser la réponse JSON
        response_text = response.text
        json_start = response_text.find('{')
        json_end = response_text.rfind('}') + 1
        
        if json_start != -1 and json_end != -1:
            json_str = response_text[json_start:json_end]
            parsed_data = json.loads(json_str)
            
            medications = []
            for med_data in parsed_data.get("medications", []):
                medication = MedicationInfo(
                    nom=med_data.get("nom", "Non identifié"),
                    laboratoire=med_data.get("laboratoire", "Non identifié"),
                    date_peremption=med_data.get("date_peremption", "Non identifié"),
                    numero_lot=med_data.get("numero_lot", "Non identifié"),
                    nombre_unites=med_data.get("nombre_unites", 0),
                    confiance=med_data.get("confiance", 0.0)
                )
                medications.append(medication)
            
            return AnalysisResponse(
                medications=medications,
                success=True,
                message=f"Analyse terminée. {len(medications)} médicament(s) détecté(s)."
            )
        else:
            raise HTTPException(status_code=500, detail="Réponse invalide de l'IA")
            
    except Exception as e:
        logger.error(f"Erreur analyse: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur lors de l'analyse: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
