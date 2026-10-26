# <img src="https://github.com/CATVIII/sabermi/raw/main/assets/icon/icon.png" width="30" height="30" alt="Logo"> SaberMI

> **This is a fork of Saber.** SaberMI is a modified version of
> [Saber](https://github.com/saber-notes/saber), forked from v1.37.0
> (commit `57e62dc`). It is **not** the official Saber build and is not endorsed
> by the original author. See [NOTICE.md](NOTICE.md) for the full list of
> changes.
>
> SaberMI is free software, licensed under the GNU General Public License v3.0 —
> the same licence as upstream.

[English](https://github.com/CATVIII/sabermi/blob/main/README.md) |
[čeština](https://github.com/CATVIII/sabermi/blob/main/README-cs.md) |
[Deutsch](https://github.com/CATVIII/sabermi/blob/main/README-de.md) |
[中文 (简体中文, 中国)](https://github.com/CATVIII/sabermi/blob/main/README-zh-CN.md) |
[中文 (繁體, 台灣)](https://github.com/CATVIII/sabermi/blob/main/README-zh-TW.md) |
[العربية](https://github.com/CATVIII/sabermi/blob/main/README-ar.md) |
[Tiếng Việt](https://github.com/CATVIII/sabermi/blob/main/README-vi.md) |
[Bahasa Indonesia](https://github.com/CATVIII/sabermi/blob/main/README-id.md)

Saber is the notes app built for handwriting.

It's designed to be as simple and intuitive as possible, while still delivering unique features that you'll actually use. Additionally, Saber is available across all your devices, large and small, and syncs between them seamlessly.

Notably, it can invert your notes when you're in dark mode. This allows you to write with white ink on a black background, which is much easier on the eyes in low-light environments like when the teacher turns off the lights in class.
Images and PDFs are also inverted, so you can still use a digital printout or a textbook without the fuss.

Saber uses a dual-password system to protect your notes from anyone but you, even if they have complete control over the server. You can safely store your notes on the official Saber server, another server, or even host your own!

The app is completely open-source so that anyone can view the source code and see exactly what it's doing and how it handles your data. Many other note-taking apps are closed-source and proprietary, meaning that their inner workings are a mystery to the public.

As someone who studies maths, highlighting multi-line equations was always a hassle with other apps, where the highlighter would change color when it overlapped with itself. Another problem I had was that in some apps, the highlighter would render on top of the text, fading it out and making it hard to read.
Saber's highlighter has no such issues. It utilizes canvas compositing to render the highlighter in a way that is consistent with/better than traditional paper, where it handles overlaps and maintains color consistency.

Saber has everything you need to keep your notes organized. Create folders inside folders inside folders to your heart's content with no limit on the number of nested folders. And even though a note may be buried deep within a nested folder, you can still access it easily with your most recent notes always available on the home screen.

Discover a whole new way to capture and organize your thoughts with Saber. Whether you're a student, professional, or creative mind, Saber is your trusted companion for digital handwriting. Download now and let your ideas flow freely!

[![GitHub Sponsors](https://img.shields.io/github/sponsors/adil192)](https://github.com/sponsors/adil192)
[![License](https://img.shields.io/github/license/CATVIII/sabermi)](https://github.com/CATVIII/sabermi/blob/main/LICENSE.md)

<details open>
<summary>Tap to show/hide screenshots</summary>

<div>
<img src="https://github.com/CATVIII/sabermi/raw/main/metadata/en-US/images/phoneScreenshots/1_home.png" width="180">
<img src="https://github.com/CATVIII/sabermi/raw/main/metadata/en-US/images/phoneScreenshots/2_editor.png" width="180">
<img src="https://github.com/CATVIII/sabermi/raw/main/metadata/en-US/images/phoneScreenshots/3_login.png" width="180">
<img src="https://github.com/CATVIII/sabermi/raw/main/metadata/en-US/images/phoneScreenshots/4_settings.png" width="180">
</div>
</details>

## Features

Please see [#1 Saber progress][progress].

## Install

SaberMI is distributed as an APK built from source; it is not on Google
Play, F-Droid, the App Store, Flathub or snapcraft.

Grab the latest build from
[Releases](https://github.com/CATVIII/sabermi/releases).

It installs alongside the official Saber (`com.sabermi` vs
`com.adilhanney.saber`), so both can be kept side by side.

## Build from source

The upstream build instructions apply unchanged:
[Build Saber](https://github.com/saber-notes/saber/wiki/build).

Differences in this fork: the extra local plugin in
`packages/miui_penengine`, and no crash or build-symbol upload anywhere
(see [NOTICE.md](NOTICE.md)).

## Links

- [Releases][releases]
- [Issues][issues]
- [Privacy policy][privacy]
- [License][license]
- [Nextcloud server][nextcloud] (upstream service)

## Translating

All translations are thanks to our community of contributors.

If you'd like to help out translating Saber, head to [Weblate](https://hosted.weblate.org/engage/saber-notes/)!

[![Translation status](https://hosted.weblate.org/widget/saber-notes/multi-auto.svg)](https://hosted.weblate.org/engage/saber-notes/)

Note: To avoid falling back to English, any gaps in the translations are filled
in by machine translation until a human can contribute.

## Supporting Saber

If you like Saber, please consider supporting it by:
- Spreading the word!
- Starring the project on GitHub
- Sponsoring me on [GitHub Sponsors](https://github.com/sponsors/adil192)
- Donating via [PayPal](https://paypal.me/adilhanney)
- Buying more storage on the Nextcloud server: see [Pricing](pricing.md)

## Development notes

Please see
[Maintainer notes](https://github.com/saber-notes/saber/wiki/Maintainer-notes)
on the wiki.


[nextcloud]: https://nc.saber.adil.hanney.org/

[privacy]: https://github.com/CATVIII/sabermi/blob/main/privacy_policy.md
[license]: https://github.com/CATVIII/sabermi/blob/main/LICENSE.md

[releases]: https://github.com/CATVIII/sabermi/releases
[issues]: https://github.com/CATVIII/sabermi/issues
[progress]: https://github.com/saber-notes/saber/discussions/1
