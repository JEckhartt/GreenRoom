# Green Room

A character chat app: create characters and personas and chat with them. Built on the Nearly codebase. Everything is stored on the device (`localStorage` for text, IndexedDB for messages and images).

On start, iOS shows a plain launch screen (black with the logo in dark mode, cream in light mode), then the app shows the logo in your theme's colours and fades into the title screen. Fonts, the token counter and the PDF reader are inside the app; the internet is only used for your proxies, image proxies, Chub and JanitorAI.

The title screen has **Chats**, **Characters**, **Personas**, **Lorebooks**, **Albums** and **Settings**. Swipe from the left edge to go back.

## Chats

- All chats, grouped per character, with the persona each was played as. Tap a character to unfold its chats (one character open at a time); open one, delete it, start a new chat or jump to the character card. Search all chats at the top.
- The button next to **+** switches between a list and a compact list.
- Long press a chat to **Move to another character**, **Change persona**, **Move to folder** (folders sit at the top of Chats; the chat also stays under its character; ⋯ on a folder renames or deletes it), **Rename** it (the name shows in the list), **Export** it (Text, Markdown, Web page, Rich text, JSON, JSON Lines or Spreadsheet) or delete it. **+** at the top right: start a new chat, or **Import chat** (pick the character and persona, then a SillyTavern `.jsonl`, a Green Room text export or a JSON file).
- A new chat starts with the chat settings of the chat you used last (proxy, preset, prompt, style, image settings, real time…; not its memory, author's note or lorebooks). For characters whose opening the AI writes, Settings → New chats → **Wait before the AI writes the opening** shows a **Start** button first, so you can change Chat settings.
- A new chat is kept as soon as it has its first message; one you leave without writing anything is discarded.

### In a chat

- A chat opens at its newest message.
- While the AI writes, the send button becomes a **stop** button (what's written so far is kept). Enter makes a new line; send with the send button.
- The screen follows a reply while it's written until you scroll yourself; then it stays where you put it (the ↓ button jumps back down). An error note disappears when you try again or pick another proxy.
- Under the character's replies: **›** writes another version, **‹ ›** flip between versions; the one showing is the one the AI remembers. Several first messages appear the same way. **Continue** under the newest reply carries on where it stopped.
- Long press a message:
  - yours: **Edit** (then Send), **Resend**, **Copy**, **Pin**, **Branch from here**, **Delete**
  - the character's: **Edit** (saved in place), **Rewrite with a prompt** (first message only), **Create image**, **Copy**, **Pin**, **Branch from here**, **Delete**
  - Deleting removes everything after it; resending asks the AI again from there. Branch makes a new chat that continues from that message.
- Long press the send button: **Enhance my message** (the AI rewrites what you typed) and **Write for me** (the AI writes your message), each with its own saved prompt. The result lands in the text box with **Retry** and **Delete**.
- The **+** above the text field: **Upload image** and **From album** (the character sees it; needs a chat model that accepts images), **Generate image** (a picture you send), **Upload file** (text, Markdown, JSON, CSV, HTML, PDF) and **Author's note** (a short instruction kept close to the newest messages).
- Swipe right-to-left: search in this chat, pinned messages and all images.
- Tap the character at the top for **Chat settings** (see below).

### Images

With **Enable** on (Settings → Image proxy, or per chat):

1. Ask for a picture in your own words ("send me a selfie", "I want a pic of you", "selfie of us?", "\*asks for a photo\*"), or the character offers one ("\*snaps a selfie and sends it\*"). English and Dutch are recognised.
2. The character replies and describes the picture; if it doesn't, the chat proxy writes the description.
3. The image proxy makes it. **Make images automatically** off: a camera button appears under the reply instead, and the image is made when you tap it.

Long press an image to delete or regenerate it. **Create image** (long press a reply) illustrates that moment as a scene seen from outside, not as a photo the character sends. **+ → Generate image** makes a picture you send (typed, or matching what you wrote).

What the image proxy gets: the character's and your profile pictures (each "only include them if the description has them in it", "don't copy the pose or background"), the character's last picture (for a consistent outfit and setting), your **Image prompt**, the description, and both personality texts. Where someone has a profile picture, the picture decides how they look and their text only adds what it doesn't show.

With **Enable** off it's a regular chat: no images are made or sent to the AI (earlier ones are mentioned as "an image was attached"), and the image buttons are hidden.

## Stories

**Stories** on the title screen turns a chat into a novel. **New story**:
- **Chat** (pick the character, then the chat) and the **proxy** that writes it.
- **Divide into chapters** (on): for longer chats, one chapter per ~14,000 characters of chat, cut at natural breaks (a long pause between messages). Shorter chats become one story.
- **Point of view**: first person or third person limited, through the character's or the persona's eyes, or omniscient.
- **Title** (empty: the AI picks one), **Generate a cover** (style only; the rest comes from the story, with the profile pictures as reference; 2:3), **Publish as** Text, PDF and/or EPUB when it's done.

The chat is written part by part; each part gets both people's texts, the point of view, a running summary of the story so far (10–15 sentences, with names of side characters, places and objects) and the last paragraphs of the previous part, so it continues seamlessly. It's saved after every part. While it writes, the screen stays on; tap the story to unfold a panel with a progress bar, what it's doing (which chapter, how many characters so far, about how long is left) and **Stop**. Cut off by leaving the app or closing it, it continues by itself when you come back; after Stop or an error, the panel has **Continue writing** and **Read what is written**. Stories show as covers in a grid; long press one to publish/export, rename, make a new cover or delete it.

The reader: pages (tap the left or right edge or swipe; tap the middle to hide the bars) or scrolling, **Contents**, and **Aa** for size, font, page colour (paper, sepia, night, or the app's theme) and spacing. It remembers where you were. PDF (A5 pages, made by iOS) works in the iPhone app; EPUB opens in Apple Books.

## Characters and personas

- **Characters**: image, name, optional chat name (used in chats and for `{{char}}`), description (shown in the list, never sent to the AI; written in a formatting editor: paragraph / headings / quote, bold, italic, underline, strikethrough, highlight and text colour, alignment, list, divider, pictures from your albums, links (a link to a picture shows the picture), and </> to see or edit the HTML; imported HTML bios keep their formatting), personality, scenario, first messages (several options to flip through until you reply, or let the AI write the opening, which follows your selected system prompt; **Generate** writes its openings in third person limited, from the character's point of view) and example dialogue. The editor shows characters and tokens of what is sent.
- **Import** → *Character card (file)* (PNG/JSON) or *From Chub link* fills everything in; from Safari or Files, **Share → Green Room** does the same. **Generate** writes a whole character, with a picture, from a few words, asking first which style the picture should be (remembered), keeping personality, scenario and example dialogue at about 1,000–2,000 tokens, following the **Template** on that page (field headings plus [instructions]; editable, with Reset to default). **+** at the top right: create new or generate.
- The picture: tap it to choose one from your phone or **From album**. **Generate image** in the editor also asks for the style first. Profile pictures are asked for in a tall 2:3 shape (head to waist, centred), both in the prompt and as the image model's aspect-ratio setting (OpenRouter `image_config`).
- **Frame picture** (opens after you pick a picture, and from the editor any time): drag, pinch or slide to choose what shows, with live previews of the chat header, messages, chats list, characters list and profile. Tap a preview to frame just that spot (its own shape: circle, or tall for the lists); the others follow the main framing. The profile shows the whole picture, in its own shape. Works for characters and personas.
- Tap a character to unfold its **Profile** and **+ Start new chat**. The button next to + switches Characters between a list, a compact list and a grid, and Personas and Albums between a list and a grid (picture, name, bio); in the grid, tapping a character opens the profile and tapping the text unfolds the whole description with a **Chat** button under it. In the profile, ⋯ at the top has Edit, Export card and Delete. The profile opens with the description unfolded and the rest folded. Starting a chat: persona folders come first (tap one to unfold the personas in it); tapping a persona shows its description, with **Start chat as …**. The eye on a picture blurs it everywhere except in a chat and the editor.
- **Personas**: who *you* are: image, name, personality.
- Swipe a character or persona left for **Move** (to a folder) and **Delete**; long press to select several.

## Lorebooks and albums

- **Lorebooks**: world info. Each entry has keywords and is only sent when one appears in the recent messages (or always, if marked). Use one everywhere, link it to a character or to a chat. Imported and exported with character cards; SillyTavern world info files work too.
- **Albums**: collect images, last added first. While selecting, slide your finger sideways over the pictures (or long press and keep moving) to select a whole run, like Photos; near the top or bottom the page scrolls along. In the viewer, swipe or flick for the next picture; zoomed in, pan freely (it glides) and pull past the edge to go to the next one. Copy an image's link (`gr://img/…`) into a character's description to show it on the card. Long press to select several: copy links, copy or move, delete.

## Connect to JanitorAI

iPhone app only. **Settings → JanitorAI → Connect to JanitorAI** opens a page with:

- **Import chats**, with options: *Create characters I don't have yet*, *Create personas I don't have yet* (off: those go to "Don't import" / "No persona" until you pick one) and *Skip chats I already imported* (off: they're updated with new messages) and *Use JanitorAI's descriptions for characters I have* (switches on Replace mine for every matched character, also ones without new chats). **Import** opens JanitorAI and starts by itself; if you're not logged in, log in and it continues (or tap **Continue**). The progress shows at the top; when it's done the window closes and **Import from JanitorAI** opens:
  - Each character and persona with where it goes: an existing one with the same name (taglines like "Name - Detective (MalePOV)" are ignored), a new one made from JanitorAI (picture, description, personality, scenario, first messages, example dialogue), or not imported.
  - Tap a character to review it: where it goes, everything JanitorAI has for it (characters whose creator hid the definition are marked "definition hidden"; their personality, scenario and example dialogue can't be imported), and its chats, each with a switch; tap a chat to read it exactly as it will be imported. For a character you already have, JanitorAI's description shows with yours below it, and **Replace mine** swaps yours for JanitorAI's (nothing else changes); when they're already the same it says *Same as yours* and is left alone. Tap a persona to see its picture and personality.
  - **Import**: replies you swiped through become versions (‹ ›); a chat's JanitorAI memory goes to its Memory; chats imported before are updated, not doubled.
- **Missing definitions → Find on JannyAI**: looks only at your characters (quick) and lists those whose definition is hidden on JanitorAI, with *Only ones I'm missing* (no personality in Green Room yet) on or off. Each has its picture and its JannyAI link (the JanitorAI link with janitorai.com changed to jannyai.com); tap to open it, or **Copy list**.
- **Custom prompts → Import custom prompts**: JanitorAI opens; go to a chat → Using proxy → edit a proxy → Custom prompt and open the list, then tap **Done**. The prompts the page loaded are listed with a switch each (ones you already have are off; tap one to read it), and **Add** puts them in Settings → Prompt. If none are found, **Save inspection file** saves what the page loaded (tokens and e-mail addresses removed) to send for a fix.
- **Open JanitorAI** (just the site) and **Log out of JanitorAI** (removes its saved login from the app).

Nothing you browse is recorded (except, while importing custom prompts, what the site loads, kept in memory until you tap Done); the window only notes the site's login headers in memory, so the import is logged in the same way.

## Settings

- **Proxy**: a list of proxies (name, URL, API key, model), like the prompts: tap one to use it and open its settings, tap it again to fold it. OpenAI-compatible; `/chat/completions` is added automatically. Long press a proxy to duplicate it. **Import** adds the proxies from JanitorAI's proxy export (**Paste from clipboard**, as JanitorAI copies it, or **Choose a file**) (name, address, model; its prompts are left out) and asks which API key they get: the one from JanitorAI, or one you already use in Green Room for the same service. Proxies you already have are skipped. **Test connection** checks that it answers; **Test images** asks it the colour of a red square, so you know whether it can see images (it only reports). In the iPhone app, requests go out from iOS itself (not from the app's web view), so services that block web pages, like LoreBary, work too; replies are still written live.
- **Image proxy**: **Enable**; **Image prompt** (your own guidance for every image: style, quality, anything; `{{char}}` and `{{user}}` work); the image proxies. Only chat-style image models are supported (like OpenRouter with an image model, URL ending in `/v1`); `/images/generations` is refused because it can't take reference pictures. **Test image proxy** makes one small test picture from a reference and shows it.
- **Generation**: presets with temperature, max reply length, top-p, top-k, min-p and penalties (empty = model default); show or hide the thinking of reasoning models; context size.
- **Prompt**: a list of system prompts (the dot picks which one is sent; tap it again for none). Every prompt, Default included, can be renamed, edited and deleted. Forbidden words (the AI is told never to use them) have their own section.
- **New chats**: wait with a Start button before an AI-written opening.
- **Extras → Vector storage**: a long-term memory that searches by meaning. Each exchange in a chat gets an embedding (through OpenRouter's `/embeddings`, with the proxy you pick there; default model `openai/text-embedding-3-small`); with every message, the closest moments from long ago (that the AI no longer sees: older than the context size, or than the last 60 messages without one) are added to the instructions, oldest first, with their date. **On for all chats**, per chat in Chat settings → Memory; how many moments; **Test**. A long chat is indexed once the first time (a few cents); after that one small request per message. If it fails, the reply still goes and a message says why.
- **JanitorAI**: Connect to JanitorAI (see above).
- **Customization**: see Style below.
- **Debug**: a log of errors and crashes (with the screen that was open), and **Download debug report** (device, storage, chat sizes and the log; no messages, prompts or API keys).
- **Privacy** (real account only): **Activate dummy account** makes a second account with its own storage: 15 characters (comedy to extreme horror) and 7 personas, plus a one-time copy of your settings (proxies, prompts, presets, styles, lorebooks; no albums, characters, personas or chats). Long press the title on the title screen to switch (**Switch** / **Switch back**). **Launch app into dummy account** opens it on every fresh start; a switch back lasts until the app is closed. **Reset dummy account** makes it fresh again.
- **Backup**: export / import everything as one file.

No workarounds: a proxy either works or it doesn't. If a model can't see images or the image proxy fails, the error shows in the chat.

## Chat settings

Tabs (tap or swipe): **Memory**, **Style**, **Proxy**, **Image proxy**, **Prompt**. Every section folds open and closed.

- **Memory**: memory sent with every message; a summary prompt and **Summarize** button that writes the not-yet-summarized part of the chat into Memory.
- **Style**: this chat's theme and background, and its style with a **Global** switch (on: the style from Settings, controls hidden; off: the same controls, for this chat only).
- **Proxy**: proxy, generation preset and context size, each with a **Global** switch.
- **Image proxy**: **Enable** (follows Settings until you change it), the image proxy (with **Global**), this chat's **Image prompt** (empty: the one from Settings) and **Make images automatically**.
- **Prompt**: system prompt and forbidden words (each with **Global**), **Repeat the character card near the latest message** (every reply already ends with a short reminder at your newest message to stay true to the character card; this sends the whole personality there too, for a character that drifts), real time (sends the date and time, and marks when messages were sent and whether time passed; an opening the AI writes, also with › under the first message, fits the time of day), lorebooks, and **Character messages you first** (a notification after 30 minutes to 3 days).

A **Global** switch that's off gives the chat its own value, starting from the one in Settings and kept when you switch back and forth. Proxies, presets and prompts can be edited and deleted from a chat too (they're shared with Settings).

## Style

Settings → Customization, and per chat under Chat settings → Style.

- **Saved styles** at the top: **+ Save current style**; tap one to use it (the dot shows which one is in use); ⋯ or long press to update, rename or delete.
- The mock-up with **AI / You / Both**: which side a change applies to. Under Both, a setting that differs between the sides shows as mixed until you change it.
- **Theme**: Default / Light / Dark / Green (the start-up screen's colours) and accent colour. In a chat with **Global** on, the theme comes from Settings too; turn Global off to give the chat its own theme.
- **Layout**: per side: bubble on/off, bubble shape and full width (with a bubble), names, profile pictures (circle or rounded square; tap one in a chat to float it), timestamps. **Picture in the chat header** on or off. For all messages: where they sit (left & right, all left, centered, all right), space between them, and how new messages appear:
  - **Appear**: typing dots while the AI writes, then the whole reply at once
  - **Fade in**: it starts showing once the AI is a little ahead, each new bit fading in, while the AI keeps writing ahead
  - **Slide up**: you watch it being written
- **Font** (**+ Add font** adds your own .ttf, .otf, .woff or .woff2; long press a font to delete it, built-in ones can be brought back), **Text style**, **Text color** and **Markdown** colours, per side.
- **Reset style** (saved styles are kept).

## What the AI receives

System prompt, then the character's personality and scenario, the chat's persona, the chat's memory, example dialogue, then the chat, plus any lorebook entries that match. `{{char}}` and `{{user}}` work in the system prompt and character fields. Markdown works in chats and on character cards.

## Backups

- **Updates keep your data.** Install a new IPA over the existing app (same app ID, same Apple ID in your sideloading tool) and everything stays.
- **Export / Import (Settings → Backup):** one `.json` file with characters, personas, chats, images and settings (API keys included). Import replaces what's in the app.

## iOS app

The `ios/` folder is a native Xcode project (Capacitor) that wraps `index.html`. With a Mac:

```
npm install
npm run ios        # copies index.html into the app, syncs, opens Xcode
```
In Xcode: select the **App** target → *Signing & Capabilities* → pick your Team, then your iPhone, and press Run.

### Without a Mac (sideloading)

Every push builds an unsigned `GreenRoom.ipa` with GitHub Actions (`.github/workflows/ios.yml`). Download it from the **latest-build** release and install it with AltStore, SideStore or Sideloadly; they sign it with your own Apple ID.

## Your own proxy (optional)

```
OPENROUTER_API_KEY=sk-or-... node proxy.js
```
Proxy URL: `http://localhost:8787/api/v1`. Keeps your key out of the browser.
