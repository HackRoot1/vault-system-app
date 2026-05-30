# Login Screen

## Changes Made

- Added the `features/login_screen/` feature using clean architecture layers.
- Implemented the login UI from the screenshot with a dark vault background, bordered glass panel, lock mark, form fields, remember-me control, login button, register CTA, and security footer.
- Integrated `POST /login` through the shared Dio `ApiClient`.
- Added Riverpod state management for form values, password visibility, remember-me, loading, success, and failure states.
- Added `/login` to named routes and made the splash fallback navigate to the login screen.
- Reworked the layout to use a naturally-sized, scrollable login card with responsive width/padding so the screen keeps the screenshot style without breaking on smaller viewports or when the keyboard opens.

## File Structure

```text
lib/
  features/
    login_screen/
      data/
        models/login_credentials.dart
        models/login_response.dart
        repositories/login_repository.dart
        services/login_service.dart
      presentation/
        providers/login_controller.dart
        providers/login_state.dart
        screens/login_screen.dart
        widgets/login_action_button.dart
        widgets/login_background.dart
        widgets/login_card.dart
        widgets/login_field.dart
        widgets/login_options_row.dart
        widgets/login_security_footer.dart
  widgets/vault_lock_icon.dart
```

## Dependencies

No new dependencies were added for this screen.

Existing dependencies used:

```yaml
dio: ^5.9.0
flutter_riverpod: ^3.0.3
```

## API Flow

Endpoint:

```bash
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "MySecure@Pass123"
  }'
```

Flow:

- `LoginScreen` watches `loginControllerProvider`.
- `LoginController.submit()` validates local form state.
- `LoginRepository.login()` receives `LoginCredentials`.
- `LoginService.login()` calls `ApiClient.post()` with `AppConstants.loginEndpoint`.
- `ApiClient` sends `POST http://localhost:8000/api/login`.
- Loading disables the button and shows a spinner.
- Success navigates to `/home`.
- Failure shows the mapped Dio/API error message in the card.

Expected response shapes supported:

```json
{ "token": "jwt", "user": { "email": "john@example.com", "name": "John" } }
```

```json
{ "data": { "access_token": "jwt", "user": { "email": "john@example.com" } } }
```

## State Management Flow

- `loginServiceProvider` builds the API service.
- `loginRepositoryProvider` builds the repository.
- `loginControllerProvider` owns `LoginState`.
- UI events update `email`, `password`, `rememberMe`, and `obscurePassword`.
- Submit moves through `idle -> loading -> success` or `idle -> loading -> failure`.

## Widget Tree Overview

```text
LoginScreen
  Scaffold
    LoginBackground
      SafeArea
        Stack
          LoginCard
            VaultLockIcon
            heading
            LoginField(email)
            LoginField(password)
            LoginOptionsRow
            LoginActionButton
            register action
          LoginSecurityFooter
```

## Running Steps

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Notes

- The app uses `AppConstants.apiBaseUrl = http://localhost:8000/api`.
- For an Android emulator, change the base URL to `http://10.0.2.2:8000/api`.
- Splash bootstrap remains disabled through `AppConstants.splashBootstrapEnabled` until a real splash/bootstrap API is available.
