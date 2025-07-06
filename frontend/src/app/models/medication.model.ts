export interface MedicationInfo {
  nom: string;
  laboratoire: string;
  date_peremption: string;
  numero_lot: string;
  nombre_unites: number;
  confiance: number;
}

export interface AnalysisResponse {
  medications: MedicationInfo[];
  success: boolean;
  message: string;
}

export interface ApiError {
  detail: string;
}
