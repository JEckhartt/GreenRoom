# GreenRoom

A character chat app: create characters and chat with them. Built on the Nearly codebase.

## Usage
1. Open `index.html` in your browser (or host it statically).
2. The app opens on the title screen: **Characters**, **Personas**, **Settings**.
3. In **Settings** (full-screen page):
   - **Proxy**: chat endpoint URL (OpenAI-compatible, `/chat/completions` appended automatically), API key, model
   - **Image proxy**: URL, API key, model. Only used when you explicitly ask for an image
   - **Prompt**: your system prompt, sent with every message
   - **Customization**: theme, accent color, fonts, text styling
4. **Personas**: who *you* are. Image, name, personality. Mark one as your persona and characters will know you as them.
5. **Characters**: create one with image, name, description (list only, never sent to the AI), personality, scenario, first message (or let the AI write the opening) and example dialogue. Tap a character to chat.

Each character has its own chat history. Edit a character from the chat header; restart or delete it from the editor. `{{char}}` and `{{user}}` placeholders work in the system prompt and character fields.

What the AI receives: system prompt, then the character's personality + scenario, then your active persona, then example dialogue, then the chat.

Everything is stored locally (`localStorage` for text, IndexedDB for images).

## iOS app
The `ios/` folder is a native Xcode project (Capacitor) that wraps `index.html`. Requires a Mac with Xcode.

```
npm install
npm run ios        # copies index.html into the app, syncs, opens Xcode
```
In Xcode: select the **App** target → *Signing & Capabilities* → pick your Team (a free Apple ID works for your own iPhone; apps signed that way expire after 7 days). Then pick your iPhone and press Run.

After changing `index.html`, run `npm run ios` again.

### Without a Mac (sideloading)
Every push builds an unsigned `GreenRoom.ipa` via GitHub Actions (`.github/workflows/ios.yml`).
Download it from the **latest-build** release (or the workflow run's artifacts) and install it with AltStore, SideStore or Sideloadly — they sign it with your own Apple ID.

## Your own proxy (optional)
```
OPENROUTER_API_KEY=sk-or-... node proxy.js
```
Proxy URL: `http://localhost:8787/api/v1`. Keeps your key out of the browser.
