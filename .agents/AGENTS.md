# Backend Development Rules

When writing or modifying backend code for this project, you MUST strictly adhere to the following rules:

- **Clean Architecture**: Always follow Clean Architecture principles to ensure the codebase remains maintainable and scalable.
- **Short & Clean Code**: Write concise, readable, and modular code. Avoid large, monolithic functions or files. Each function should have a single, clear responsibility.
- **Strict Layered Structure**: Organize all server-side logic into the following distinct layers:
  - **Routes**: Define HTTP or WebSocket endpoints. Keep these files extremely thin. They should only map endpoints to the appropriate controllers.
  - **Controllers**: Handle request extraction, basic validation, and HTTP responses. Controllers must NOT contain complex business logic; they must delegate work to services.
  - **Services**: This is where the core business logic lives. All complex data processing, algorithms, and orchestration between different models or external APIs should be done here.
  - **Models**: Define data schemas, database interaction logic, and data structures.
- **General Best Practices**: Use descriptive variable/function names, implement proper and consistent error handling, and add comments only where the logic is inherently complex.
- **User-Friendly Error Handling & Validation**: Every error and validation failure MUST return a clear, relevant, and easy-to-understand message so the end-user (or frontend developer) knows exactly what went wrong.

# Frontend (Flutter) Development Rules

When writing or modifying Flutter code for this project, you MUST strictly adhere to the following rules:

- **Architecture**: Always follow Clean Architecture principles. Use `get_cli` to generate and manage folders/files structurally (Service, Controller, Model, Screen).
- **Core Packages**: Use the following packages strictly:
  - `dio` for network requests.
  - `hive` for local database/storage.
  - `get` (GetX) for state management and dependency injection.
  - `go_router` for routing/navigation (do not use GetX for routing).
  - `flutter_screenutil` for responsive UI sizing.
- **File Size & Widgets**: 
  - A single screen/UI file MUST NOT exceed 120 lines of code. 
  - If a file exceeds this limit, extract the UI components into smaller widgets and place them in a `widgets` folder within the same feature/screen directory.
- **Performance Optimization**: 
  - Strictly use `const` and `final` keywords wherever possible.
  - Ensure proper usage of `ListView.builder` (and similar lazy-loading widgets) instead of rendering massive scrollable columns or standard ListViews.
- **Common & Reusable Structure**: Always maintain and use the following central configuration files:
  - `custom_assets.dart`: Manage and declare all image/asset paths here.
  - `api_url.dart`: Centralize all API endpoints and base URLs.
  - `app_theme.dart`: Define the global app theme, colors, text styles.
  - `custom_button.dart`: Create a reusable, highly customizable button widget.
  - `custom_text_field.dart`: Create a reusable text field widget that encapsulates all types of validation logic and validator functions.
