# Splash Screen

## Changes Made

- Replaced the starter counter app with a production app shell using `ProviderScope`, named routes, and the app theme.
- Added a feature-first `features/splash_screen/` module with data, repository, state, screen, and reusable widget layers.
- Added a Dio-backed API client with centralized response handling, network errors, server errors, token expiration detection, and typed responses.
- Implemented the screenshot UI with a custom painted dark vault background, lock mark, centered brand typography, bottom progress rail, and status row.
- Refined the full-bleed viewport layout, brand anchors, typography scale, and footer position to better match the supplied screenshot proportions.
- Added fallback initialization because the provided API details are still `[ADD API DETAILS HERE]`.

## File Structure

```text
lib/
  core/
    constants/app_constants.dart
    network/api_client.dart
    network/api_exception.dart
    network/api_response.dart
    network/auth_token_store.dart
    state/app_providers.dart
  features/
    splash_screen/
      data/
        models/splash_bootstrap.dart
        repositories/splash_repository.dart
        services/splash_service.dart
      presentation/
        providers/splash_controller.dart
        screens/splash_screen.dart
        widgets/splash_background.dart
        widgets/splash_brand_mark.dart
        widgets/splash_status_footer.dart
  routes/app_routes.dart
  theme/app_colors.dart
  theme/app_theme.dart
  widgets/vault_home_placeholder.dart
```

## Dependencies

Added to `pubspec.yaml`:

```yaml
dio: ^5.9.0
flutter_riverpod: ^3.0.3
```

## API Flow

- `SplashController` starts initialization through Riverpod.
- `SplashRepository` enforces the minimum splash duration and asks `SplashService` for bootstrap data only when `AppConstants.splashBootstrapEnabled` is true.
- `SplashService` calls `GET /splash/bootstrap` through `ApiClient`.
- `ApiClient` injects bearer tokens, maps Dio failures into `ApiException`, and returns `ApiResponse<T>`.
- Until real splash API details are supplied, `splashBootstrapEnabled` is false and the repository uses a local bootstrap result that navigates to `/login`.

Expected bootstrap response:

```json
{
  "nextRoute": "/home",
  "statusMessage": "Decrypting local vault...",
  "requiresSessionRefresh": false
}
```

## State Management Flow

- Provider: `apiClientProvider`
- Provider: `splashServiceProvider`
- Provider: `splashRepositoryProvider`
- AsyncNotifier: `splashControllerProvider`
- UI watches `AsyncValue<SplashBootstrap>` for loading, success, and error states.
- On success, `SplashScreen` navigates with `pushReplacementNamed`.
- On error, the footer becomes retryable.

## Widget Tree Overview

```text
SplashScreen
  Scaffold
    SplashBackground
      SafeArea
        Stack
          SplashBrandMark
            _VaultLockIcon
            title text
            tagline text
          SplashStatusFooter
            LinearProgressIndicator
            _StatusLine
```

## Running Steps

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Notes

- Configure the production API host in `AppConstants.apiBaseUrl`.
- Enable `AppConstants.splashBootstrapEnabled` only after the splash bootstrap endpoint exists.
- Replace `AppConstants.splashBootstrapEndpoint` if the backend uses a different bootstrap endpoint.
- The current `/home` route is a small placeholder so splash navigation has a valid target.
