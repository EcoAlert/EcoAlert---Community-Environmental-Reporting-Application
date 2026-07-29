# FixAlert

A community environmental issue-reporting platform built with Flutter and Supabase. Citizens report local issues (e.g. potholes, waste dumping, broken infrastructure), Volunteers verify them on the ground via GPS, and Admins manage resolution — all within a single role-based app.

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?logo=supabase&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)

## 🖼️ Screenshots

All app screenshots are available here: [View Screenshots](https://github.com/EcoAlert/EcoAlert---Community-Environmental-Reporting-Application/tree/main/View_App)

## ✨ Key Features

- **Three role-based experiences** — Citizen, Volunteer, and Admin, each with distinct permissions and workflows
- **Full report lifecycle** — submission → volunteer verification → admin resolution, backed by a relational Supabase/PostgreSQL schema
- **GPS-based verification** — volunteers confirm reports are legitimate using live location matching
- **Anti-spam control** — citizens are limited to 3 reports per week
- **Deep link support** — password reset flows handled via deep linking
- **Production-ready build** — resolved real-world Android build issues (SDK config, permissions, cross-drive build errors)

## 🛠️ Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Supabase (PostgreSQL, Auth, Storage)
- **Other:** GPS/location services, deep linking

## 📐 Architecture & Diagrams

This project includes full technical documentation produced for academic defence:
- ER Diagram
- Use Case Diagram
- Activity Diagram
- Class Diagram
- DFD (Levels 0, 1)

## 🚀 Getting Started

```bash
git clone https://github.com/[username]/fixalert.git
cd fixalert
flutter pub get
flutter run
```

## 📄 License

<!-- Add your license here, e.g. MIT -->
