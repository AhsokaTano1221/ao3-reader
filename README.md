# AO3Reader (iOS) ✎ᝰ.ᐟ⋆⑅˚₊

An easy way for you to access your favorite fanworks offline! ✮⋆˙

---

## Why did I make it? ∘ ∘ ∘ ( °ヮ° ) ?

As an avid user of AO3, I've experienced the ups and downs of using AO3 on mobile. No downloading, keeping infinitely many tabs open, etc. As a disclaimer, I do not earn any money from this, nor do I have access to any person's account. I simply made it as a project for myself to work on.

---

## What the App Can Do So Far ◝(ᵔᗜᵔ)◜

The app is arranged into four main pages. Home, Search, Library, and Settings.

### 1. Home Page
- Displays whether you are signed into an account or on a guest account.
- Records your last opened fic you read, and what position you left at.
- Displays favorited tags for easy access.

### 2. Search Page
- There are two options. Direct URL search or the classic AO3 tag search on the website.
- AO3 tag search includes all the fields from the original website.
- Once you have completed your search, you can view the fics that match, loading twenty fics per page. You can also edit your search.

### 3. Library Page
- Four subsections; Saved Offline, Passages, AO3 Bookmarks, and AO3 History.
- **Saved Offline**: Displays fics you have downloaded.
- **Passages**: Ever have a quote or part of a fic you loved? Passages is where you can save those said parts, and easily access them later.
- **AO3 Bookmarks**: If logged in, displays all your AO3 Bookmarks you have made on the AO3 website.
- **AO3 History**: Similarly to Bookmarks, displays your AO3 history.

### 4. Settings
- Lets you log in or out of your AO3 account, or stay on guest.
- Customize app look and feel (e.g. font, font size, colors, etc.)

### Reader View
Once you open a fic, it will open in Reader View. You are currently able to...
- View work comments
- Access Table of Contents
- Mark passages
- Save for offline reading
- Change font size
- View tags of the fic

As of this first version, you are unable to add Kudos or Comments. I will be working to add this shortly!

---

## How to Get the App (˵• ̀⩊•́˵)

Currently, as an app which is not downloadable on the Apple App Store, just a project of mine, the only way to download the app is the following.

### Requirements:
- You will need a Mac and Apple ID

### 1) Enable Developer Mode on your iPhone
- Settings > Privacy & Security > Scroll to Developer Mode

### 2) Get Xcode
- Once you have Xcode, connect your iPhone to your Mac using a cable and tap "Trust this Computer" if prompted.
- Open the files for the project on Xcode.
- Go to the Signing & Capabilities tab, check Automatically manage signing, and under Team, select your Personal Team (log into your Apple ID)

### 3) Build and Install
- At the top bar of Xcode, select your connected phone as the target for the build, rather than a simulator.
- You may be prompted to enter your device's password.

### 4) Trust Developer Certificate on the iPhone
- Go to Settings > General > VPN & Device Management.
- Tap your Apple ID under Developer App.
- Tap Trust "[Your Apple ID]" and confirm.

The app will expire after SEVEN DAYS, so if you want to continue using the app, make sure to rebuild the app after a week.

---

## Technical Details ( ꩜ ᯅ ꩜;)⁭ ⁭
- Framework: SwiftUI, Combine
- Project Structure: Generated via XCodeGen
- Parsing Engine: SwiftSoup (HTML Web Scraping)
- Minimum Target: iOS 16.0

---

## DISCLAIMER ( ◺˰◿ )

I will repeat this once again, AO3Reader is an unofficial client and is not affiliated with or endorsed by the Organization for Transformative Works (OTW) or Archive of Our Own (AO3).

---

I hope you enjoy using AO3Reader! ᥫ᭡.ִֶָ𓂃 ⸜(｡˃ ᵕ ˂ )⸝♡
