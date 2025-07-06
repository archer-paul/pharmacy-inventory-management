from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import os
import base64
import json
from typing import List
from pydantic import BaseModel
from datetime import datetime
import logging
from dotenv import load_dotenv
import uuid

load_dotenv()

app = FastAPI(title="PharmStock Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("pharmstock")

# Configuration Gemini
try:
    import google.generativeai as genai
    API_KEY = os.getenv("GEMINI_API_KEY")
    if API_KEY:
        genai.configure(api_key=API_KEY)
        GEMINI_AVAILABLE = True
    else:
        GEMINI_AVAILABLE = False
except Exception as e:
    logger.error(f"Erreur Gemini: {e}")
    GEMINI_AVAILABLE = False

# Stockage en mémoire (pour la demo)
medications_storage = []

class MedicationInfo(BaseModel):
    id: str
    nom: str
    laboratoire: str
    date_peremption: str
    numero_lot: str
    nombre_unites: int
    confiance: float
    timestamp: str
    session_id: str = "default"

class AnalysisResponse(BaseModel):
    medications: List[MedicationInfo]
    success: bool
    message: str

class StorageResponse(BaseModel):
    medications: List[MedicationInfo]
    total_count: int
    total_units: int

@app.get("/")
async def root():
    return {
        "message": "PharmStock Backend API", 
        "version": "1.0.0", 
        "gemini_available": GEMINI_AVAILABLE,
        "total_medications": len(medications_storage)
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy", 
        "timestamp": datetime.now().isoformat(),
        "gemini_available": GEMINI_AVAILABLE,
        "stored_medications": len(medications_storage)
    }

@app.post("/analyze-medication", response_model=AnalysisResponse)
async def analyze_medication(file: UploadFile = File(...), session_id: str = "default"):
    try:
        if not file.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="Le fichier doit être une image")
        
        if not GEMINI_AVAILABLE:
            raise HTTPException(status_code=503, detail="Service Gemini non disponible")
        
        image_data = await file.read()
        image_base64 = base64.b64encode(image_data).decode('utf-8')
        
        # Prompt amélioré pour mieux détecter le numéro de lot
        prompt = """
        Analyse cette image de médicaments pharmaceutiques et extrais les informations suivantes pour chaque médicament visible :
        
        1. Nom du médicament (avec dosage si visible)
        2. Laboratoire pharmaceutique (fabricant)
        3. Date de péremption (format DD/MM/YYYY)
        4. Numéro de lot (cherche "LOT", "Lot", "BATCH", "N°", ou des codes alphanumériques)
        5. Nombre d'unités encore présentes (ignore les cases vides)
        
        IMPORTANT pour le numéro de lot :
        - Cherche attentivement tous les codes sur l'emballage
        - Le lot peut être précédé de "LOT:", "Lot", "BATCH", "N°" ou sans préfixe
        - Il s'agit souvent d'un code alphanumériques (ex: AB1234, LOT123456, etc.)
        - Si vraiment illisible, mets "Non lisible" au lieu de "Non identifié"
        
        Retourne UNIQUEMENT un JSON valide :
        {
            "medications": [
                {
                    "nom": "nom complet du médicament",
                    "laboratoire": "nom du laboratoire", 
                    "date_peremption": "DD/MM/YYYY",
                    "numero_lot": "numéro de lot trouvé",
                    "nombre_unites": nombre_entier,
                    "confiance": score_entre_0_et_1
                }
            ]
        }
        """
        
        model = genai.GenerativeModel('gemini-1.5-flash')
        image_part = {"mime_type": file.content_type, "data": image_base64}
        
        logger.info("Début analyse Gemini avec prompt amélioré")
        response = model.generate_content([prompt, image_part])
        
        response_text = response.text
        json_start = response_text.find('{')
        json_end = response_text.rfind('}') + 1
        
        if json_start != -1 and json_end != -1:
            json_str = response_text[json_start:json_end]
            parsed_data = json.loads(json_str)
            
            medications = []
            timestamp = datetime.now().isoformat()
            
            for med_data in parsed_data.get("medications", []):
                medication = MedicationInfo(
                    id=str(uuid.uuid4()),
                    nom=med_data.get("nom", "Non identifié"),
                    laboratoire=med_data.get("laboratoire", "Non identifié"),
                    date_peremption=med_data.get("date_peremption", "Non identifié"),
                    numero_lot=med_data.get("numero_lot", "Non identifié"),
                    nombre_unites=med_data.get("nombre_unites", 0),
                    confiance=med_data.get("confiance", 0.0),
                    timestamp=timestamp,
                    session_id=session_id
                )
                medications.append(medication)
                # Stocker en mémoire
                medications_storage.append(medication)
            
            logger.info(f"Analyse réussie: {len(medications)} médicaments ajoutés au stockage")
            return AnalysisResponse(
                medications=medications,
                success=True,
                message=f"Analyse terminée. {len(medications)} médicament(s) ajouté(s) au stockage."
            )
        else:
            raise HTTPException(status_code=500, detail="Réponse invalide de l'IA")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur analyse: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur lors de l'analyse: {str(e)}")

@app.get("/medications", response_model=StorageResponse)
async def get_all_medications(session_id: str = "default"):
    """Récupérer tous les médicaments stockés"""
    session_meds = [med for med in medications_storage if med.session_id == session_id]
    total_units = sum(med.nombre_unites for med in session_meds)
    
    return StorageResponse(
        medications=session_meds,
        total_count=len(session_meds),
        total_units=total_units
    )

@app.delete("/medications")
async def clear_medications(session_id: str = "default"):
    """Vider le stockage des médicaments"""
    global medications_storage
    before_count = len(medications_storage)
    medications_storage = [med for med in medications_storage if med.session_id != session_id]
    after_count = len(medications_storage)
    cleared = before_count - after_count
    
    return {"message": f"{cleared} médicament(s) supprimé(s)", "remaining": after_count}

@app.get("/medications/export")
async def export_medications_csv(session_id: str = "default"):
    """Exporter les médicaments en CSV"""
    from fastapi.responses import Response
    
    session_meds = [med for med in medications_storage if med.session_id == session_id]
    
    if not session_meds:
        raise HTTPException(status_code=404, detail="Aucun médicament à exporter")
    
    # Créer le CSV
    csv_content = "Nom,Laboratoire,Date péremption,Numéro de lot,Unités,Confiance (%),Horodatage\n"
    for med in session_meds:
        csv_content += f'"{med.nom}","{med.laboratoire}","{med.date_peremption}","{med.numero_lot}",{med.nombre_unites},{round(med.confiance * 100)},"{med.timestamp}"\n'
    
    return Response(
        content=csv_content,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=medicaments_{session_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
