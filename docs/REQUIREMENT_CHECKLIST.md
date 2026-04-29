# 🕋 Mish Umrah Guide: Requirement & Progress Checklist
*Based on Methodchap3.pdf (DSR & Agile Framework)*

## 📍 Phase 1: Core Geofencing & Simulation Engine (Current Focus)
*Objective: Stabilize location tracking, map rendering, and basic geofence boundaries.*

- [x] **Geofence Engine Initialization**: Setup `geolocator` stream and base provider.
- [x] **Tawaf Zone Configuration**: Set strict 75m radius for Mataf/Tawaf area.
- [x] **Web/Emulator Stabilization**: Fix `AbortError`, tile buffering, and viewport scaling.
- [x] **GPS Optimization**: Implement 0.5m movement throttle to prevent UI jitter/infinite loops.
- [x] **Instant Pinning UX**: Use cached position for 0-delay manual Kaabah pinning.
- [x] **Auto-Follow Camera**: Map smoothly tracks user movement during Tawaf.
- [x] **Local Notifications (Basic)**: Trigger alerts on Entry/Exit of Tawaf Zone.
- [x] **Sa'i Zone Implementation**: Configure Safa & Marwa points (100m x 450m corridor logic).
- [x] **Miqat Detection**: Configure 150-200m early detection zones.

---

## 🔄 Phase 2: Dual-Mode Architecture & Ritual Progression
*Objective: Enforce the rules of Umrah based on the user's selected mode.*

- [ ] **Mode Selection State**: Toggle between 'Manual' and 'Location-Based'.
- [ ] **Manual Mode Logic**: Allow unrestricted access to ritual guides without GPS triggers.
- [ ] **Location-Based Enforcement**: 
  - [ ] Block Tawaf access until Miqat/Niyyah is cleared.
  - [ ] Block Sa'i access until Tawaf (Checkpoint) is completed.
- [ ] **Tawaf Persistence & Recovery**: If user exits radius, prompt 'Continue/End'. Save state if 'End' to allow resumption. [NEW]
- [x] **Sa'i Trip Logic**: User must reach both Safa and Marwa to count as 1 lap. [NEW]
- [x] **Ritual Guidance UI**: Auto-display contextual Du'a, Niyyah, and step-by-step instructions when a geofence is triggered. (In-App Popup/Display). [REFINED]

---

## 🗄️ Phase 3: Backend Integration (MySQL & RESTful API)
*Objective: Connect the Flutter frontend to the 3-tier architecture database.*

- [ ] **Database Schema Setup**: Implement ERD (Pilgrims, Schedules, Locations, Progress).
- [ ] **Auth & Profile Module**: User Registration / Login.
- [ ] **State Syncing**: Save and retrieve Ritual Progress (Pending, InProgress, Completed) from the server.
- [ ] **Offline Caching**: Locally cache mode preferences for seamless offline-to-online transitions.

---

## 🚀 Phase 4: Advanced Optimizations & Polish (FYP2 Prep)
*Objective: Ensure production readiness, battery efficiency, and edge-case handling.*

- [ ] **Background Geofencing**: Integrate native Android/iOS background tracking for battery efficiency.
- [ ] **Adaptive Scheduling**: Fetch crowd density API to suggest rerouting.
- [ ] **Privacy & Consent**: Implement PDPA/GDPR compliant location permission onboarding.
- [ ] **UI Polish (Rank S)**: Finalize animations, typography, and "Clean Light" aesthetic.

---
*Last Updated: 30 April 2026 by Jargon (Squad)*
