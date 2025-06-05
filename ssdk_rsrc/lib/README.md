# ssdk_rsrc/lib Overview

This directory contains the Flutter source for the mobile client.
It currently follows a conventional Flutter layout using models,
services and widgets. The project is built with Dart 3.7.

## Directory Structure

- `constants/` – Default constant values used across the app.
- `enums/` – Enumerations such as `MusicApp` for supported services.
- `models/` – Data models for playlists, tracks and UI utilities.
- `pages/` – Application screens including home, login and music views.
- `providers/` – Global session state holders.
- `services/` – API integrations (main server, Spotify, Apple Music).
- `styles/` – Shared color palettes and button styles.
- `themes/` – Light and dark theme definitions.
- `utils/` – Helper functions for authentication and timers.
- `widgets/` – Reusable UI components and skeleton loaders.
- `main.dart` – App entry point and route definitions.

## VIPER Migration

We plan to migrate this codebase to [VIPER](https://en.wikipedia.org/wiki/VIPER_(software_architecture)),
which separates logic into **View**, **Interactor**, **Presenter**, **Entity** and **Router** layers.
A suggested mapping is as follows:

- **Entity** – contents of `models/`.
- **Interactor** – business logic currently in `services/` and parts of `utils/`.
- **Presenter** – UI state handling presently in `providers/` or page state classes.
- **View** – widgets under `pages/` and `widgets/`.
- **Router** – navigation helpers like `navigation_page.dart` and route setup in `main.dart`.

During migration, each module should own a well-defined feature and expose
interfaces so that the layers remain decoupled. Existing files can be
refactored gradually, placing new code under directories reflecting the
