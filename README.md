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

### Group chats

Chats → + → New group chat: pick two or more characters (the order you tap is the list order), a name and a persona. Chat settings → Group opens first to set it up. The chat starts empty: with **AI writes the opening** on, tap a character above the text box and they open the scene; off, you write first. Each reply is written by one character with their own card; the whole chat goes along with names.

- **Member faces** next to + and Author's note (‹ hides them, › brings them back): tap a character to make them reply now (even when muted); long press to mute or unmute. **Auto** keeps them talking to each other, 5 seconds apart, until you type.
- **Chat settings → Group**: name, members (add, remove, reorder, mute), reply order, self responses, auto-mode, Swap or Join character cards, group scenario, and each member's own scenario with a switch to include it.
- **Reply order**: Natural (everyone you mention by name in your message replies, in that order — names in the characters' replies don't count; otherwise one by talkativeness, or someone at random), List (everyone in order), Pooled (someone who hasn't spoken since your message), Manual (only who you tap).
- **Talkativeness** is set per character in Chat settings → Group (with Natural order), for that group only.
- Regenerate and Continue use the character who wrote that message. Write for me, Enhance and pictures go with whoever spoke last. Deleting a character removes them from their groups.

### Trying prompts and models

Long press a character's reply:
- **What was sent**: the exact request behind it: proxy, model, prompt name, size in characters and tokens, and every part (system prompt with card, lorebook entries and memories; the messages; your last message with the notes added to it). Lorebook entries that went along are listed at the top, each with the keyword and the message that triggered it. **Copy** copies it all. Replies written since the app was opened are shown exactly; older ones are rebuilt from the chat as it is now.
- **Describe a character…**: type the name of a side character. Every message that mentions them (with the one before it) goes to the AI, which writes one paragraph about only that character (looks, voice, personality, role; nothing about the others or the story). **Copy** it and paste it into the generator as the idea.
- **Version with…**: another version of that reply with another proxy and/or prompt, without changing the chat's settings. It's added as a version (‹ ›), with "Written with *proxy · prompt*" under it, so you can compare.

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

The chat is written part by part; each part gets both people's texts, the point of view, a running summary of the story so far (10–15 sentences, with names of side characters, places and objects) and the last paragraphs of the previous part, so it continues seamlessly. It's saved after every part. While it writes, the screen stays on; tap the story to unfold a panel with a progress bar, what it's doing (which chapter, how many characters so far, about how long is left) and **Stop**. Cut off by leaving the app or closing it, it continues by itself when you come back; after Stop or an error, the panel has **Continue writing** and **Read what is written**. Stories show as covers in a grid; long press one to publish/export, **Edit** (title, the characters' names shown with it, cover style, and the text and title of every chapter), rename, make a new cover or delete it.

The reader: pages (tap the left or right edge or swipe; tap the middle to hide the bars) or scrolling, **Contents**, and **Aa** for size, font, page colour (paper, sepia, night, or the app's theme) and spacing. Tap the cover to see it full screen. It remembers where you were. PDF (A5 pages, made by iOS) works in the iPhone app; EPUB opens in Apple Books.

## Characters and personas

- **Characters**: image, name, optional chat name (used in chats and for `{{char}}`), description (shown in the list, never sent to the AI; written in a formatting editor: paragraph / headings / quote, bold, italic, underline, strikethrough, highlight and text colour, alignment, list, divider, pictures from your albums, links (a link to a picture shows the picture), and </> to see or edit the HTML; imported HTML bios keep their formatting), personality, scenario, first messages (several options to flip through until you reply, or let the AI write the opening, which follows your selected system prompt; **Generate** writes its openings in third person limited, from the character's point of view) and example dialogue. The editor shows characters and tokens of what is sent.
- **Import** → *Character card (file)* (PNG/JSON) or *From Chub link* fills everything in; from Safari or Files, **Share → Green Room** does the same. **Generate** writes a whole character, with a picture, from a few words, asking first which style the picture should be (remembered), keeping personality, scenario and example dialogue at about 1,000–2,000 tokens, following the **Template** on that page (field headings plus [instructions]; editable, with Reset to default). **+** at the top right: create new or generate.
- The picture: tap it to choose one from your phone or **From album**. **Generate image** in the editor also asks for the style first. Profile pictures are asked for in a tall 2:3 shape (head to waist, centred), both in the prompt and as the image model's aspect-ratio setting (OpenRouter `image_config`).
- **Frame picture** (opens after you pick a picture, and from the editor any time): drag, pinch or slide to choose what shows, with live previews of the chat header, messages, chats list, characters list and profile. Tap a preview to frame just that spot (its own shape: circle, or tall for the lists); the others follow the main framing. The profile shows the whole picture, in its own shape. Works for characters and personas.
- Tap a character to unfold its **Profile** and **+ Start new chat**. The button next to + switches Characters between a list, a compact list and a grid, and Personas and Albums between a list and a grid (picture, name, bio); in the grid, tapping a character opens the profile and tapping the text unfolds the whole description with a **Chat** button under it. In the profile, ⋯ at the top has Edit, Export card and Delete. The profile opens with the description unfolded and the rest folded. Starting a chat: persona folders come first (tap one to unfold the personas in it); tapping a persona shows its description, with **Start chat as …**. The eye on a picture blurs it everywhere except in a chat and the editor.
- **Personas**: who *you* are: image, name, personality.
- Swipe a character or persona left for **Move** (to a folder) and **Delete**; long press to select several.

### Prompt layout and SillyTavern presets

Settings → Prompt → **Prompt layout**: everything a request is made of, as blocks in order: Main prompt, Character, Group, Persona, Lorebook, Memory, Reply length, Example dialogue, Forbidden words, Real time, Pictures, Recalled moments and **Chat** (the messages), plus your own blocks. **Standard** is GreenRoom's own layout and can't be changed; **+ New** makes an editable copy. Per block: on/off (the Group block switches itself: on in group chats, off otherwise), ↑ ↓, role (system, user, assistant) and place: where it is in the list (above Chat = before the messages, system ones in the system prompt; below Chat = after them, system text added to your last message) or **inside the chat** a number of messages back. Your own blocks have a name and text. A chat can use another layout (Chat settings → Prompt: the one in use is highlighted, **+ New** makes one there too). Long press a layout to duplicate, rename or delete it. What was sent lists the layout and where each block went.

**Import SillyTavern preset** (same place): a chat-completion preset (.json) becomes a layout in their prompt order (their markers map to GreenRoom's blocks; their main, NSFW, post-history and custom prompts become your blocks with their role and depth; GreenRoom's own main prompt is kept but switched off) and a generation preset with their values. Logit bias is not imported.

Generation presets also have **Reasoning effort** (thinking models), **Assistant prefill** (the reply starts with it; only the character's replies), **Stop strings** (the reply is cut there, e.g. `{{user}}:`), **Top-a** and **Seed**, each explained in the app.

### Prompts for a character

In the character editor (folded, under Character's note): **Main prompt for this character** replaces your system prompt in chats with that character; `{{original}}` in it puts your system prompt there. **After the chat, for this character** is placed after the chat with every reply of that character. Both come from and go into SillyTavern cards (`system_prompt`, `post_history_instructions`), and are available as `{{charPrompt}}` and `{{charInstruction}}`. In the prompt layout the second one is the block **After the chat (character)**; older layouts send it after the chat too.

### Macros

Placeholders filled in when a request is sent, in prompts, layout blocks, cards, notes, persona, lorebook entries, prefill and stop strings (the full list is in Settings → Prompt → Macros you can use): `{{char}}`, `{{user}}`, `{{random:a,b,c}}` (each time), `{{pick:a,b,c}}` (the same for the whole chat), `{{roll:d20}}` / `{{roll:2d6+1}}`, `{{time}}`, `{{date}}`, `{{weekday}}`, `{{idle_duration}}`, `{{lastMessage}}`, `{{lastUserMessage}}`, `{{lastCharMessage}}`, `{{group}}`, `{{charIfNotGroup}}`, `{{model}}`, `{{newline}}`, `{{trim}}`, `{{// comment}}`, chat variables `{{getvar::x}}`, `{{setvar::x::y}}`, `{{addvar::x::n}}`, `{{incvar::x}}`, `{{decvar::x}}`, the same shared by all chats (`{{getglobalvar::x}}` etc.; Settings → Prompt → Macros you can use → Shared variables), the card as text (`{{description}}` = the personality field, `{{personality}}` (empty when `{{description}}` is in the same text), `{{scenario}}`, `{{mesExamples}}`, `{{charDepthPrompt}}`, `{{persona}}`), `{{notChar}}`, `{{groupNotMuted}}`, `{{isodate}}`, `{{isotime}}`, `{{noop}}`, `{{reverse:text}}`. `{{summary}}` (the chat's Memory). SillyTavern's old placeholders `<USER>`, `<BOT>`, `<CHAR>`, `<GROUP>` and `<CHARIFNOTGROUP>` (any letter case) are filled in too. The newer SillyTavern syntax works too, so presets built with it (Pura, Sola, Deus Ex Machina, Voyage 6…) run with their switches: `{{if .x}}…{{else}}…{{/if}}`, `{{#if .x}}` (keeps the whitespace), `{{if !.x}}`, `{{if::{{persona}}}}`, `{{if {{getvar::x}}}}`, short variables `{{.x}}` (= `{{getvar::x}}`), `{{.x = v}}`, `{{.x += n}}`, `{{.x++}}`, `{{.x--}}`, comparisons `{{.x == v}}` (`!=`, `>`, `<`, `>=`, `<=`), shared ones with `$` (`{{$x}}`), and `{{setvar::x}}…{{/setvar}}`. Everything is worked out from top to bottom, so a switch sees the variables set above it; comments may hold macros. Variables are saved once per request. Within one request every text is filled once (same random result, a variable changes once); What was sent changes nothing. Variables can be seen and changed in Chat settings → Prompt → Variables. Unknown macros are left as they are.

### Character's note

In the character editor, under Example dialogue: a few lines the AI gets with every reply, placed close to the end of the chat (at your newest message, or 2, 4, 6 or 10 messages back; 4 by default), where the AI pays the most attention. Use it for what the character tends to lose in long chats: voice, attitude, habits. In a group chat each character's note only goes with their own replies. Imported from and exported to SillyTavern / Chub cards (their "Character's Note").

### Replace rules

Settings → Extras → **Replace rules**: find and replace that runs by itself. Each rule: **Find** (plain text, or a pattern/regex), **Replace with** (empty deletes it), **Applies to** (the character's replies, your messages, or both) and **Where**: *Change it* (the message itself is changed when it's written), *On screen only* (you see it changed, the AI gets the original) or *Only what's sent* (the AI gets it changed, you see the original). The editor shows a **test** on your last chat: how many matches and the newest examples, before and after. **Describe it…**: say in plain words what should go ("remove the question at the end asking what I do next") and the AI writes the rule, which opens in the editor with the test to check before saving. A chat can switch single rules off in Chat settings → Prompt.

## Lorebooks and albums

- **More options** per entry (folded; a tag on the entry shows when something is set): **Second keywords** (the entry only fires when one of them is also in the recent messages, or with *Not if*, when none of them is), **Chance it fires** (e.g. 30% for random events; a sticky run doesn't roll again) and the timing below.
- **Timing** per entry (in messages; 0 = off): **Sticky** keeps an entry on for that many messages after its keyword was last seen, even when nobody says it (people in a scene); **Cooldown** stops it triggering again for a while afterwards (running jokes); **Delay** keeps it out until the chat has that many messages (slow reveals). Each chat keeps its own timing; regenerating doesn't count as a new message. What was sent shows why an entry went along or was left out (sticky, cooldown, delay, budget).
- **Lorebook from chat** (Chat settings → Prompt → Lorebooks → **Make a lorebook from this chat**): the AI reads the whole chat in parts (~30,000 characters each, one request per part) and writes entries for side characters, places, objects, events and running jokes, each with keywords, updating them as the story goes on. The chat's characters and your persona get no entries (they have cards). You check them (switch off, edit title, keywords, text), then **Make the lorebook** creates it and links it to the chat. Stop keeps what was found so far.
- **Lorebooks**: world info. Each entry has keywords and is only sent when one appears in the recent messages (or always, if marked). Use one everywhere, link it to a character, a persona (used in every chat where you play it) or a chat. Imported and exported with character cards; SillyTavern world info files work too.
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
- **Extras → Vector storage**: a long-term memory that searches by meaning. Each exchange in a chat gets an embedding (through OpenRouter's `/embeddings`, with the proxy you pick there; default model `openai/text-embedding-3-small`); with every message, the closest moments from long ago (that the AI no longer sees: older than the context size, or than the last 60 messages without one) are added to the instructions, oldest first, with their date. **On for all chats**, per chat in Chat settings → Memory (with how far the chat is indexed, e.g. "Indexed: 412 of 412 exchanges · up to date", and **Index now**); how many moments; **Test**. A long chat is indexed once the first time (a few cents); after that one small request per message. If it fails, the reply still goes and a message says why.
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

### Look and feel (recent)

- Back buttons are arrows everywhere; the chat's Profile button is a person icon.
- Headers (and the chat's message box) float over the content: while you scroll, the line under the header goes and the content fades out as it reaches the header (and the message box in a chat); when you stop, it's back to normal.
- Style → **Side margin**: space between the messages and the screen edges (global or per chat).
- A chat's background keeps its place when the keyboard opens; the thumbnail under Background and the text preview show it, dimmed as set.
- Personas have a compact list too (the view button cycles list, compact, grid).
- Chat settings no longer switch tabs on a sideways swipe.
