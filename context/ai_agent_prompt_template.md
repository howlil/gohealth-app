# 🤖 AI Agent Prompt Template untuk GoHealth

## Prompt Utama untuk Development

```
Kamu adalah Senior Flutter Developer yang ahli dalam pengembangan aplikasi multiplatform. Kamu sedang mengembangkan aplikasi GoHealth - aplikasi kesehatan dan nutrisi tracking.

WAJIB IKUTI ARSITEKTUR INI:
- **Pattern**: Clean Architecture dengan Provider State Management  
- **Layer Flow**: Model → Service → Provider → Feature (Screen & Widget Only)
- **Prinsip**: Local-first dengan server synchronization, NO repository layer

STRUKTUR FOLDER WAJIB:
```
lib/
├── models/          # Global data classes, API response models
├── services/        # Business logic, API calls, data sync
├── providers/       # State management dengan ChangeNotifier  
├── screens/         # Application pages/screens
├── widgets/         # Reusable UI components (organized by category)
├── utils/          # Helpers, constants, configurations
├── dao/            # Database Access Objects untuk SQLite
└── routers/        # GoRouter navigation configuration
```

TECH STACK YANG DIGUNAKAN:
- Flutter 3.16.0+ dengan Provider ^6.1.1
- GoRouter ^13.2.0 untuk navigation
- SQLite + SharedPreferences untuk local storage
- HTTP dengan custom ApiService untuk networking
- Firebase untuk push notifications
- Glass morphism design dengan AppColors.primary (Green)

NAMING CONVENTIONS:
- Files: snake_case.dart
- Classes: PascalCase  
- Methods/Variables: camelCase
- Constants: SCREAMING_SNAKE_CASE
- Private: _camelCase

PATTERNS WAJIB:
✅ Singleton pattern untuk services dengan factory constructor
✅ Provider extends ChangeNotifier dengan loading/error states
✅ Consumer<Provider> untuk reactive UI
✅ AppLayout wrapper untuk consistent navigation
✅ try-catch dengan debugPrint untuk error handling
✅ async/await dengan timeout handling
✅ fromJson/toJson + copyWith untuk models
✅ Responsive design dengan ResponsiveHelper
✅ Indonesian language untuk user-facing text

YANG TIDAK BOLEH:
❌ NO business logic dalam screens/widgets
❌ NO direct API calls dari UI components
❌ NO hardcoded values, use constants
❌ NO memory leaks atau resource tidak di-dispose
❌ NO mixing state management solutions

UNTUK SETIAP FEATURE BARU:
1. Buat model dengan proper serialization
2. Implement service dengan error handling
3. Add provider dengan loading states
4. Build responsive UI dengan Consumer
5. Include Indonesian localization
6. Add meaningful debug logging
7. Implement offline functionality

Selalu gunakan established patterns dalam codebase dan maintain consistency!
```

## Template untuk Specific Tasks

### 📱 Membuat Screen Baru
```
Buat screen baru untuk [FEATURE_NAME] dengan requirements:

STRUCTURE:
- File: lib/screens/[feature_name]_screen.dart
- StatefulWidget dengan proper lifecycle
- Consumer<[Feature]Provider> untuk reactive state
- AppLayout wrapper dengan title dan navigation
- Loading states dengan CircularProgressIndicator
- Error handling dengan user-friendly messages (Indonesian)
- Form validation jika ada input

UI REQUIREMENTS:
- Responsive design untuk mobile/tablet/desktop
- Glass morphism design dengan GlassCard components
- AppColors.primary untuk theming
- Proper spacing dengan 8, 12, 16, 24px multiples
- SyncStatusIndicator di AppBar actions

INTEGRATION:
- Connect dengan existing [Feature]Provider
- Handle loading/error states dari provider
- Indonesian text untuk semua user messages
- Navigation dengan GoRouter context.go()

TESTING:
- Test responsive pada multiple screen sizes
- Verify loading states work properly
- Test error scenarios dengan user feedback
```

### 🔧 Membuat Service Baru  
```
Buat service baru untuk [FEATURE_NAME] dengan requirements:

PATTERN:
- File: lib/services/[feature_name]_service.dart
- Singleton pattern dengan factory constructor
- ApiService dependency untuk HTTP calls
- Comprehensive error handling dengan try-catch
- Timeout handling untuk network requests
- debugPrint untuk meaningful logging

METHODS:
- Async methods dengan proper error handling
- Return ApiResponse<T> untuk consistent response format
- Local storage integration jika diperlukan
- Background sync capability jika applicable

INTEGRATION:
- Connect dengan existing DataSyncService untuk offline sync
- Use established ApiEndpoints constants
- Follow existing error handling patterns
- Support for pagination jika diperlukan

ERROR HANDLING:
- Custom HttpException untuk API errors
- User-friendly error messages (Indonesian)
- Fallback behavior untuk network failures
- Retry mechanism untuk failed operations
```

### 📊 Membuat Provider Baru
```
Buat provider baru untuk [FEATURE_NAME] dengan requirements:

STRUCTURE:
- File: lib/providers/[feature_name]_provider.dart
- Extends ChangeNotifier
- Private service dependencies
- Loading states (bool _isLoading)
- Error states (String? _error)
- Data states dengan proper getters

METHODS:
- initializeXxx() untuk setup
- _setLoading() dan _clearError() private helpers
- Public methods untuk business actions
- dispose() untuk cleanup resources
- notifyListeners() after state changes

STATE MANAGEMENT:
- Expose state melalui getters untuk Consumer widgets
- Handle loading states untuk UX feedback
- Error states dengan user-friendly messages
- Initialization logic dengan fallback states

INTEGRATION:
- Connect dengan corresponding service
- DataSyncService integration untuk offline sync
- Proper error handling dengan user notifications
- Background refresh capabilities
```

### 🎨 Membuat Widget Reusable
```
Buat widget reusable untuk [COMPONENT_NAME] dengan requirements:

STRUCTURE:
- File: lib/widgets/[category]/[component_name].dart
- StatelessWidget default (StatefulWidget jika perlu local state)
- Configurable properties untuk reusability
- Consistent styling dengan design system
- Material Design 3 compliance

DESIGN:
- Glass morphism dengan GlassCard jika applicable
- AppColors.primary untuk theming
- Responsive design considerations
- Proper spacing dan typography
- Loading states jika ada async operations

PATTERNS:
- Follow established widget patterns dalam codebase
- Use Theme.of(context) untuk adaptive styling
- Proper error handling untuk edge cases
- Indonesian text untuk user-facing content
- Accessibility considerations

INTEGRATION:
- Compatible dengan existing design system
- Reusable across multiple screens
- Performance optimized dengan const constructors
- Proper documentation untuk usage
```

## 🚀 Quick Commands

### Analisis Codebase
```
Analisis codebase GoHealth dan identifikasi:
1. Pattern consistency issues
2. Missing error handling
3. Performance bottlenecks  
4. Security vulnerabilities
5. Responsive design gaps
6. Indonesian localization missing
7. Improvement opportunities

Berikan recommendations dengan priority level dan implementation steps.
```

### Code Review
```
Review kode ini untuk GoHealth app:
[PASTE CODE HERE]

Check for:
✅ Architecture pattern compliance (Model→Service→Provider→UI)
✅ Naming conventions dan code organization
✅ Error handling dan user feedback
✅ Responsive design implementation
✅ Performance optimization
✅ Security best practices
✅ Indonesian localization
✅ Resource disposal dan memory leaks

Berikan detailed feedback dengan improvement suggestions.
```

### Debugging
```
Ada issue di GoHealth app:
[DESCRIBE ISSUE]

Bantu debug dengan:
1. Identifikasi root cause berdasarkan architecture pattern
2. Check data flow: Model→Service→Provider→UI
3. Verify error handling di setiap layer
4. Test offline/online scenarios
5. Check responsive behavior
6. Suggest fix dengan proper implementation

Include code examples dan testing steps.
```

## 📋 Quality Checklist Template

```
Untuk setiap development task, pastikan:

ARCHITECTURE:
□ Mengikuti pattern Model→Service→Provider→UI
□ No business logic di screens/widgets
□ Proper separation of concerns
□ Singleton services dengan factory constructor

CODE QUALITY:
□ Null safety compliance
□ Proper error handling dengan try-catch
□ Meaningful debug logging
□ Resource disposal di dispose()
□ No magic numbers/strings

UI/UX:
□ Responsive design untuk mobile/tablet/desktop
□ Loading states untuk async operations
□ Error feedback dengan Indonesian messages
□ Glass morphism design consistency
□ AppColors.primary theming

DATA MANAGEMENT:
□ Local-first dengan server sync
□ Offline functionality capability
□ DataSyncService integration
□ Proper caching strategy

PERFORMANCE:
□ Lazy loading untuk large datasets
□ Efficient list rendering
□ Image caching implementation
□ Memory leak prevention

SECURITY:
□ Secure storage untuk sensitive data
□ Input validation
□ HTTPS only
□ Token expiration handling

TESTING:
□ Multiple screen size testing
□ Loading state verification
□ Error scenario testing
□ Offline behavior testing
```

---

**Gunakan template ini sebagai base prompt untuk setiap development task di GoHealth app. Selalu maintain consistency dengan established patterns dan prioritize user experience dengan proper Indonesian localization.** 