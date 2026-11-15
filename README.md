# GreenRoom

A character chat app: create characters and chat with them. Built on the Nearly codebase.

## Usage
1. Open `index.html` in your browser (or host it statically).
2. The app opens on the title screen: **Chats**, **Characters**, **Personas**, **Settings**.
3. In **Settings** (full-screen page):
   - **Proxy**: chat endpoint URL (OpenAI-compatible, `/chat/completions` appended automatically), API key, model
   - **Image proxy**: URL, API key, model. Only used when you explicitly ask for an image
   - **Prompt**: your system prompt, sent with every message
   - **Customization**: theme, accent color, and separately for AI text and your text: font, size, weight, spacing, italic, underline, glow, color/gradient, and a color for "text between quotes"
4. **Personas**: who *you* are. Image, name, personality.
5. **Characters**: image, name, description (list only, never sent to the AI), personality, scenario, first message (or let the AI write the opening) and example dialogue. Tap a character for **Character profile** (full card, edit, delete) or **Chat** (pick a persona, starts a new chat).
6. **Chats**: all chats grouped per character, with the persona each was played as. Tap a character to unfold its chats; open, delete, or jump to the character card.

`{{char}}` and `{{user}}` placeholders work in the system prompt and character fields. A chat you leave without writing anything is discarded.

What the AI receives: system prompt, then the character's personality + scenario, then the chat's persona, then example dialogue, then the chat.

Everything is stored locally (`localStorage` for text, IndexedDB for images).

## Backups
- **Updates keep your data.** Install a new IPA over the existing app (same app ID, same Apple ID in your sideloading tool) and everything stays.
- **Automatic backup (iOS app):** every change is mirrored to the app's Library folder. If iOS ever clears the web storage, the app restores from that copy on launch. Deleting the app deletes this copy too.
- **Export / Import (Settings → Backup):** one `.json` file with characters, personas, chats, images and settings (API keys included). Save it to Files or iCloud Drive; Import restores it after a reinstall or on another phone and replaces what's in the app.

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
