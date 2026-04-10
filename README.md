# UniPast Workspace

This workspace contains the source code for the UniPast platform.

## 📱 [Mobile App](file:///c:/Users/16789/Downloads/UniPast%20New/README.md)
The Flutter-based mobile application for university students in Ghana.
- **Role**: Student interface (Signup, Browse, PDF Viewing, Offline access).
- **Tech**: Flutter, Riverpod, Supabase.

## 🖥 [Admin Dashboard](file:///c:/Users/16789/Downloads/UniPast%20New/unipast-admin/README.md)
The Next.js-based web application for platform administrators.
- **Role**: Backend management (Content upload, Stats, Rep management, Financials).
- **Tech**: Next.js 14, Tailwind CSS, Supabase.
- **Access**: [admin.unipast.app](https://admin.unipast.app) (Production URL)

---

## 🏗 Project Structure
```text
UniPast New/
├── unipast-admin/      # Standalone Next.js Web App
│   ├── src/
│   │   ├── app/        # UI Pages (Dashboard, Upload, etc.)
│   │   └── lib/        # Connectivity & Utils
│   └── README.md
├── lib/               # Flutter Mobile App Source
│   ├── features/
│   │   ├── auth/
│   │   ├── browse/
│   │   └── ... (No admin modules)
├── pubspec.yaml
└── .env               # Shared Supabase Config
```
