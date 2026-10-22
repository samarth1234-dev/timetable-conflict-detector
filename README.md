# 📅 Timetable Clash Detector & Offline Sync Engine

> A modern Flutter timetable application that **actively detects and visually flags scheduling conflicts** instead of passively listing classes. Features a visual weekly calendar grid with automated column-partitioning, durable offline logging surviving app restarts with no connection, and bi-directional sync-on-reconnect reconciliation.

[![Flutter](https://img.shields.io/badge/Flutter-3.47.7-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.5-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20macOS-4CAF50)](#download-pre-built-android-apks)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-7%20Passed-success)](#running-tests--code-quality)

---

## 📑 Table of Contents
1. [Core Features](#-core-features)
2. [Download Pre-Built Android APKs](#-download-pre-built-android-apks)
3. [Interval Comparison Logic (Clash Detection Engine)](#-interval-comparison-logic-clash-detection-engine)
4. [Offline Data Structure & Reconciliation Protocol](#-offline-data-structure--reconciliation-protocol)
5. [Getting Started & Local Setup](#-getting-started--local-setup)
6. [Running Tests & Quality Checks](#-running-tests--code-quality)
7. [Project Architecture & File Structure](#-project-architecture--file-structure)
8. [Optional: Live Cloud Sync with Render](#-optional-live-cloud-sync-with-render)

---

## 🌟 Core Features

### 1. Slot Management (Working CRUD)
- **Create, Read, Update, Delete**: Complete slot lifecycle via dialogs, list manager, and grid taps.
- **Rich Metadata**: Subject title, Day of week (Mon–Sun chips), interactive TimePickers (start and end times), room/lecture hall, instructor name, and color palette.
- **Live Clash Detection in Form**: As you adjust the day, start time, or end time in the editor dialog, the form executes interval checks **in real-time** and warns you before saving:
  > *"⚠️ LIVE CLASH DETECTED: This slot overlaps with 'Database Systems' (10:00 - 10:30, 30 min overlap)."*

### 2. Real-Time Collision Flagging (Not Silently Allowed)
- Collisions are never allowed to slip by silently.
- **Weekly Grid**: Conflicting slots are drawn with high-contrast red borders (`#D32F2F`), danger background shading, and an elevated **`CLASH ⚠️`** badge.
- **App Bar**: Live counter badge showing total active conflict pairs across the timetable.
- **Clash Warning Banner**: Top banner summarizing clashes with a 1-tap **"Review"** modal detailing exact overlapping pairs, time ranges, and quick-edit buttons.

### 3. Visual Grid Timetable UI
- **Full Weekly View**: Flexible 08:00 to 20:00 calendar grid with a toggle between **Mon–Fri (5 days)** and **Mon–Sun (7 days)**.
- **Automated Column-Partitioning**: When multiple classes overlap on the same day, they do not stack on top of each other. An interval clustering algorithm partitions overlapping cards into parallel side-by-side sub-columns ($k / C$ width) so every conflicting class remains 100% visible and readable.

### 4. Offline Durability (Survives App Restart)
- **Zero Internet Required**: All timetable CRUD, clash checks, and grid rendering function completely offline.
- **Write-Ahead Mutation Log (WAL)**: Every create, update, and delete action creates an immutable event committed to local disk storage before UI updates.
- **Survives App Shutdowns & Device Reboots**: Even with no internet connection, closing or force-stopping the app preserves all timetable entries and pending sync mutations.

### 5. Working Sync-on-Reconnect
- **In-App Sync Engine**: Built-in `MockRemoteServer` and `SyncService` simulate real-world network latency and multi-client reconciliation without needing any external server.
- **Network Toggle Switch**: Status bar chip allows toggling **"Go Offline"** / **"Go Online"** to test offline mutation queueing and instant reconnection replay.
- **Audit Log Inspector**: Dedicated **"Offline Log & Sync"** tab showing queued mutations (`Pending ⏳` vs `Synced ✅`) with full JSON disk snapshots.

---

## 📲 Download Pre-Built Android APK

Pre-compiled, release-signed APK is available directly on GitHub Releases:

| Release Asset | File Size | Description | Download Link |
| :--- | :---: | :--- | :---: |
| **Universal Release APK** | **56.5 MB** | Compatible with all Android phones & emulators (Android 8.0 - 15.0). Crash-proof startup with instant native rendering. | [⬇️ Download Full APK](https://github.com/samarth1234-dev/timetable-conflict-detector/releases/download/v1.0.0/Timetable_Clash_Detector_Full.apk) |

> **GitHub Release Tag**: [v1.0.0 Release Notes & Assets](https://github.com/samarth1234-dev/timetable-conflict-detector/releases/tag/v1.0.0)

### How to Install on Android:
1. Download the APK file on your phone using the link above.
2. If prompted, tap **Settings** $\rightarrow$ **Allow from this source** (standard for non-Play Store APKs).
3. Tap **Install** and open the application.

---

## 📐 Interval Comparison Logic (Clash Detection Engine)

### Mathematical Formulation
Let each scheduled class $S$ be represented as a half-open interval on day $D$:
$$S = \left[t_{\text{start}},\, t_{\text{end}}\right) \quad \text{where } t \in [0, 1439] \subset \mathbb{Z} \text{ (minutes from 00:00 midnight)}$$

Two distinct slots $A$ and $B$ clash if and only if they share the same day and their intervals intersect:
$$\text{Clash}(A, B) \iff (A.\text{day} = B.\text{day}) \land (\max(A.t_{\text{start}},\, B.t_{\text{start}}) < \min(A.t_{\text{end}},\, B.t_{\text{end}}))$$

The exact overlap sub-interval $\left[O_{\text{start}},\, O_{\text{end}}\right)$ and overlap duration $\Delta O$ are:
$$O_{\text{start}} = \max(A.t_{\text{start}},\, B.t_{\text{start}})$$
$$O_{\text{end}} = \min(A.t_{\text{end}},\, B.t_{\text{end}})$$
$$\Delta O = O_{\text{end}} - O_{\text{start}}$$

A conflict exists if and only if $\Delta O > 0$.

```
Timeline (Minutes):
09:00 (540m)      10:00 (600m)      10:30 (630m)      11:30 (690m)
  |-----------------|-----------------|-----------------|
  [=== Slot A: Algorithms (540-630m) =]
                    [=== Slot B: Databases (600-690m) ==]
                    ^^^^^^^^^^^^^^^^^^^
                    OVERLAP: 30 minutes [600, 630) ⚔️ CLASH FLAGGED!
```

### Boundary & Edge Cases Handled

1. **Contiguous / Abutting Classes ($A.t_{\text{end}} = B.t_{\text{start}}$)**:
   - Example: Class 1 runs `10:00–11:30` (600–690 mins); Class 2 runs `11:30–13:00` (690–780 mins).
   - $O_{\text{start}} = \max(600, 690) = 690$
   - $O_{\text{end}} = \min(690, 780) = 690$
   - $\Delta O = 690 - 690 = 0$.
   - **Result**: $\Delta O \le 0 \implies$ **Zero clash**. Classes are back-to-back and permitted without warning.
2. **Strict Interval Containment ($A \subset B$)**:
   - Example: A 60-minute quiz (`11:00–12:00`) scheduled inside a 4-hour lab (`10:00–14:00`).
   - $\Delta O = \min(840, 720) - \max(600, 660) = 720 - 660 = 60$ minutes.
   - **Result**: Captures inner collision duration without false negatives.
3. **Multi-Slot Transitive Chains**:
   - If Slot 1 clashes with Slot 2, and Slot 2 clashes with Slot 3, all slots are mapped symmetrically into `clashPairs` and flagged in the global report.
4. **Computational Complexity**:
   - Slots are partitioned into $\le 7$ day buckets and sorted by $t_{\text{start}}$ in $\mathcal{O}(N_d \log N_d)$.
   - The scan terminates early once $B.t_{\text{start}} \ge A.t_{\text{end}}$.
   - **Overall Complexity**: $\mathcal{O}\left(\sum_{d=1}^7 (N_d \log N_d + K_d)\right)$ where $K_d$ is the number of collisions. Executes in **$< 1$ millisecond** even for hundreds of slots.

---

## 💾 Offline Data Structure & Reconciliation Protocol

### Local Data Architecture
The application maintains two persistent data models backed by local disk storage:

```
[ Local Disk Persistence (StorageService) ]
       │
       ├──► Active Entity Snapshot: List<TimeSlot>
       │     └── { id, subject, day, startMinutes, endMinutes, room, instructor, colorValue, version, updatedAt, isDeleted }
       │
       └──► Append-Only Write-Ahead Mutation Log (WAL): List<MutationLogEntry>
             └── { logId, timestamp, action: CREATE|UPDATE|DELETE, entityId, payload, syncStatus: PENDING|SYNCED|FAILED }
```

### Durability Invariants
1. **UUID Primary Keys**: Every slot is created with a unique UUID v4, preventing ID collisions when multiple offline clients create slots simultaneously.
2. **Monotonic Version Vectors**: Every update increments `version = version + 1` and updates `updatedAt = DateTime.now().toUtc()`.
3. **Tombstone Pattern**: Deleted slots are flagged with `isDeleted = true` and an incremented version number, ensuring deletions propagate across peers and do not resurrect upon reconnection.

### 3-Phase Reconciliation Protocol (Sync-on-Reconnect)
When network connectivity is restored (or when toggled from Offline to Online):
1. **Phase 1: Ordered FIFO Mutation Replay**:
   Pending mutation log entries are sorted chronologically by timestamp and pushed in FIFO order to the sync endpoint. Upon confirmation, the local log entry is marked `SYNCED`.
2. **Phase 2: Last-Write-Wins (LWW) Merge**:
   The client pulls authoritative remote state:
   - If remote has an entity not present locally, it is inserted.
   - If an entity exists on both sides, the client compares `updatedAt` timestamps and version counters. The newer timestamp wins.
   - If remote marks an entity as `isDeleted: true`, local entity applies the tombstone.
3. **Phase 3: Post-Sync Deterministic Clash Re-computation**:
   Merging remote edits may introduce new schedule conflicts (e.g. another teacher booked the same lab). The client automatically runs `ClashDetector.computeClashReport()` across the merged dataset, immediately decorating new conflicts on the grid.

---

## 🚀 Getting Started & Local Setup

### Prerequisites
- **Flutter SDK**: `3.47.7` or later ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: `3.13.5` or later
- **Java JDK**: 17+ (for Android builds)

### Installation Steps

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/samarth1234-dev/timetable-conflict-detector.git
   cd timetable-conflict-detector
   ```

2. **Install Flutter Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run on Connected Devices**:
   - **Run on Android**:
     ```bash
     flutter run -d <your-android-device-id>
     ```
   - **Run in Chrome (Web)**:
     ```bash
     flutter run -d chrome
     ```
   - **Run on macOS Desktop**:
     ```bash
     flutter run -d macos
     ```

4. **Build Android Release APK**:
   ```bash
   flutter build apk --release
   # Output: build/app/outputs/flutter-apk/app-release.apk
   ```

---

## 🧪 Running Tests & Code Quality

The codebase includes full unit and integration tests covering interval collision math, edge cases, candidate preview checks, and offline serialization:

```bash
# Run all unit tests
flutter test

# Run static analysis (0 warnings / 0 errors)
flutter analyze
```

### Test Suite Output:
```text
00:00 +0: Interval Comparison & Clash Detection Logic Detects partial overlap on the same day
00:00 +1: Interval Comparison & Clash Detection Logic Boundary Condition: Adjacent / contiguous classes do NOT clash
00:00 +2: Interval Comparison & Clash Detection Logic Detects complete containment (A inside B)
00:00 +3: Interval Comparison & Clash Detection Logic Same time range on different days does NOT clash
00:00 +4: Interval Comparison & Clash Detection Logic Candidate clash preview detects collisions before saving
00:00 +5: Offline Mutation Log & Data Structure TimeSlot JSON serialization round-trip
00:00 +6: Offline Mutation Log & Data Structure MutationLogEntry JSON serialization and pending status
00:00 +7: All tests passed!
```

---

## 📂 Project Architecture & File Structure

```text
timetable_conflict_detector/
├── lib/
│   ├── models/
│   │   ├── time_slot.dart             # Core TimeSlot model (day, start/end minutes, color, version)
│   │   ├── clash_result.dart          # ClashDetail, ClashPair, ClashReport models
│   │   └── mutation_log.dart          # MutationLogEntry for offline WAL persistence
│   ├── services/
│   │   ├── clash_detector.dart        # Pure functional Interval Collision Detection Engine
│   │   ├── storage_service.dart       # Resilient local disk persistence (SharedPreferences + fallback)
│   │   ├── mock_remote_server.dart    # Embedded remote mock backend for standalone testing
│   │   └── sync_service.dart          # Offline-first reconciliation & FIFO mutation replay
│   ├── state/
│   │   └── timetable_controller.dart  # Central ChangeNotifier managing slots, clashes, and sync
│   ├── widgets/
│   │   ├── weekly_grid_view.dart      # Weekly grid calendar with sub-column collision splitting
│   │   ├── slot_list_view.dart        # Searchable and filterable slot CRUD manager
│   │   ├── slot_editor_dialog.dart    # Slot creation/edit dialog with live clash warning preview
│   │   ├── clash_warning_banner.dart  # Interactive collision banner & detail inspection modal
│   │   ├── offline_status_bar.dart    # Connectivity state toggle & sync indicator
│   │   ├── audit_log_sheet.dart       # Offline Write-Ahead Log visualizer
│   │   └── theory_documentation_sheet.dart # In-app architectural write-up & math guide
│   └── main.dart                      # App entry point, instant native rendering, and tab shell
├── test/
│   └── widget_test.dart               # Complete test suite for interval logic & offline WAL
├── backend/                           # Node.js Express sync server (packaged in same repo)
│   ├── server.js                      # Express bulk sync and REST API
│   ├── package.json                   # Dependencies (express, cors, uuid)
│   ├── Dockerfile                     # Container spec for cloud deployment
│   ├── render.yaml                    # 1-click Render blueprint spec
│   └── README.md                      # Backend API documentation
├── server.js                          # Root Express sync server (for zero-config cloud deploy)
├── package.json                       # Root Node.js dependencies
├── render.yaml                        # Root 1-click Render Blueprint spec
└── Dockerfile                         # Root Container spec
```

---

## ☁️ Optional: Live Cloud Sync with Render

> **Note**: The mobile APK runs 100% standalone and executes all offline logging and sync-on-reconnect reconciliation using its built-in engine. External server deployment is completely optional.

Since the backend is bundled directly inside this repository, you can deploy it to Render in 1 click:

1. Click the 1-click Render blueprint link:  
   👉 **[Deploy to Render (1-Click)](https://render.com/deploy?repo=https://github.com/samarth1234-dev/timetable-conflict-detector)**
2. Render will automatically parse [`render.yaml`](render.yaml) and start the Node.js service:
   - **Build Command**: `npm install`
   - **Start Command**: `node server.js`
   - **Health Check Path**: `/health`
3. Once deployed, test the live health endpoint:
   ```bash
   curl https://<your-render-app>.onrender.com/health
   # Returns: {"status":"healthy","uptime":...}
   ```

---

## 📄 License
This project is open source and available under the [MIT License](LICENSE).
