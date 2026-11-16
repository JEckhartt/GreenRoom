# Green Room

A character chat app: create characters and chat with them. Built on the Nearly codebase.

## Usage
1. Open `index.html` in your browser (or host it statically).
2. The app opens on the title screen: **Chats**, **Characters**, **Personas**, **Albums**, **Settings**.
3. In **Settings** (full-screen page):
   - **Proxy**: save several (name, URL, API key, model) and tap one to make it active. OpenAI-compatible; `/chat/completions` is appended automatically
   - **Image proxy**: same, for images. **Generate images** off (or off per chat) makes it a normal roleplay: the character describes pictures in words. Only used when you explicitly ask for an image. With chat-style image models the character's image is sent as a style reference
   - **Generation**: presets with temperature, max reply length (the AI is also told to stay within it), top-p, top-k, min-p and repetition/frequency/presence penalties (empty = model default); show or hide the thinking of reasoning models; context size (oldest messages are left out beyond it)
   - **Prompt**: your system prompt, sent with every message, and forbidden words the AI is told never to use
   - **Backup**: export / import everything as one file
   - **Themes**: Default / Light / Dark, accent color, AI message bubble
   - **Customization**: separately for AI text and your text: font, size, weight, spacing, glow, color/gradient, and a Markdown section that gives quoted text, italic, bold, strikethrough, code, headings, list bullets, quote blocks, links and dividers each their own color (chats only). **Match user** (under Style AI text) and **Match AI** (under Style your text) copy one side's style to the other
4. **Personas**: who *you* are. Image, name, personality.
5. **Characters**: image, name, optional chat name (used in chats and for `{{char}}`), description (list only, never sent to the AI), personality, scenario, first messages (Option 1, 2, … — flip through them in a new chat until you reply; or let the AI write the opening) and example dialogue. **Import character card** (next to the image) fills everything in; before saving, the editor shows characters and exact tokens (GPT-4o tokenizer) of what is sent; **Generate** writes a whole character (and a picture) from a few words from a PNG/JSON card (SillyTavern/Chub/JanitorAI format). Tap a character for **Character profile** (collapsible sections, edit, export card, delete) or **Chat** (pick a persona, starts a new chat).
   - From Safari or Files: **Share → Green Room** (or "Open in Green Room") on a downloaded `.png`/`.json` card opens a new character with everything filled in
   - Swipe a character or persona left for **Move** (to a folder, or a new one) and **Delete**
   - Long press to select several, then move or delete them together
6. **Chats**: all chats grouped per character, with the persona each was played as. Tap a character to unfold its chats; open, delete, start a new chat, or jump to the character card. Search all chats at the top. Long press a chat to export it (text or SillyTavern `.jsonl`) or delete it.
   - While the AI writes, the send button becomes a **stop** button (what's written so far is kept)
   - Under every reply of the character: **›** writes another version, **‹ ›** flip between versions (2/3); the one showing is the one the AI remembers. Several first messages appear the same way
   - Long press a message: yours → **Edit** (then Send), **Resend**, **Copy**, **Delete**; the character's → **Rewrite with a prompt** (first message only: say what to change, the new version sits next to the old one under ‹ ›), **Create image**, **Copy**, **Delete**. Deleting removes everything after it too; resending asks the AI again from there
   - Long press the send button: **✨ Enhance my message** (AI rewrites what you typed) and **✍️ Write for me** (AI writes your message), each with its own saved prompt. The result lands in the text box with **Retry** and **Delete** (back to what you wrote)
   - The **+** above the text field: **Upload image** (the character sees it; needs a model that accepts images), **Upload file** (text, Markdown, JSON, CSV, HTML, PDF; sent with your message) and **Author's note** (a short instruction kept close to the newest messages so it keeps working in long chats)
   - **Continue** under the newest reply (or long press send → Continue the last reply): the AI carries on where it stopped
   - Swipe right-to-left in a chat: search in this chat, pinned messages and all images (tap to jump to the message; long press an image to view it or delete it from the chat)
   - Long press a message → **Pin** or **Branch from here** (a new chat that continues from that message; the original stays as it is)
   - Timestamps under messages; a background image per chat (Chat settings → Style)
   - In a chat, tap the character at the top for **Chat settings**, with tabs (tap or swipe): **Memory** (memory sent with every message; a summary prompt and **Summarize** button that writes the not-yet-summarized part of the chat into Memory; a counter of unsummarized tokens), **Style** (theme and style for this chat), **Proxy** (pick or add a proxy and image proxy for this chat, or keep Global; switch whether the character sends pictures on its own, otherwise a 📷 under such a reply makes it on tap; temperature and context size for this chat) and **Prompt** (replaces the global system prompt in this chat; extra forbidden words; **Character messages you first**: when you leave the chat the character writes a message that arrives as a notification after 30 minutes to 3 days, or at a random moment within that time; off by default)
7. **Lorebooks**: world info (places, people, rules). Each entry has keywords and is only sent when a keyword appears in the recent messages (or always, if marked). Use a lorebook everywhere, link it to a character (editor) or to a chat (Chat settings → Prompt). Lorebooks in character cards are imported and exported with the card; SillyTavern world info files can be imported and exported.
8. **Albums**: collect images. Tap one to view it (swipe between images) and copy its link (`gr://img/…`); paste it in a character's description and the image shows on the character card. Long press to select several: copy links, copy/move to another album, delete. Swipe an album left to delete it. Exported cards carry linked images along.

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
