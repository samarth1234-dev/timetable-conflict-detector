# 🚀 Timetable Clash Detector & Sync Engine Backend

> Production-ready Node.js Express synchronization backend for the **Timetable Clash Detector** Flutter application. Features REST API endpoints, real-time collision detection verification, and batch reconciliation using Last-Write-Wins (LWW) conflict resolution.

[![Node.js](https://img.shields.io/badge/Node.js-18%2B-green.svg)](https://nodejs.org/)
[![Express](https://img.shields.io/badge/Express-4.19-lightgrey.svg)](https://expressjs.com/)
[![Render](https://img.shields.io/badge/Render-Deploy%20Ready-46E3B7.svg)](https://render.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## ⚡ 1-Click Render Deployment

Click the button below to deploy this backend directly to Render with zero configuration needed:

👉 **[Deploy to Render (1-Click)](https://render.com/deploy?repo=https://github.com/samarth1234-dev/timetable-backend)**

Render will automatically detect [`render.yaml`](render.yaml):
- **Runtime**: `Node`
- **Build Command**: `npm install`
- **Start Command**: `node server.js`
- **Health Check Path**: `/health`

---

## 📡 API Endpoints Reference

### 1. Health Check
- **`GET /health`**
- **Description**: Returns server status, uptime, and count of active slots.
- **Response**:
  ```json
  {
    "status": "healthy",
    "timestamp": "2026-10-22T15:45:00.000Z",
    "uptime": 124.5,
    "activeSlots": 5
  }
  ```

### 2. Timetable Slot Management
- **`GET /api/slots`**: Returns all slots (both active and tombstoned).
- **`POST /api/slots`**: Adds a new class slot.
  ```json
  {
    "subject": "Advanced Operating Systems",
    "day": 2,
    "startMinutes": 660,
    "endMinutes": 750,
    "room": "Hall OS-105",
    "instructor": "Prof. Tanenbaum",
    "colorValue": 4282613831
  }
  ```
- **`PUT /api/slots/:id`**: Updates an existing slot and increments version.
- **`DELETE /api/slots/:id`**: Soft-deletes a slot by applying a tombstone (`isDeleted = true`).

### 3. Server-Side Clash Detection
- **`GET /api/clashes`**: Evaluates intervals and returns all conflicting pairs on the server.
- **Response**:
  ```json
  {
    "success": true,
    "report": {
      "clashingSlotIds": ["slot-1", "slot-2"],
      "totalConflictPairs": 1,
      "clashPairs": [
        {
          "slotA": { "id": "slot-1", "subject": "Data Structures & Algorithms" },
          "slotB": { "id": "slot-2", "subject": "Database Systems" },
          "overlapMinutes": 30,
          "overlapRange": "600-630"
        }
      ]
    }
  }
  ```

### 4. Batch Offline-to-Online Sync Reconciliation
- **`POST /api/sync`**: Replays queued client mutations and resolves conflicts using Last-Write-Wins (LWW).
- **Request Body**:
  ```json
  {
    "mutations": [
      {
        "action": "CREATE",
        "entityId": "uuid-1234",
        "payload": { ... },
        "timestamp": "2026-10-22T15:30:00.000Z"
      }
    ]
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "syncedCount": 1,
    "slots": [ ... ],
    "serverTimestamp": "2026-10-22T15:45:00.000Z"
  }
  ```

---

## 🛠️ Local Development

```bash
# Clone the repository
git clone https://github.com/samarth1234-dev/timetable-backend.git
cd timetable-backend

# Install dependencies
npm install

# Start development server with live reload
npm run dev

# Or start in production mode
npm start
```

Default port is `3000` (or `process.env.PORT`). Visit `http://localhost:3000/health`.

---

## 🐳 Docker Deployment

```bash
# Build Docker image
docker build -t timetable-backend .

# Run Docker container
docker run -p 3000:3000 timetable-backend
```

---

## 📱 Related Repositories
- **Flutter Frontend App**: [samarth1234-dev/timetable-conflict-detector](https://github.com/samarth1234-dev/timetable-conflict-detector)
- **Pre-Built Android Release APK**: [Download APK v1.0.0](https://github.com/samarth1234-dev/timetable-conflict-detector/releases/tag/v1.0.0)
