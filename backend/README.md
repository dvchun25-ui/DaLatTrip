# DALATTRIP backend

FastAPI proxy for Gemini structured trip parsing and Google Places photos.

## Setup

1. Copy `.env.example` to `.env`.
2. Put a newly rotated Gemini key in `GEMINI_API_KEY`.
3. Add `GOOGLE_PLACES_API_KEY` when available.
4. Install dependencies:
   `python -m pip install -r requirements.txt`
5. Start:
   `uvicorn app.main:app --reload`

The Flutter app defaults to `http://10.0.2.2:8000/api/v1` on Android emulator.
Override with `--dart-define=API_BASE_URL=http://HOST:8000/api/v1`.
