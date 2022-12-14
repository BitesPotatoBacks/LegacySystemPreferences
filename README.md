<h1 align="center" style="">Legacy System Preferences</h1>
<p align="center">
An expiremental, slightly reverse-engineered attempt (with questionable stability) to return the old System Preferences to MacOS Ventura.
</p>
<p align="center">
    <img src="https://img.shields.io/badge/Swift-F05138?style=flat&logo=Swift&logoColor=white"/>
    <a href="">
       <img alt="Software Support" src="https://img.shields.io/badge/support-macOS_Ventura-orange.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/LegacySystemPreferences/stargazers">
        <img alt="Stars" src="https://img.shields.io/github/stars/BitesPotatoBacks/LegacySystemPreferences.svg"/>
    </a>
</p>

<!--
<p align="center">
Example screenshot :arrow_down:
</p>
-->

<p align="center">
<img src="https://user-images.githubusercontent.com/83843298/202055563-7ffc1d4f-a6f3-4dce-b586-0a33a961fb66.png" width="548">
</p>

<h6 align="center">Screenshot of Legacy System Preferences (using old pref panes) shown above</h6>

___

# :wave: Wait! Functionality Warning
Due to the nature of the project, some old-macOS panes (such as **Software Update** or **Siri**) may be unstable or have limited functionality (see [Pane Status Table](#pane-status-table)), and some crucial features are not fully implemented (see [Completion Checklist](#completion-checklist)).

Some panes may require different privacy privileges in order to work properly. For example, screen recording for **Appearance** (weird, right?) or input monitoring for the keyboard menu in **Accessibility**.

# Project Deets
### Wat it do?
In order restore the classic System Preferences (albeit in a pretty janky manner), we use the NSPreferencePane framework in order to interface with `.prefPane` files. New MacOS still contains the old `.prefPanes`, but most of the bundles are empty (as App Extensions are now used); so instead of using the newer empty files, we rip the completed old ones ([these](https://drive.google.com/drive/folders/1XXXov0TvGNJbwaqKJWsqp0x2cYOKh099?usp=share_link)) out of a previous release of MacOS.

(We don't use the new App Extension files because they wouldn't have the classic look!) 

### Why it do?
Because some of us miss the ways of old (see new [System Settings](https://9to5mac.com/2022/06/06/macos-13-ventura-system-settings-first-look/)). Sure, it may be possible to bring the actual System Preferences from an older release (like Monterey) and run it in Ventura (with the proper pref panes)...

...but it would be a pain to get it to run in most cases, and that method requires access to another Mac or a VM. If you want to go that route and it works, great! It probably will be less janky! Either way, this project is just an attempt of open-source revive-itizing, and was just a fun thing for me to throw togethar.

### Construction!
The project is written in slightly messy Swift using a SwiftUI lifecycle, plus some good ol' Objective-C for legacy stuff. The app is compiled for x86 due to compatability reasons with old pref panes, and must run under Rosetta for Apple Silicon machines.

### Localization!
No localization has been implemented just yet, working on that too...

### Contribution!
If anyone wishes to contribute towards the app???s preference pane support and stability, feel free to make an issue detailing improvement suggestions or open a PR for the change. I will respond and evaluate propositions as quick as possible.

___

# Old Preference Pane Installation
1. Download the preference panes [from here](https://drive.google.com/drive/folders/1XXXov0TvGNJbwaqKJWsqp0x2cYOKh099?usp=share_link).
2. Unzip the download. Use Finder to **Rename > Add Text**. Then, append the extension `.prefPane` to all items in unzipped directory.
3. Make a folder `/Library/LegacyPrefPanes` and move the preference panes into it. 

**Note**: Just like classic System Preferences, this app will not function without `.prefPane` files. If `/Library/LegacyPrefPanes` is empty or does not exist, you will have no panes available. You may also place panes under the native `/Library/PreferencePanes` directory, if you wish.

4. Finally, open `/Library/LegacyPrefPanes` in Terminal, and run the `pane_stripper.sh` tool (located in source or [release DMG](https://github.com/BitesPotatoBacks/LegacySystemPreferences/releases)). Don't forget to `chmod` it first!
5. Now you are ready for..."nostalgia", I guess?

### Waitaminute! What does `pane_stripper.sh` do?
`pane_stripper.sh` removes the code signature of all pref panes in the current operating dir (for compatibilty), and flags them as safe to the system (to stop the system from killing the pane for not having a signature). It is necessary to use this tool for our method, and without it, old pref panes (most likely) will not run in the app.


___

# :warning: Halt! Misc Disclaimers and Warnings
- The app icon used by Legacy System Preferences was designed by Apple, not I, and belongs to the native System Preferences/Settings app.
- The classic preference panes tested and avaiable for use by this app (I'm talking about the ones I have made available [here](https://drive.google.com/drive/folders/1XXXov0TvGNJbwaqKJWsqp0x2cYOKh099?usp=share_link)) were written and licensed by Apple, not I, and were ripped from a previous release of MacOS.

If *any* preference pane (3rd party or from old macOS) contained by this app decides to wig out and bricks your machine or nukes your filesystem, don't blame me for the catastrophe. This project is very much a jank experiment. **You've been warned!!!**

___

## Completion Checklist
This is a checklist of features that obviously existed in old System Preferences, which this project may or may not have currently.
- [ ] Localization
- [ ] Search Completion Dropwdown
- [ ] AppleID Avatar Setting
- [X] ~~User Avatar Collection~~
- [x] ~~Search with Spotlight Focus~~
- [X] ~~Backwards/Forwards Navigation~~
- [x] ~~Crossfade Transitions~~
- [X] ~~Alphabetical Pane Sorting~~
- [X] ~~Pane Enable/Disable~~
- [X] ~~3rd Party Pane Support~~
- [X] ~~Pane Loading~~

**Notes:** 3rd party panes are allowed but may still suffer instability depending on the vendor, architecture, and etc. Place them in `/Library/PreferencePanes` as you normally would.

## Pane Status Table
This is a report on functionality of the old system pref panes (using [these](https://drive.google.com/drive/folders/1XXXov0TvGNJbwaqKJWsqp0x2cYOKh099?usp=share_link)) running via this project.

**Note:** Some panes, such as **Appearance**/**General**, work fine but may crash the app.
| Status | Pane(s)
| ---- | ---- |
| Seemingly Working | General, Spotlight, Language & Region, Sound, Sidecar, Date & Time, Energy Saver, Sharing, Network, Mouse, Security & Privacy, Extensions, Users & Groups, Mission Control |
| Missing Crucial Funcs | Apple ID, Internet Accounts, Notifications, Desktop & Screensaver, Software Update, Startup Disk |
| Failing | Fibre Channel, Dock, Family Sharing, Printer & Scanner, Siri, Bluetooth, Keyboard, Trackpad, Displays, Classroom, Profiles, Screen Time, Time Machine, Wallet |
| Untested or Seemingly Working | Battery, CDs & DVDs |
