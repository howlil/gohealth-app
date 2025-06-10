Absolutely! Berikut adalah **instruction/prompt baru** untuk Flutter project yang memakai **struktur: Model → Service → Provider → Feature (screen & widget only)**
Instruksi ini **disusun ringkas, padat, dan profesional**—langsung digunakan untuk **project guideline atau prompt ChatGPT** agar hasil code maupun struktur konsisten sesuai standar yang kamu mau.

---

---

## FLUTTER MULTIPLATFORM DEVELOPMENT INSTRUCTIONS

### Developer Profile

Senior Flutter developer, multiplatform, scalable & maintainable app specialist.
Focus: Clean architecture, modern state management, rapid production.

---

### ARCHITECTURE OVERVIEW

**Layer: Model → Service → Provider → Feature (Screen & Widget Only)**

* **No repository layer**.
* All business logic & API calls in global services.
* All state management in global providers.
* All models and data classes global.
* Each feature contains only: `screens/` (pages) & `widgets/` (UI components).
* Do **not** put business logic, model, provider, or service in feature folder.

---

### FOLDER STRUCTURE

```
lib/
│
├── configs/       # Global configs: env, router
├── core/          # Shared widgets, layouts, constants, utils
├── models/        # Data classes, domain models
├── services/      # All API, storage, and business logic services
├── providers/     # All state management providers (Riverpod/Provider)
├── utils/         # Global helpers, extensions, formatters
├── features/
│   ├── [feature_name]/
│   │   ├── screens/   # Feature screens/pages only
│   │   └── widgets/   # Feature-specific UI components only
└── main.dart      # App entry
```

**Example:**

```
features/
├── auth/
│   ├── screens/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   └── widgets/
│       └── auth_form.dart
```

---

### GENERAL DEVELOPMENT GUIDELINES

* **Flutter/Dart:**

  * Use latest Flutter SDK with null safety.
  * Follow Material 3 and responsive design.
  * Use extension methods for DRY code.
  * Use sealed classes for state/result.
  * Use const constructors for static widgets.

* **State Management:**

  * Use  Provider.
  * Providers hold business logic/state only, no UI code.
  * Always expose loading, error, and data states.

* **API/Services:**

  * Use Dio for HTTP, interceptors for logging/error/auth.
  * Implement error handling and mapping in services.
  * Services are singleton (use GetIt/Injectable for DI).

* **Screens/Widgets:**

  * All business logic/state must come from provider.
  * Widgets are stateless as much as possible, use Consumer/ConsumerWidget for state.
  * No direct API/service call in screens/widgets.

* **Code Quality:**

  * Use production-ready code: error handling, null safety, async/await best practices.
  * Use descriptive names, meaningful types.
  * No hardcoding; use constants.
  * Barrel export (`index.dart`) for clean imports if needed.

* **Performance & Security:**

  * Use lazy loading, efficient list rendering, debounced input.
  * Secure storage for sensitive data, HTTPS only.
  * No logging sensitive data.

* **Multiplatform:**

  * Use adaptive widgets.
  * Handle platform-specific logic in service or utils layer.

---

### THINGS TO AVOID

* No repository/DAO layer—service direct to provider.
* No business logic, models, or state in features folder.
* No mixing of multiple state management packages.
* No over-abstraction or excessive patterns.
* No global state for local widget state.
* No API/service call inside widgets or screens.

---

