# PregnaCare Backend API

Node.js + Express REST API with PostgreSQL and Redis for the PregnaCare reproductive health app.

---

## Tech Stack

| Layer       | Technology                        |
|-------------|-----------------------------------|
| Runtime     | Node.js 20 + Express 4            |
| Database    | PostgreSQL 16 (relational data)   |
| Cache/Auth  | Redis 7 (sessions, token blacklist, predictions cache) |
| Auth        | JWT (access + refresh) + 4-digit PIN |
| AI Coach    | Anthropic Claude API (proxy)      |
| Validation  | express-validator                 |
| Security    | Helmet, CORS, bcrypt, rate-limit  |
| Logging     | Winston                           |

---

## Quick Start

### 1. Prerequisites
- Node.js 20+
- PostgreSQL 16+
- Redis 7+

### 2. Install
```bash
cd pregnacare-backend
npm install
cp .env.example .env
# Edit .env with your credentials
```

### 3. Docker (recommended for local dev)
```bash
docker-compose up -d          # Starts PostgreSQL + Redis
npm run migrate               # Apply schema
npm run seed                  # Load Filipino food data + demo user
npm run dev                   # Start API with hot-reload
```

### 4. Manual setup
```bash
createdb pregnacare
npm run migrate
npm run seed
npm run dev
```

The API runs at: `http://localhost:3000/api/v1`

---

## Demo Credentials (after seeding)
```
Email:    maria.santos@pregnacare.demo
Password: Demo1234!
PIN:      1234
```

---

## Database Schema

### Core Tables
```
users                   — accounts, PIN, language preference
health_profiles         — cycle stats, pregnancy data, wearable config
refresh_tokens          — JWT refresh token rotation
```

### Menstrual Tracking
```
cycle_logs              — period start/end, calculated cycle length
daily_logs              — flow level, symptoms, mood, vitals (upsert per day)
```

### Pregnancy
```
pregnancy_logs          — daily kick counts, vitals, symptoms (upsert per day)
prenatal_checkups       — scheduled OB visits + auto-reminders
ppd_assessments         — Edinburgh Postnatal Depression Scale results
```

### Wellness & Nutrition
```
food_logs               — scanned/logged meals with full nutritional data
food_database           — 20+ Filipino foods with DOH pregnancy notes
breastfeeding_sessions  — side, duration, latch quality
```

### Communication & Safety
```
chat_sessions           — AI coach conversation sessions
chat_messages           — full message history with token tracking
reminders               — medication, checkup, exercise, kick count alerts
sos_events              — emergency SOS with location + vitals snapshot
emergency_contacts      — family/partner contacts for SOS
community_posts         — peer support forum
community_replies       — post replies
```

---

## API Reference

### Authentication
All protected routes require: `Authorization: Bearer <access_token>`

| Method | Endpoint              | Auth | Description                    |
|--------|-----------------------|------|--------------------------------|
| POST   | /auth/register        | —    | Create account                 |
| POST   | /auth/login           | —    | Login, get tokens              |
| POST   | /auth/refresh         | —    | Rotate access + refresh tokens |
| POST   | /auth/logout          | ✅   | Revoke tokens                  |
| PUT    | /auth/pin             | ✅   | Set 4-digit PIN                |
| POST   | /auth/verify-pin      | ✅   | Verify PIN (marks session)     |

### Users
| Method | Endpoint                          | Description                  |
|--------|-----------------------------------|------------------------------|
| GET    | /users/me                         | Get full profile              |
| PATCH  | /users/me                         | Update name, phone, region   |
| GET    | /users/me/health-profile          | Get health profile           |
| PUT    | /users/me/health-profile          | Update cycle/pregnancy data  |
| GET    | /users/me/emergency-contacts      | List emergency contacts       |
| POST   | /users/me/emergency-contacts      | Add emergency contact         |

### Cycle Tracking
| Method | Endpoint                 | Description                              |
|--------|--------------------------|------------------------------------------|
| GET    | /cycles                  | List period history                      |
| POST   | /cycles                  | Log new period (auto-closes previous)    |
| GET    | /cycles/predictions      | Next 4 predicted periods + fertile windows |
| GET    | /cycles/insights         | AI-generated cycle pattern insights     |
| GET    | /cycles/daily-logs       | Daily logs (filter by ?from=&to=)       |
| POST   | /cycles/daily-logs       | Upsert today's log (flow, mood, vitals) |

### Pregnancy
| Method | Endpoint                       | Description                            |
|--------|--------------------------------|----------------------------------------|
| GET    | /pregnancy/status              | Current week, trimester, due date      |
| GET    | /pregnancy/logs                | Pregnancy daily logs                   |
| POST   | /pregnancy/logs                | Log kick count, BP, symptoms           |
| GET    | /pregnancy/checkups            | OB checkup schedule (?upcoming=true)  |
| POST   | /pregnancy/checkups            | Schedule checkup (auto-creates reminder)|
| GET    | /pregnancy/risk-assessment     | Preeclampsia + fetal risk analysis     |

### AI Coach
| Method | Endpoint                           | Description                        |
|--------|------------------------------------|------------------------------------|
| GET    | /chat/sessions                     | List chat sessions                 |
| POST   | /chat/sessions                     | Start new session (mode selection) |
| GET    | /chat/sessions/:id/messages        | Load message history               |
| POST   | /chat/sessions/:id/messages        | Send message, get AI response      |
| POST   | /chat/quick                        | Stateless single-turn Q&A          |

**Chat modes:** `pregnancy` | `menstrual` | `teleconsult` | `general`

### Food & Nutrition
| Method | Endpoint      | Description                              |
|--------|---------------|------------------------------------------|
| GET    | /food         | Today's food log with nutrient totals    |
| POST   | /food         | Log meal with nutritional data           |
| GET    | /food/search  | Search food database (?q=kangkong)       |

### Wellness
| Method | Endpoint                    | Description                   |
|--------|-----------------------------|-------------------------------|
| GET    | /wellness/breastfeeding     | Breastfeeding sessions        |
| POST   | /wellness/breastfeeding     | Log session (side + duration) |
| GET    | /wellness/mood-history      | 30-day mood trend             |
| POST   | /wellness/ppd-assessment    | Submit EPDS assessment        |

### Emergency
| Method | Endpoint                        | Description                          |
|--------|---------------------------------|--------------------------------------|
| POST   | /emergency/sos                  | Trigger SOS with location + vitals   |
| PATCH  | /emergency/sos/:id/resolve      | Mark SOS resolved                    |
| GET    | /emergency/sos/history          | SOS event history                    |

### Reminders
| Method | Endpoint                         | Description                   |
|--------|----------------------------------|-------------------------------|
| GET    | /reminders                       | List reminders (?active=true) |
| POST   | /reminders                       | Create reminder               |
| PATCH  | /reminders/:id                   | Update reminder               |
| DELETE | /reminders/:id                   | Delete reminder               |
| POST   | /reminders/:id/acknowledge       | Mark reminder seen            |

---

## Request/Response Examples

### Register
```json
POST /api/v1/auth/register
{
  "email": "ana@example.com",
  "password": "MyPass123!",
  "full_name": "Ana Reyes",
  "phone": "+639171234567",
  "region": "NCR",
  "language_pref": "fil"
}
```

### Log a Period
```json
POST /api/v1/cycles
Authorization: Bearer <token>
{
  "period_start": "2026-03-25",
  "notes": "Moderate flow, some cramps"
}
```

### Daily Log (mood + vitals)
```json
POST /api/v1/cycles/daily-logs
{
  "log_date": "2026-03-25",
  "has_period": true,
  "flow_level": "moderate",
  "symptoms": ["cramps", "fatigue"],
  "mood_score": 3,
  "mood_label": "tired",
  "heart_rate": 78,
  "bp_systolic": 118,
  "bp_diastolic": 76,
  "water_glasses": 5,
  "steps": 6240
}
```

### Ask AI Coach
```json
POST /api/v1/chat/quick
{
  "message": "Ligtas ba ang kumain ng malunggay sa 24 weeks?",
  "mode": "pregnancy"
}
```

### SOS
```json
POST /api/v1/emergency/sos
{
  "latitude": 14.5547,
  "longitude": 121.0244,
  "location_text": "Makati City, NCR",
  "vital_snapshot": { "hr": 110, "bp_systolic": 150, "bp_diastolic": 98 }
}
```

---

## Environment Variables

See `.env.example` for the full list. Key variables:

```
DB_HOST / DB_PORT / DB_NAME / DB_USER / DB_PASSWORD
REDIS_HOST / REDIS_PORT
JWT_SECRET / JWT_REFRESH_SECRET
ANTHROPIC_API_KEY
EMERGENCY_SMS_KEY     (Semaphore PH for SOS SMS)
FCM_SERVER_KEY        (Firebase push notifications)
```

---

## Security

- **Passwords**: bcrypt (12 rounds)
- **PINs**: bcrypt-hashed, lockout after 5 failed attempts (15 min)
- **JWT**: Short-lived access tokens (7d) + refresh rotation (30d)
- **Token blacklist**: Redis-backed logout invalidation
- **Rate limiting**: Auth (10/15min), Chat (20/min), SOS (3/min), Global (100/15min)
- **Input validation**: express-validator on all routes
- **SQL injection**: Parameterised queries only (pg library)
- **Headers**: Helmet.js (CSP, HSTS, etc.)

---

## Running Tests

```bash
npm test                      # Run all tests
npm test -- --coverage        # With coverage report
```

---

## Production Deployment

```bash
# Build Docker image
docker build -t pregnacare-api .

# Run with production env
docker run -p 3000:3000 --env-file .env pregnacare-api

# Or use docker-compose
docker-compose up -d
```
