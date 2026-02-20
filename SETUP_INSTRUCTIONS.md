# ExamAI - Setup Instructions

## 📱 Flutter App (Frontend)

The Flutter app is ready to run. Just execute:

```bash
flutter pub get
flutter run
```

### Demo Login Credentials
- **Email**: `student@exam.ai`
- **Password**: `test1234`

---

## 🤖 AI Backend (FastAPI) — Setup Guide

You are deploying the AI part separately. Here's how to set up the FastAPI backend.

### 1. Prerequisites
- Python 3.10+ installed
- `pip` or `pipenv` or `poetry` for dependency management

### 2. Create the Project

```bash
mkdir examai-backend
cd examai-backend
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install fastapi uvicorn python-multipart pillow pytesseract pydantic supabase python-dotenv
```

Optional (for AI/ML features):
```bash
pip install openai langchain transformers torch scikit-learn pandas numpy
```

### 4. Project Structure

```
examai-backend/
├── main.py                 # FastAPI entry point
├── .env                    # Environment variables
├── requirements.txt        # Dependencies
├── routers/
│   ├── auth.py             # Authentication endpoints
│   ├── tests.py            # Test/quiz endpoints
│   ├── analytics.py        # Progress analytics endpoints
│   ├── recommendations.py  # AI recommendation endpoints
│   └── ocr.py              # Camera/PYQ scanning endpoints
├── services/
│   ├── ai_service.py       # AI/ML logic (predictions, recommendations)
│   ├── ocr_service.py      # OCR processing logic
│   └── supabase_service.py # Supabase client wrapper
├── models/
│   ├── user.py             # User data models
│   ├── test.py             # Test/Question models
│   └── analytics.py        # Analytics models
└── utils/
    └── helpers.py           # Utility functions
```

### 5. Create `main.py`

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="ExamAI Backend",
    description="AI-Powered Competitive Exam Performance Analytics API",
    version="1.0.0"
)

# CORS — allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "ExamAI API is running"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

# Import and include routers
# from routers import auth, tests, analytics, recommendations, ocr
# app.include_router(auth.router, prefix="/api/auth", tags=["Auth"])
# app.include_router(tests.router, prefix="/api/tests", tags=["Tests"])
# app.include_router(analytics.router, prefix="/api/analytics", tags=["Analytics"])
# app.include_router(recommendations.router, prefix="/api/recommendations", tags=["Recommendations"])
# app.include_router(ocr.router, prefix="/api/ocr", tags=["OCR"])
```

### 6. Create `.env`

```env
# Supabase
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# OpenAI (if using GPT for recommendations)
OPENAI_API_KEY=sk-your-key-here

# App
APP_ENV=development
SECRET_KEY=your-secret-key-for-jwt
```

### 7. Run the Server

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at: `http://localhost:8000`  
Swagger docs at: `http://localhost:8000/docs`

### 8. Key API Endpoints to Implement

| Method | Endpoint                     | Description                           |
|--------|------------------------------|---------------------------------------|
| POST   | `/api/auth/login`            | User login                            |
| POST   | `/api/auth/register`         | User registration                     |
| GET    | `/api/tests`                 | List available tests                  |
| POST   | `/api/tests/submit`          | Submit test answers                   |
| GET    | `/api/analytics/overview`    | Overall performance analytics         |
| GET    | `/api/analytics/subject/:id` | Subject-wise breakdown                |
| GET    | `/api/analytics/progress`    | Weekly progress data                  |
| POST   | `/api/ocr/scan`              | Upload & scan PYQ image               |
| GET    | `/api/recommendations`       | Get AI-powered study recommendations  |

### 9. Connecting Flutter to FastAPI

In the Flutter app, create an API service class:

```dart
// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your deployed URL
  static const String baseUrl = 'http://localhost:8000/api';

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl/$endpoint'));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }
}
```

Add the `http` package to `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.2.0
```

---

## 🗄️ Database (Supabase) — Setup Guide

### 1. Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and sign up / log in.
2. Click **"New Project"**.
3. Choose your organization, give it a name (e.g., `examai`), set a strong database password, and select a region.
4. Wait for the project to be created (~2 minutes).

### 2. Get Your API Keys

1. Go to **Project Settings → API**.
2. Copy these values into your `.env` file:
   - `Project URL` → `SUPABASE_URL`
   - `anon/public key` → `SUPABASE_ANON_KEY`
   - `service_role key` → `SUPABASE_SERVICE_ROLE_KEY` (keep this secret!)

### 3. Create Database Tables

Go to **SQL Editor** in Supabase and run these queries:

```sql
-- Users table (Supabase Auth handles auth, this stores profile data)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    avatar_url TEXT,
    exam_target TEXT DEFAULT 'JEE Main',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tests table
CREATE TABLE public.tests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    exam_type TEXT NOT NULL,  -- 'JEE Main', 'NEET', etc.
    duration_minutes INT NOT NULL DEFAULT 180,
    total_marks INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Questions table
CREATE TABLE public.questions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    test_id UUID REFERENCES public.tests(id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    topic TEXT NOT NULL,
    difficulty TEXT NOT NULL DEFAULT 'Medium',  -- Easy, Medium, Hard
    question_text TEXT NOT NULL,
    option_a TEXT NOT NULL,
    option_b TEXT NOT NULL,
    option_c TEXT NOT NULL,
    option_d TEXT NOT NULL,
    correct_option CHAR(1) NOT NULL,  -- A, B, C, D
    explanation TEXT,
    marks INT NOT NULL DEFAULT 4,
    negative_marks INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Test Attempts (student submissions)
CREATE TABLE public.test_attempts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    test_id UUID REFERENCES public.tests(id) ON DELETE CASCADE,
    score INT NOT NULL,
    total_marks INT NOT NULL,
    percentage DECIMAL(5,2) NOT NULL,
    time_taken_minutes INT,
    submitted_at TIMESTAMPTZ DEFAULT NOW()
);

-- Individual question responses
CREATE TABLE public.question_responses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    attempt_id UUID REFERENCES public.test_attempts(id) ON DELETE CASCADE,
    question_id UUID REFERENCES public.questions(id) ON DELETE CASCADE,
    selected_option CHAR(1),  -- A, B, C, D, NULL if skipped
    is_correct BOOLEAN NOT NULL DEFAULT FALSE,
    time_spent_seconds INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Scanned PYQ papers
CREATE TABLE public.scanned_papers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    exam_type TEXT NOT NULL,
    year INT,
    image_url TEXT,
    extracted_text TEXT,
    questions_extracted INT DEFAULT 0,
    status TEXT DEFAULT 'processing',  -- processing, completed, failed
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI Recommendations
CREATE TABLE public.recommendations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    subject TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'Medium',  -- High, Medium, Low
    type TEXT NOT NULL DEFAULT 'practice',    -- practice, revision, test
    estimated_time TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Weekly progress snapshots
CREATE TABLE public.weekly_progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    week_start DATE NOT NULL,
    average_score DECIMAL(5,2),
    tests_taken INT DEFAULT 0,
    total_time_minutes INT DEFAULT 0,
    physics_avg DECIMAL(5,2),
    chemistry_avg DECIMAL(5,2),
    maths_avg DECIMAL(5,2),
    biology_avg DECIMAL(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 4. Enable Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scanned_papers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_progress ENABLE ROW LEVEL SECURITY;

-- Policies: users can only read/write their own data
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own attempts" ON public.test_attempts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own attempts" ON public.test_attempts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own responses" ON public.question_responses
    FOR SELECT USING (
        attempt_id IN (SELECT id FROM public.test_attempts WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can insert own responses" ON public.question_responses
    FOR INSERT WITH CHECK (
        attempt_id IN (SELECT id FROM public.test_attempts WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can view own scans" ON public.scanned_papers
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own scans" ON public.scanned_papers
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own recommendations" ON public.recommendations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own progress" ON public.weekly_progress
    FOR SELECT USING (auth.uid() = user_id);

-- Tests and questions are public (read-only for all authenticated users)
ALTER TABLE public.tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view tests" ON public.tests
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can view questions" ON public.questions
    FOR SELECT USING (auth.role() = 'authenticated');
```

### 5. Set Up Storage (for PYQ image uploads)

1. Go to **Storage** in Supabase dashboard.
2. Create a new bucket called `pyq-scans`.
3. Set bucket policy to allow authenticated uploads:

```sql
CREATE POLICY "Users can upload PYQ scans"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'pyq-scans' AND auth.role() = 'authenticated');

CREATE POLICY "Users can view their own scans"
ON storage.objects FOR SELECT
USING (bucket_id = 'pyq-scans' AND auth.role() = 'authenticated');
```

### 6. Connect FastAPI to Supabase

```python
# services/supabase_service.py
import os
from supabase import create_client, Client

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

supabase: Client = create_client(url, key)

# Example: Fetch user profile
def get_user_profile(user_id: str):
    response = supabase.table("profiles").select("*").eq("id", user_id).single().execute()
    return response.data

# Example: Save test attempt
def save_test_attempt(user_id: str, test_id: str, score: int, total: int):
    data = {
        "user_id": user_id,
        "test_id": test_id,
        "score": score,
        "total_marks": total,
        "percentage": round((score / total) * 100, 2),
    }
    response = supabase.table("test_attempts").insert(data).execute()
    return response.data

# Example: Get recommendations
def get_recommendations(user_id: str):
    response = (
        supabase.table("recommendations")
        .select("*")
        .eq("user_id", user_id)
        .eq("is_completed", False)
        .order("created_at", desc=True)
        .execute()
    )
    return response.data
```

### 7. Deployment Options for FastAPI

| Platform       | Free Tier | Notes                               |
|----------------|-----------|-------------------------------------|
| **Railway**    | Yes       | Easy deploy, connect GitHub repo    |
| **Render**     | Yes       | Free web services with sleep        |
| **Fly.io**     | Yes       | Good for global deployment          |
| **AWS Lambda** | Yes       | Use Mangum adapter for FastAPI      |
| **DigitalOcean App Platform** | $5/mo | Simple container deploy |

Example Dockerfile for deployment:

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## 📋 Summary

| Component      | Tech                | Status         |
|----------------|---------------------|----------------|
| Frontend       | Flutter             | ✅ Built        |
| Auth           | Sample account      | ✅ Built        |
| AI Backend     | FastAPI + Python    | 📝 Instructions |
| Database       | Supabase (Postgres) | 📝 Instructions |
| OCR            | Tesseract / Google Vision | 📝 Instructions |
| AI/ML          | OpenAI / Custom     | 📝 Instructions |

When you're ready to connect the Flutter app to the real backend, replace the sample data in `lib/constants/sample_data.dart` with API calls using the `ApiService` class.
