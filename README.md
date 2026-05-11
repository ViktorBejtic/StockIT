# StockIT

Native iOS application for inventory management, developed as part of a 
multi-platform system for cataloguing the historical computer collection 
at FIIT STU Bratislava. Built with Swift, SwiftUI and the MVVM architectural 
pattern with a dedicated service layer for REST API communication.

## Key features

- **Dual-mode item creation** — five-step wizard for new users and a 
  single-screen quick form for experienced users, switchable in settings
- **AI photo recognition** — Gemini 2.5 Flash Lite (via Google Generative 
  AI SDK) suggests item name, description and categories from a photograph
- **Reference images** — visual verification of AI suggestions via SerpAPI
- **Contextual navigation** — automatic pre-filling of organization and 
  location based on the user's position in the hierarchy
- **Offline write support** — failed item-creation requests are persisted 
  locally and auto-synchronised once connectivity returns (OfflineSyncManager)
- **QR code scanning** for rapid item lookup
- **Six-level role-based access** with conditional UI rendering
- **Bilingual interface** (Slovak / English) with full dark mode support
- **Secure credential storage** in iOS Keychain

## Tech stack

Swift, SwiftUI, MVVM with service layer, Alamofire, Kingfisher, 
Google Generative AI SDK, KeychainAccess, Swift Package Manager.

## Requirements

iOS 18.2 or later, Xcode 16.3 or later.

## Author

Viktor Bejtic — Bachelor thesis at the Faculty of Informatics and 
Information Technologies, Slovak University of Technology in Bratislava (2026).
