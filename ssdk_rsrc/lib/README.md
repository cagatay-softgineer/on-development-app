# ssdk_rsrc/lib Overview

This directory contains the Flutter source for the mobile client.
It currently follows a conventional Flutter layout using models,
services and widgets. The project is built with Dart 3.7.

## Current Architecture

The codebase is organised by type. Screens live under `pages/` as
`StatefulWidget` classes. These widgets call helper functions from
`utils/` and perform API requests through the `services/` layer.
Session information is stored in static classes inside `providers/`.
This gives a quick way to build features but mixes UI, business logic
and navigation concerns in the same classes.

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
VIPER layers.

## VIPER vs Current Approach

The current approach keeps most logic in the page widgets. VIPER would
split responsibilities more strictly:

- **View** – only displays data and forwards user events.
- **Presenter** – prepares data for the view and handles state.
- **Interactor** – performs business logic and networking.
- **Entity** – holds plain model objects.
- **Router** – coordinates navigation.

Today the `TimerPage`, `HomePage` and other screens fetch data and manage
state on their own. Providers such as `UserSession` expose global mutable
state, which can lead to tight coupling. Under VIPER, presenters and
interactors would encapsulate this logic and expose simple interfaces to
the views. This separation improves testability and makes it easier to
replace or mock the networking layer.

## Migration Feedback

- Extract networking and timer logic from page widgets into
  `Interactor` classes.
- Replace global session providers with presenter-managed state.
- Keep widgets dumb so that each view only renders data.
- Introduce a router to centralise navigation, removing manual
  `Navigator` calls from views.

