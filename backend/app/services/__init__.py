"""
Services module pour PharmStock Backend
"""

SERVICE_CONFIG = {
    "gemini": {"model_name": "gemini-1.5-flash", "max_retries": 3, "timeout": 30, "temperature": 0.1},
    "image": {"max_size": 10 * 1024 * 1024, "allowed_formats": ["image/jpeg", "image/jpg", "image/png", "image/webp"], "quality": 85, "max_dimensions": (3000, 3000)},
    "validation": {"min_confidence": 0.3, "max_medications_per_image": 20, "required_fields": ["nom", "laboratoire", "date_peremption", "numero_lot"]},
}
