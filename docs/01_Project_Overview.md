# 01 · Project Overview

> 🎓 **Audience:** Academic / project report readers

---

## 1. Project Title

**FieldTrack** — A Digital Field Activity Supervision Platform

### Version
`1.0.0` (Build 42)

### Authors
*FieldTrack Development Team*

### Institution
**Pwani University** — Environmental Sciences (developed in support of field-based academic programmes)

### Supervisor
*Prof. Okeyo* — Project introduction & supervision

### Date
2025

### License
Private / academic research project.

### Repository
- Backend: [`backend/`](../backend)
- Frontend: [`frontend/`](../frontend)
- Documentation: [`docs/`](../docs)

---

## 2. Executive Summary

**What is FieldTrack?**

FieldTrack is a full-stack digital platform that transforms how university students, supervisors, and administrators manage field-based academic activities. It replaces paper-based field logs with a GPS-verified, evidence-backed, real-time digital workflow.

**Why was it developed?**

Field supervision in higher education — particularly for research programmes that require students to conduct fieldwork (environmental science, agriculture, geography, sociology, and similar disciplines) — has historically relied on manual processes. These processes are slow, hard to verify, and leave supervisors blind to what happens in the field until long after the fact.

**The problem it solves:**

- Eliminates the logistical overhead of paper field logs and manual reporting.
- Provides cryptographic-strength *evidence capture* (geo-tagged images, videos, documents) that is much harder to fabricate.
- Enables *real-time monitoring* so supervisors can see, at a glance, which students are in the field and what they are recording.
- Works even in low-connectivity rural field sites through an **offline-first architecture**.

**Target users:**

1. **Students** — record field sessions, log activities, attach evidence, receive feedback.
2. **Supervisors** — monitor students live, review and approve activities, generate reports.
3. **Administrators** — manage users, departments, projects, and system settings.

**Expected impact:**

- Increased accountability and authenticity of field data.
- Reduced administrative burden on academic staff.
- Faster feedback loops between students and supervisors.
- A reusable digital infrastructure that universities can operate on-premises or in the cloud.

---

## 3. Problem Statement

> *The following introduction was provided by Prof. Okeyo and inspired the development of FieldTrack.*

Universities across the region supervise thousands of students who must complete field-based research and practicum activities. Traditional supervision relies on:

1. **Challenges of field supervision** — supervisors cannot physically be present with every student; distances, costs, and scheduling make direct oversight impractical.
2. **Manual verification** — paper field logs are laborious to produce, easy to lose, and difficult to audit.
3. **Evidence authenticity** — without geo-tagged, time-stamped evidence, it is difficult to confirm that claimed activities actually took place at the stated time and location.
4. **GPS challenges** — accurate, tamper-resistant location capture requires careful engineering (permissions, accuracy thresholds, offline buffering, validation).
5. **Lack of real-time monitoring** — supervisors often only discover problems (e.g., students not in the field, incomplete data) weeks after the fieldwork has ended.

FieldTrack addresses each of these challenges with a purpose-built digital supervision workflow that is practical for the connectivity and device constraints of real field environments.

---

## 4. Objectives

### General Objective

> To develop a **digital field activity supervision platform** that enables GPS-verified, evidence-backed, real-time supervision of student field activities.

### Specific Objectives

1. **GPS check-in/check-out** — allow students to begin and end a supervised field session with verified GPS coordinates and accuracy metadata.
2. **Activity tracking** — capture structured field activity logs (objectives, methodology, findings, remarks).
3. **Evidence capture** — attach geo-tagged images, videos, and documents to each activity with automatic compression and thumbnailing.
4. **Supervisor review** — provide a structured review workflow (approve / reject / request revision) with ratings and comments.
5. **Real-time monitoring** — show supervisors and administrators live student status and location on an interactive map.
6. **Reporting** — generate supervisor dashboards and reports filtered by week, month, quarter, or year.
7. **Offline support** — ensure students can record activities in the field even without connectivity, with automatic synchronization when connectivity returns.

---

## 5. Scope

The FieldTrack platform covers:

### Portals
| Portal | Description |
|--------|-------------|
| **Student Portal** | Field session check-in/out, activity logging, evidence upload, feedback, profile & settings |
| **Supervisor Portal** | Dashboard, student list & profiles, field logs, live map, review & approval, reports |
| **Admin Portal** | User management, supervisor assignment, departments, projects, audit logs, notifications, system settings |

### Platform Components
| Component | In Scope |
|-----------|----------|
| **Backend** | ✅ Express REST API, Prisma/PostgreSQL, media processing, notifications |
| **Web** | ✅ Flutter Web build |
| **Android** | ✅ Flutter Android build |
| **Offline Support** | ✅ Hive-based offline mutation queue & caching |
| **Reports** | ✅ Supervisor period reports, admin analytics |
| **Maps** | ✅ flutter_map live student locations & ping history |
| **Notifications** | ✅ In-app + Firebase Cloud Messaging push |

### Out of Scope (v1)
- iOS native build (Flutter supports it, but v1 targets Android/Web)
- AI-assisted verification (see [Future Improvements](./20_Future_Improvements.md))
- IoT sensor integration
- Multi-university tenancy (see [13_Multi_Tenant_Architecture.md](./13_Multi_Tenant_Architecture.md))

