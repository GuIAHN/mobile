# Floating Bottom Navigation Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the current full-width bottom navigation with a subtle floating capsule inspired by the approved reference, preserving the centered guIAutomotriz logo and every existing role/tab mapping.

**Architecture:** Keep `BottomNavBar` as the Riverpod integration boundary and contain the visual behavior in private navigation widgets. The surface becomes a safe-area-aware rounded capsule; each side destination owns a fixed circular icon stage that animates vertically when selected; the center logo stays geometrically stable and only reacts to direct press.

**Tech Stack:** Flutter, Riverpod, Material, Google Fonts, flutter_test.

---

### Task 1: Lock the approved behavior with widget tests

**Files:**
- Modify: `test/features/home/presentation/widgets/bottom_nav_bar_test.dart`

- [ ] Replace stale 88 dp/full-width surface expectations with the approved 58 dp stable logo and 14 dp floating margins.
- [ ] Assert the selected side destination is visually elevated while inactive destinations remain aligned.
- [ ] Preserve consumer/store index mapping, center-logo home action, semantics, 48 dp targets, safe-area behavior, and representative phone-width coverage.
- [ ] At 2× text, assert no Flutter layout errors and that labels remain inside their destination, allowing intentional one-line ellipsis.
- [ ] Run the focused test and confirm the new visual assertions fail before implementation.

### Task 2: Build the floating capsule and micro-interactions

**Files:**
- Modify: `lib/features/home/presentation/widgets/navigation/bottom_nav_bar.dart`

- [ ] Add a white capsule with 14 dp horizontal margin, 8 dp bottom separation, 28 dp radius, design-system border, and restrained shadow.
- [ ] Use a fixed 48 dp icon stage; selected destinations receive a muted-orange circular background, orange filled icon, and a 6 dp upward motion.
- [ ] Keep inactive icons neutral and labels compact; selected labels use orange w800 and all labels use one-line ellipsis.
- [ ] Enlarge the center logo to 58 dp, lift it 12 dp, remove selection-dependent scaling/borders, and retain a white ring with subtle orange shadow.
- [ ] Add 0.97 press feedback and 220 ms `easeOutCubic` selection motion; use zero durations when reduced motion is enabled.
- [ ] Keep safe-area and public content-inset calculations synchronized with the actual opaque surface.
- [ ] Run the focused widget suite until green.

### Task 3: Final verification and isolated commit

**Files:**
- Verify: `lib/features/home/presentation/widgets/navigation/bottom_nav_bar.dart`
- Verify: `test/features/home/presentation/widgets/bottom_nav_bar_test.dart`

- [ ] Format only the files changed for this navigation task.
- [ ] Run `flutter analyze` for the component and test.
- [ ] Run the focused widget suite and broader relevant home tests once, at the end.
- [ ] Review the diff to ensure no backend, route, provider, or unrelated dirty file changed.
- [ ] Commit only the navigation implementation, its tests, and this plan.
