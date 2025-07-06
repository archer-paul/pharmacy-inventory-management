# PharmStock - Pharmaceutical Inventory Management

**[Français](README.fr.md) | English**

A modern web application designed for pharmacists to intelligently manage pharmaceutical stock recovered from hospitals using AI-powered analysis.

## Live Demo

**🚀 Try the application now: [https://pharmstock-prod-2025.web.app](https://pharmstock-prod-2025.web.app)**

The application is fully deployed and ready to use. Simply visit the link above to start managing your pharmaceutical inventory.

## Features

- **Intelligent Scanner**: Photo capture with smartphone camera for medication analysis
- **AI Analysis**: Automatic extraction of medication information using Google Gemini Vision
  - Drug name and dosage
  - Pharmaceutical laboratory
  - Expiration date
  - Batch/lot number
  - Unit count (excluding empty blisters)
- **Mobile-First Interface**: Responsive design optimized for smartphones
- **Data Export**: CSV download and clipboard copy functionality
- **Multi-Session Management**: Support for multiple scanning sessions
- **Real-Time Inventory**: Live inventory management with automatic updates

## Architecture

### Frontend (HTML/CSS/JavaScript)
- **Technology**: Vanilla JavaScript with modern web standards
- **UI/UX**: Modern green/white design, mobile-first responsive layout
- **Camera**: Native camera access with intuitive interface
- **PWA Ready**: Offline support and mobile installation capability

### Backend (Python FastAPI)
- **Framework**: FastAPI with multipart file handling
- **AI**: Google Gemini Vision integration for image analysis
- **API**: RESTful API with automatic Swagger documentation
- **CORS**: Configured for development and production environments

### Deployment (Google Cloud Platform)
- **Backend**: Cloud Run (containerized with Docker)
- **Frontend**: Firebase Hosting
- **CI/CD**: Cloud Build for automatic deployment
- **Secrets**: Secret Manager for API key management

## User Journey

1. **Welcome**: Landing page with feature overview
2. **Scanner**: Camera interface with visual guide and intuitive capture
3. **Analysis**: Loading indicator with progress during AI analysis
4. **Results**: Detailed table with export options and new scan capability
5. **Multi-Scan**: Result accumulation for multiple captures

## Quick Start

The application is ready to use at **[https://pharmstock-prod-2025.web.app](https://pharmstock-prod-2025.web.app)**

### For Development

#### Prerequisites
- Node.js 18+
- Python 3.11+
- Google Cloud CLI
- Firebase CLI

#### Backend Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or venv\Scripts\activate  # Windows
pip install -r requirements.txt

# Create .env file with your Gemini API key
echo "GEMINI_API_KEY=your_api_key" > .env

# Start server
python -m uvicorn app.main_storage:app --reload --port 8000
```

#### Frontend Development
```bash
cd frontend
# Start local server (for development)
python -m http.server 8080
```

Local application will be accessible at `http://localhost:8080`

## Google Cloud Deployment

### Prerequisites
1. Google Cloud account with billing enabled
2. Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

### Automated Deployment
```bash
# 1. Setup GCP project
./setup_gcp.sh

# 2. Configure Gemini API key
./setup_gemini.sh

# 3. Deploy application
./deploy_pharmstock.sh
```

### Manual Deployment Steps

#### 1. GCP Configuration
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

#### 2. Gemini API Setup
```bash
# Store API key in Secret Manager
echo -n "YOUR_GEMINI_API_KEY" | gcloud secrets create gemini-api-key --data-file=-
```

#### 3. Backend Deployment
```bash
# Build and deploy to Cloud Run
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/pharmstock-backend ./backend
gcloud run deploy pharmstock-backend \
    --image gcr.io/YOUR_PROJECT_ID/pharmstock-backend \
    --region europe-west1 \
    --allow-unauthenticated \
    --update-secrets GEMINI_API_KEY=gemini-api-key:latest
```

#### 4. Frontend Deployment
```bash
# Configure Firebase
firebase login
firebase init hosting
firebase use --add YOUR_PROJECT_ID

# Deploy to Firebase Hosting
firebase deploy
```

## API Documentation

### Medication Analysis
```http
POST /analyze-medication
Content-Type: multipart/form-data

file: image file
session_id: string (optional, default: "default")
```

### Response Format
```json
{
  "medications": [
    {
      "id": "uuid",
      "nom": "Medication Name 1000mg",
      "laboratoire": "Pharmaceutical Lab",
      "date_peremption": "12/2025",
      "numero_lot": "ABC123",
      "nombre_unites": 8,
      "confiance": 0.95,
      "timestamp": "2025-01-15T10:30:00",
      "session_id": "default"
    }
  ],
  "success": true,
  "message": "Analysis completed successfully"
}
```

### Inventory Management
```http
GET /medications?session_id=default     # Get all medications
DELETE /medications?session_id=default  # Clear inventory
GET /medications/export?session_id=default  # Export CSV
GET /health                             # Health check
```

## Configuration

### Environment Variables
- `GEMINI_API_KEY`: Google Gemini API key (required)
- `PORT`: Server port (default: 8080 for Cloud Run)

### API Optimization
The Gemini prompt is optimized to extract:
- Medication name with dosage
- Pharmaceutical laboratory
- Expiration date (DD/MM/YYYY format)
- Batch/lot number with improved detection
- Unit count excluding empty blister slots
- Confidence score for analysis quality

## Project Structure

```
pharmacy-inventory-management/
├── README.md                 # English documentation
├── README.fr.md             # French documentation  
├── LICENSE                  # MIT License
├── backend/                 # FastAPI application
│   ├── app/
│   │   ├── main_storage.py    # Main application entry point
│   │   ├── services/          # Business logic services
│   │   └── __init__.py        # Application metadata
│   ├── Dockerfile             # Container configuration
│   └── requirements.txt       # Python dependencies
├── frontend/                  # Static web application
│   ├── index.html            # Main application file
│   ├── firebase.json         # Firebase hosting configuration
│   └── src/                  # Original Angular artifacts (deprecated)
├── deployment/               # Deployment scripts
│   ├── setup_gcp.sh         # GCP project setup
│   ├── setup_gemini.sh      # API key configuration
│   └── deploy_pharmstock.sh # Full deployment automation
└── .gcp_config              # Deployment configuration
```

## Design System

### Colors
- **Primary**: Medical green (#28a745, #20c997)
- **Secondary**: White/Gray (#f8f9fa, #e9ecef)
- **Accent**: Information blue (#17a2b8)
- **Error**: Red (#dc3545)

### Components
- **Buttons**: Green gradients with hover animations
- **Cards**: Subtle shadows with rounded corners
- **Loading**: Animated spinners with messaging
- **Tables**: Responsive with visual indicators

## Security

### Frontend
- File type validation (images only)
- User error handling
- HTTPS required for camera access

### Backend
- Strict upload validation
- File size limitations
- CORS configured for authorized domains
- Secret management via Google Secret Manager

## Performance Optimizations

### Image Processing
- Automatic compression before upload
- Format validation and conversion
- Size optimization for API calls

### Deployment
- **Bundle**: Optimized static assets
- **Cache**: Optimized cache headers
- **CDN**: Firebase Hosting global distribution

### Mobile
- **PWA**: Home screen installation
- **Offline**: Critical asset caching
- **Touch**: Optimized touch interface
- **Responsive**: Adaptive breakpoints

## Troubleshooting

### Common Issues
1. **Camera not accessible**: Check HTTPS and permissions
2. **CORS Error**: Verify backend URL in application
3. **Gemini API Error**: Check API key and quotas
4. **Deployment Error**: Verify GCP billing and API enablement

### Useful Commands
```bash
# Backend Cloud Run logs
gcloud logs read --service=pharmstock-backend

# Frontend Firebase logs
firebase hosting:channel:list

# Health check
curl https://pharmstock-backend-dssnndhw7a-ew.a.run.app/health
```

## Cost Management

### Google Cloud Costs
- **Cloud Run**: Pay-per-request (very low cost for typical usage)
- **Firebase Hosting**: Free tier sufficient for most use cases
- **Gemini API**: Pay-per-request (approximately $0.001 per image)
- **Secret Manager**: Minimal cost for API key storage

### Optimization Tips
- Use Cloud Run min-instances=0 for cost efficiency
- Monitor Gemini API usage in Google Cloud Console
- Set up billing alerts for cost control

## Roadmap

### Version 1.1
- [ ] User authentication system
- [ ] Scan history and persistence
- [ ] Push notifications for expiration dates
- [ ] Batch mode for simultaneous multiple scanning

### Version 1.2
- [ ] Medication database integration
- [ ] Automatic correction suggestions
- [ ] Analytics and reporting dashboard
- [ ] Public API for third-party integrations

## License

MIT License - See LICENSE file for details.

## Support

For issues and questions:
1. Check the [troubleshooting section](#troubleshooting)
2. Review Cloud Run logs for backend issues
3. Test the live application at [https://pharmstock-prod-2025.web.app](https://pharmstock-prod-2025.web.app)

---

**Built with ❤️ by Paul** | **Try it now: [pharmstock-prod-2025.web.app](https://pharmstock-prod-2025.web.app)**