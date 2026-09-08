# Secrets Configuration

This folder is used for local secrets and API keys.
Files matching `secrets/*` (such as `secrets/api_keys.json`) are strictly ignored by `.gitignore` and must **never** be committed to version control.

### Setup Gemini API Key

1. Copy the example file:
   ```bash
   cp secrets/api_keys.json.example secrets/api_keys.json
   ```
2. Add your Gemini API key in `secrets/api_keys.json`:
   ```json
   {
     "GEMINI_API_KEY": "your_api_key_here"
   }
   ```
3. Run or build the app with `--dart-define-from-file`:
   ```bash
   flutter run --dart-define-from-file=secrets/api_keys.json
   flutter build apk --dart-define-from-file=secrets/api_keys.json
   ```

### In-App Configuration
Users can also configure or change their Gemini API key directly within the app at runtime via:
- **Chat Header**: Tap the AI status badge (Offline AI / Gemini Active)
- **Profile Screen**: Tap **Configure Gemini API Key** under AI Intelligence Settings
- The key is securely saved to local storage (`SharedPreferences`) on the device or browser.
