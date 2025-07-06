import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { AnalysisResponse } from '../models/medication.model';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class MedicationService {
  private apiUrl = environment.apiUrl;

  constructor(private http: HttpClient) {}

  analyzeMedication(imageFile: File): Observable<AnalysisResponse> {
    const formData = new FormData();
    formData.append('file', imageFile);

    return this.http.post<AnalysisResponse>(`${this.apiUrl}/analyze-medication`, formData)
      .pipe(catchError(this.handleError));
  }

  private handleError(error: HttpErrorResponse) {
    let errorMessage = 'Une erreur est survenue lors de l\'analyse';
    
    if (error.error instanceof ErrorEvent) {
      errorMessage = `Erreur: ${error.error.message}`;
    } else {
      if (error.error?.detail) {
        errorMessage = error.error.detail;
      } else {
        errorMessage = `Erreur ${error.status}: ${error.message}`;
      }
    }
    
    return throwError(() => new Error(errorMessage));
  }
}
