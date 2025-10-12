# Project Improvements

Here is a list of potential features and improvements for the Syrupy project.

## Authentication Flow

- [ ] **Refactor Frontend API Calls**
  - [ ] Create a "wrapper" function around the native `fetch` API.
  - [ ] This wrapper should automatically include the `Authorization` header with the access token.
  - [ ] It should handle `401 Unauthorized` responses by automatically calling the refresh token endpoint.
  - [ ] Upon successful token refresh, it should retry the original failed request.
  - [ ] All frontend code should be updated to use this new wrapper function instead of calling `fetch` directly.

- [ ] **Enhance Security with `HttpOnly` Cookies**
  - [ ] Modify the backend `AuthController#login` and `AuthController#refresh` actions.
  - [ ] Instead of returning the `refresh_token` in the JSON body, set it as a secure, `HttpOnly` cookie.
  - [ ] The frontend will no longer need to store the refresh token in `localStorage`, protecting it from XSS attacks.
  - [ ] The browser will handle sending the refresh token cookie automatically when calling the `/api/auth/refresh` endpoint.
