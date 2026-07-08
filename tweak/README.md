# VLC Crossfade — iOS jailbreak tweak

Adds crossfade between tracks and fade in/out on play/pause to VLC for iOS
(`org.videolan.vlc-ios`). Built for **arm64e**, packaged with the
**roothide** scheme.

## Features

- Equal-power (or linear) crossfade between the current and next queue item.
- Configurable crossfade duration (1–12 s, default 6 s).
- Optional fade-in on play and fade-out on pause/stop (default 400 ms).
- PreferenceLoader pane under Settings → VLC Crossfade.

## Building via GitHub Actions

Push to `main` or trigger the **Build VLCCrossfade** workflow manually.
The workflow installs roothide Theos + SDKs on an Ubuntu runner, builds the
tweak, and uploads `tweak/packages/*.deb` as an artifact. Tagging `v*`
attaches the `.deb` to a GitHub Release.

## Building locally (macOS or Linux with Theos)

```sh
export THEOS=~/theos
cd tweak
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=roothide
```

Output: `tweak/packages/com.lovable.vlccrossfade_0.1.0_iphoneos-arm64e.deb`

## Configuration

Bundle id: `com.lovable.vlccrossfade`. Change in `control` and
`Crossfader.m` (`kPrefsSuite`) plus `Prefs/Resources/Root.plist` if you fork.

Preferences suite: `com.lovable.vlccrossfade`
- `Enabled` (BOOL, default YES)
- `Duration` (float seconds, default 6.0)
- `Curve` (`linear` | `equalPower`, default `equalPower`)
- `FadeOnPlayPause` (BOOL, default YES)
- `PlayPauseFadeDuration` (float seconds, default 0.4)

## How it works

Hooks `VLCPlaybackService` (`play`, `pause`, `stopPlayback`) from
MobileVLCKit inside VLC-iOS. A 4 Hz ticker polls `remainingTime` on the
active `VLCMediaPlayer`; when it drops below the configured crossfade
duration, a second `VLCMediaPlayer` is spun up on the queue's next media
and both players' `audio.volume` are ramped in opposite directions on a
30 fps `dispatch_source_timer`. On completion, `VLCPlaybackService.next`
is invoked so VLC's own queue index advances.

## Third-party notes

- **Theos** and **roothide SDKs** are fetched at CI time from their
  upstream repositories; not vendored here.
- **MobileVLCKit** (LGPL, © VideoLAN) is dynamically linked at runtime
  from VLC.app. Only a minimal public-header stub is vendored under
  `vendor/MobileVLCKit.framework/Headers/` to allow compilation.

## License

MIT — see `../LICENSE`.
