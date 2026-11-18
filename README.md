# JARVIS AI Assistant — Step 1 (Core UI)

This is Step 1 of your JARVIS AI Assistant Android app, built with Flutter.

## What works right now (tested logic, not just claims)
- Iron Man style dark blue holographic theme
- Animated JARVIS orb (pure Flutter `CustomPainter`, no external packages,
  so it cannot fail to compile due to a missing dependency)
- Home screen → Chat screen navigation
- Typing and sending messages, with a placeholder JARVIS reply
- English / Marathi language toggle (UI state only)
- Microphone button UI that visually activates, and is honest that real
  voice recognition is not wired up yet

## What is NOT implemented yet (on purpose)
- Real speech-to-text / text-to-speech → **Step 2**
- Real Claude AI responses → **Step 3**
- Saved chat history across app restarts → **Step 4**
- Device automation permissions/actions → later step
- Windows .exe build → later step (same codebase, different `flutter build` target)

No feature above is faked in the code — the mic button and chat replies
say plainly in-app that they're placeholders.

---

## How to turn this into an installable APK (from your phone)

You don't need a computer. Follow these steps on your phone:

### 1. Create a GitHub repository
1. Install the **GitHub** app (or use github.com in your browser).
2. Create a new repository, e.g. `jarvis-assistant`.
3. Upload **all the files from this ZIP**, keeping the folder structure
   exactly as it is (the `lib/`, `android/` folders etc. must stay intact).

### 2. Connect Codemagic
1. Go to [codemagic.io](https://codemagic.io) and sign up (free tier is enough).
2. Click "Add application" → connect your GitHub account → select your
   `jarvis-assistant` repo.
3. Codemagic will detect the `codemagic.yaml` file already included in
   this project and set up the build workflow automatically.

### 3. Start the build
1. Press **Start new build** → choose workflow `jarvis-android-build`.
2. Wait a few minutes. Codemagic runs `flutter pub get` and
   `flutter build apk --debug` in the cloud.
3. When it finishes, download the `.apk` file directly from the
   Codemagic build page on your phone.

### 4. Install on your Android phone
1. Open the downloaded `.apk` file.
2. Allow "install unknown apps" for your browser/file manager if asked.
3. Install and open — you'll see the JARVIS orb and can enter the chat.

---

## Project structure
```
lib/
  main.dart                 # App entry point
  theme/app_theme.dart      # Colors & theme
  models/chat_message.dart  # Chat message data model
  widgets/jarvis_orb.dart   # Animated holographic orb
  widgets/chat_bubble.dart  # Chat message bubble UI
  screens/home_screen.dart  # Landing screen with orb
  screens/chat_screen.dart  # Chat interface
  services/voice_service.dart   # Stub for Step 2
  services/claude_service.dart  # Stub for Step 3
android/                    # Native Android project files
codemagic.yaml              # Cloud build configuration
```

## Security note on API keys
No API key exists anywhere in this project yet. When Claude AI is added
in Step 3, the key will be stored as a **secure environment variable**
inside Codemagic's dashboard (encrypted, never committed to GitHub, never
hardcoded into Dart files).

## Next step
Once you've confirmed this APK installs and the chat screen works on
your phone, tell me and we'll move to **Step 2: real voice recognition
and text-to-speech for English and Marathi**.
