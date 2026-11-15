# GreenRoom

A character chat app: create characters and chat with them. Built on the Nearly codebase.

## Usage
1. Open `index.html` in your browser (or host it statically).
2. The app opens on the title screen: **Chats**, **Characters**, **Personas**, **Albums**, **Settings**.
3. In **Settings** (full-screen page):
   - **Proxy**: chat endpoint URL (OpenAI-compatible, `/chat/completions` appended automatically), API key, model
   - **Image proxy**: URL, API key, model. Only used when you explicitly ask for an image. With chat-style image models the character's image is sent as a style reference
   - **Prompt**: your system prompt, sent with every message
   - **Backup**: export / import everything as one file
   - **Themes**: Default / Light / Dark, accent color, AI message bubble
   - **Customization**: separately for AI text and your text: font, size, weight, spacing, glow, color/gradient, and a color for "text between quotes". One tap copies one side's style to the other
4. **Personas**: who *you* are. Image, name, personality.
5. **Characters**: image, name, optional chat name (used in chats and for `{{char}}`), description (list only, never sent to the AI), personality, scenario, first messages (Option 1, 2, … — flip through them in a new chat until you reply; or let the AI write the opening) and example dialogue. **Import character card** (next to the image) fills everything in from a PNG/JSON card (SillyTavern/Chub/JanitorAI format). Tap a character for **Character profile** (collapsible sections, edit, export card, delete) or **Chat** (pick a persona, starts a new chat).
   - From Safari or Files: **Share → GreenRoom** (or "Open in GreenRoom") on a downloaded `.png`/`.json` card opens a new character with everything filled in
   - Swipe a character or persona left for **Move** (to a folder, or a new one) and **Delete**
   - Long press to select several, then move or delete them together
6. **Chats**: all chats grouped per character, with the persona each was played as. Tap a character to unfold its chats; open, delete, start a new chat, or jump to the character card. Long press a chat to export it (text or SillyTavern `.jsonl`) or delete it.
   - Under every reply of the character: **›** writes another version, **‹ ›** flip between versions (2/3); the one showing is the one the AI remembers. Several first messages appear the same way
   - Long press a message: yours → **Edit** (then Send), **Resend**, **Copy**, **Delete**; the character's → **Copy**, **Delete**. Deleting removes everything after it too; resending asks the AI again from there
   - Long press the send button: **✨ Enhance my message** (AI rewrites what you typed) and **✍️ Write for me** (AI writes your message), each with its own saved prompt. The result lands in the text box with **Retry** and **Delete** (back to what you wrote)
   - Add one image to a message with the image button next to the text field; the character sees it (needs a model that accepts images)
   - Swipe right-to-left in a chat: **Character card**, **Edit character**, and all images in the chat
   - In a chat, tap the character at the top for **Chat settings**, with tabs (tap or swipe): **Memory & style** (memory sent with every message, theme and style for this chat), **Proxy** (URL / key / model for this chat; empty fields use the global ones) and **Prompt** (replaces the global system prompt in this chat)
7. **Albums**: collect images. Tap one to view it (swipe between images) and copy its link (`gr://img/…`); paste it in a character's description and the image shows on the character card. Long press to select several: copy links, copy/move to another album, delete. Swipe an album left to delete it. Exported cards carry linked images along.

Markdown works in chats and on character cards (bold, italic, lists, quotes, headings, code, links). Swipe from the left edge to go back.

`{{char}}` and `{{user}}` placeholders work in the system prompt and character fields. A chat you leave without writing anything is discarded.

What the AI receives: system prompt, then the character's personality + scenario, then the chat's persona, then the chat's memory, then example dialogue, then the chat.

Everything is stored locally (`localStorage` for text, IndexedDB for images).

## Backups
- **Updates keep your data.** Install a new IPA over the existing app (same app ID, same Apple ID in your sideloading tool) and everything stays.
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
