# 修改声明 / Modification notice

**SaberMI** is a modified version of **Saber**
(<https://github.com/saber-notes/saber>).

- Upstream project: Saber, by Adil Hanney and contributors
- Fork point: `v1.37.0` (commit `57e62dc`, 2026-10-25)
- Fork date: 2026-10-27
- Fork maintainer: Cat8th
- Fork repository: <https://github.com/CATVIII/sabermi>

This is **not** the official Saber build. It is not endorsed by, affiliated with,
or supported by the original author.

---

## Changes in this fork

1. **Xiaomi Focus Pen Pro gesture support** — new local Flutter plugin
   `packages/miui_penengine`, plus editor, preferences and settings integration.
   The pen body's *pinch*, *double tap*, *slide up* and *slide down* gestures can
   be mapped to editor actions (toggle eraser, page navigation, undo/redo, …).
2. **Renamed to SaberMI**, with `applicationId` `com.sabermi`, so the fork can be
   installed alongside the official Saber.
3. **Distribution channels removed from the README** — the fork is not published
   on Google Play, F-Droid, the App Store, Flathub or snapcraft.
4. **Hardened `.gitignore`** for local build artefacts and signing material.

Nothing has been removed from the upstream source; all upstream copyright
notices are retained verbatim.

### On the Xiaomi pen integration

The gesture protocol was reverse engineered from the device and reimplemented as
a plain AIDL client
(`packages/miui_penengine/android/src/main/kotlin/.../PencilEngineClient.kt`).
**No proprietary Xiaomi binary — no SDK `.aar`, `.jar` or `.so` — is bundled with
this fork.** Bundling one would have made the combined work non-distributable
under the GPL, so this matters for licence compliance.

---

## Licence

SaberMI is free software: you can redistribute it and/or modify it under the
terms of the **GNU General Public License** as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but **without any
warranty**; without even the implied warranty of merchantability or fitness for a
particular purpose. See the GNU General Public License for more details.

The full licence text is in [`LICENSE.md`](LICENSE.md). The original Saber
licence is GPL-3.0 as well, so this fork keeps the same terms.

---

## Copyright

```
Saber      Copyright © 2022-2026  Adil Hanney
SaberMI    modifications Copyright © 2026  Cat8th
```

Per GPL-3.0 §5(a), the modifications above are marked with their date and are
released under the same licence as the original work.
