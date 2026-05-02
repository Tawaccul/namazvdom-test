# Stage Step Screen: Architecture Guide

## Goal
This document explains which file is responsible for what in the Stage Step screen flow, and where to change behavior safely.

## Entry Points
- `lib/features/stage/stage_step_screen.dart`
  - Public entry for the feature.
  - Re-exports implementation layer.

- `lib/features/stage/stage_step_screen_impl.dart`
  - Thin implementation entry.
  - Re-exports state implementation.

- `lib/features/stage/stage_step_screen_state.dart`
  - Main `StatefulWidget` and state orchestration.
  - Keeps screen-level state, wiring, lifecycle, and integration of helpers.

## Screen Composition Files
- `lib/features/stage/parts/stage_step_screen_builder.dart`
  - Builds the final screen body composition.
  - Connects progress card + content section + scaffold.
  - Change here when you need to reorganize the screen body structure.

- `lib/features/stage/parts/stage_step_screen_scaffold.dart`
  - Handles the shell layout: gestures, overlays, pinned progress, onboarding overlay, overview layer container.
  - Change here for stack/positioning/overlay visibility behavior.

- `lib/features/stage/parts/stage_overview_page_builder.dart`
  - Renders one overview page card.
  - Change here for preview card UI/content in overview mode.

- `lib/features/stage/stage_overview_geometry.dart`
  - Pure geometry/transformation math for overview canvas and cards.
  - Change here for zoom/position/matrix/clamp behavior.

## Behavior Helpers
- `lib/features/stage/parts/stage_additional_surah_helper.dart`
  - Additional surah selection logic and local fallback loading.
  - Key points:
    - `isAdditionalSurahStep`
    - `selectedIndexForStep`
    - `replaceAdditionalSurahSteps`
  - Change here if insertion/replacement strategy for additional surah steps changes.

- `lib/features/stage/parts/stage_audio_playback_helper.dart`
  - Audio play/pause/autoplay/session lifecycle.
  - Key points:
    - `togglePlay`
    - `startPageAutoplayFrom`
    - `waitForPlaybackCompletion`
    - `selectAyahInCurrentStep`
  - Change here for playback rules, autoplay sequence, completion detection.

- `lib/features/stage/parts/stage_step_screen_flow_helper.dart`
  - Navigation and step/rakaat flow utilities.
  - Key points:
    - `nextStep`
    - `prevStep`
    - `jumpToRakaatAndStep`
    - `displayStepProgressFor`
  - Change here when step transition logic or progress calculation rules change.

- `lib/features/stage/parts/stage_step_data_helper.dart`
  - Pure data derivations: indexes, grouped entries, stage page mapping.
  - Key points:
    - `stepOrderIndexesForRakaatIndex`
    - `allStagePages`
    - `currentFlatPageIndex`
    - `entriesForPage`
    - `recitationEntriesForPage`
  - Change here for data mapping/selection logic.

- `lib/features/stage/parts/stage_overview_state_helper.dart`
  - Overview mode state flow (open/close/pan/transform scheduling).
  - Key points:
    - `openOverviewMode`
    - `closeOverviewMode`
    - `handleOverviewPanUpdate`
    - `animateOverviewMatrix`
    - `closeOverviewFromPinch`
  - Change here for overview interaction behavior.

## Where To Change Common Requests
- Change main step content UI:
  - `lib/features/stage/parts/stage_step_content_section.dart`

- Change overview card UI:
  - `lib/features/stage/parts/stage_overview_page_builder.dart`

- Change swipe navigation behavior:
  - `lib/features/stage/parts/stage_step_screen_flow_helper.dart` (`nextStep`, `prevStep`, `handleHorizontalDragEnd`)

- Change autoplay behavior:
  - `lib/features/stage/parts/stage_audio_playback_helper.dart`

- Change additional surah replacement/fallback loading:
  - `lib/features/stage/parts/stage_additional_surah_helper.dart`

- Change overview zoom/pinch/pan behavior:
  - `lib/features/stage/parts/stage_overview_state_helper.dart`
  - `lib/features/stage/stage_overview_geometry.dart`

## Safe Editing Rules
- Keep `stage_step_screen_state.dart` as orchestration only.
- Put pure logic in helper files (no UI context when possible).
- Keep UI rendering in `parts/` widgets/builders.
- Run:
  - `dart format ...`
  - `flutter analyze ...`
  after any edits.
