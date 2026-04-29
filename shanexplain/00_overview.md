# Overview — What Is This App and How Does It Work?

Welcome, Shane! These files are written specifically for you to understand your **first Flutter project** from the ground up. No prior knowledge assumed.

---

## What is this app?

This app is called **Dragon**. Right now it does the following:

- Shows a **splash screen** (a loading/intro screen with an animation) when you open the app
- Lets users **register** (create an account) with their email and password
- Lets users **log in** with their email and password
- Shows a **shell** after logging in — a permanent frame with an app bar, a bottom navigation bar (two tabs: Home and Food), and a slide-out profile drawer
- The **Home tab** shows a welcome card with the user's email and a dashboard placeholder
- The **Food tab** is a placeholder for future content
- **Automatically redirects** you based on whether you're logged in or not

It's a solid foundation — the "skeleton" — that you can build any real app on top of.

---

## What is Flutter?

Flutter is a framework made by Google that lets you write **one codebase** and run it on:
- Android phones
- iPhones (iOS)
- Web browsers
- Windows / Mac / Linux desktops

The language Flutter uses is called **Dart**. Dart files end in `.dart`.

Think of Flutter like LEGO — it gives you pre-built blocks called **widgets** (buttons, text boxes, screens, etc.), and you snap them together to build a UI.

---

## What is Firebase?

Firebase is a service by Google that handles things that would otherwise require you to build your own server. In this app, you're using:

- **Firebase Authentication** — handles all the login/register/logout logic. Firebase stores user emails and passwords securely in the cloud so you don't have to.

You don't need to write any "save password to database" code — Firebase does it all for you.

---

## The Big Picture Flow

```
App opens
    ↓
Splash Screen (2.8 seconds of animation)
    ↓
Is the user already logged in?
    ↓ YES → Main Shell (with bottom nav bar)
    ↓ NO  → Login Screen
              ↓
          User taps "Register" → Register Screen
              ↓
          User creates account → automatically sent to Main Shell

Inside the Main Shell:
    ↓
    Bottom nav: [ Home tab | Food tab ]
    Left corner: Avatar button → opens Profile Drawer (logout here)
```

---

## Files in this folder

See [INDEX.md](INDEX.md) for the full, up-to-date list of explanation files and instructions on how to add new ones when you update the codebase.
