# Home Marketplace Redesign

## Objective

Turn the consumer Home into a trustworthy automotive-services hub. From the first viewport, a user can launch any of the product's three core journeys in one tap:

1. Request a spare part.
2. Search workshops.
3. Search mechanics.

Below those entry points, Home surfaces the best-rated workshops and mechanics so discovery remains useful without competing with the three core actions.

## Approved Visual Direction

The approved reference is the final mockup from the 2026-08-12 design conversation, with these explicit decisions:

- Keep the orange header.
- Keep `Chats` in the bottom navigation; do not rename it to `Solicitudes`.
- Keep the official guIAutomotriz logo in the center of the bottom navigation.
- Raise the center logo roughly 10–12 dp above its previous position.
- Keep Hanken Grotesk and the existing brand palette from `DESIGN_SYSTEM.md`.

The visual language is "precision workshop / operational trust": cold-gray canvas, white surfaces, graphite text, orange for brand and direct action, cyan only for trust/location metadata, fine borders, and restrained shadows. The center logo is the single strong brand gesture; the rest of the screen remains quiet and systematic.

## Information Architecture

### Consumer Home

The vertical order is:

1. Orange header.
2. Heading: `¿Qué necesitas hoy?`.
3. Three equal direct-action cards.
4. `Talleres mejor valorados`.
5. `Mecánicos mejor valorados`.
6. Bottom navigation with `Inicio`, `Chats`, centered logo, `Compras`, and `Perfil`.

Promotional banners and the expanded `Mi garage` carousel are removed from the consumer Home's primary flow. The selected vehicle remains available as a compact control inside the header, which preserves vehicle context without pushing the core actions below the fold.

The existing store dashboard remains unchanged for store-role users. Role restrictions already encoded by `allowedServiceTypes` remain authoritative for provider roles; the three-action consumer layout applies when all three consumer actions are allowed.

## Header

The header uses `AppColors.primaryDark` (`#BF4704`) behind white text and icons. This preserves the requested orange identity while making the white foreground accessible; the current `AppColors.primary` (`#F25C05`) remains available for non-text accents.

The header contains:

- The current location-sharing control. Until reverse geocoding exists, its copy is honest state text (`Ubicación activada` or `Ubicación desactivada`) instead of a hard-coded street.
- The notification control only when it has an action; an inert bell is not rendered.
- Personalized copy formatted as `Hola, {nombre}` without the existing spacing error.
- A compact selected-vehicle control. It shows the selected search vehicle, otherwise the first garage vehicle, otherwise `Seleccionar vehículo`.
- Tapping the vehicle control opens the existing garage vehicle selector and updates `searchVehicleProvider` plus the selected variant identifier when present.

All header controls expose at least a 48 dp hit area and explicit semantics.

## Three Direct Actions

The action area is a responsive three-column row on normal phones. A `LayoutBuilder` reduces icon size, padding, and type slightly on narrow widths; it never requires horizontal scrolling. At large text scales the cards may grow vertically and labels wrap instead of clipping.

Each card has equal visual weight, an orange outline icon, a two-line verb label, and a visible arrow affordance:

- `Solicitar repuesto` opens the existing `SparePartWizardPage`.
- `Buscar talleres` navigates to `RouteNames.workshops`.
- `Buscar mecánicos` navigates to `RouteNames.mechanics`.

Cards use Material/Ink interaction feedback, 16–20 dp radius, a fine border, a minimum 48 dp touch target, and semantics that announce the destination. Press motion is subtle (150–200 ms) and disabled when `MediaQuery.disableAnimations` is true.

## Ranked Providers

Workshops appear before mechanics, matching the approved mockup. The section titles are:

- `Talleres mejor valorados`
- `Mecánicos mejor valorados`

Each section presents a compact preview rather than the full search result set. `Ver todos` remains a 48 dp action and navigates to the corresponding provider route. Provider cards retain real backend fields: name, photo or fallback icon, rating, review count, distance, open/closed state, and specialty/detail.

Ranking is deterministic:

1. Higher rating first.
2. For equal ratings, more reviews first.
3. For equal rating and review count, shorter distance first.

The Home shows up to three providers per section. Loading shows reserved skeleton cards, empty shows a compact explanatory state with `Ver todos`, and error shows a human message plus `Reintentar`; raw exceptions are never shown.

## Bottom Navigation

Consumer navigation keeps the current tab mapping and behavior:

- Index 0: `Inicio`.
- Index 1: `Chats`.
- Center official logo: also returns to index 0.
- Index 2: `Compras`.
- Index 3: `Perfil`.

The official `assets/images/logo_icon.png` is used without recoloring or distortion. The logo's visual diameter is reduced from the current oversized 88 dp treatment to approximately 64 dp and positioned so its center sits 10–12 dp higher than the approved second mockup. The bar reserves its space, respects bottom safe area, and content receives sufficient bottom inset.

`Inicio` remains a labeled destination even though the center logo also returns Home, because the user explicitly approved both. Semantics distinguish them as `Inicio` and `Volver al inicio, logo guIAutomotriz`. Navigation remains at five visible positions.

For store accounts, the existing role-specific omission of purchases remains intact; spacers preserve the centered logo without changing the store's tab indices.

## Data and State Flow

- Authentication continues to provide the greeting and role.
- `userCarsProvider` supplies garage vehicles.
- `searchVehicleProvider` stores the Home-selected vehicle shared with search flows.
- The existing category callbacks and named routes launch the three journeys.
- `topProvidersProvider` consumes existing provider results and applies the ranking rules locally.
- Each provider section independently renders loading, empty, error, and data states.

No new backend endpoint or dependency is required.

## Accessibility and Adaptation

- Normal text contrast is at least 4.5:1; meaningful UI glyphs meet at least 3:1.
- White header text is placed on `AppColors.primaryDark`, not the lighter primary orange.
- Interactive controls are at least 48×48 dp.
- All icon-only actions receive semantic labels.
- Text wraps at 1.3× and 2.0× scaling without hiding an action.
- Layout is checked at 375 dp and 430 dp widths, plus representative landscape/tablet constraints.
- Top and bottom safe areas are respected.
- Motion is limited to 150–200 ms press/selection feedback and disabled when reduced motion is requested.
- Loading placeholders reserve space; error and empty states always provide a next action.

## Testing Strategy

Widget tests will cover:

- All three Home action labels render for a consumer.
- Tapping workshops and mechanics invokes their respective routes.
- Tapping spare parts launches the existing wizard.
- Provider ranking uses rating, then review count, then distance.
- Provider sections render loading, empty, error with retry, and data states.
- The bottom navigation exposes `Inicio`, `Chats`, `Compras`, `Perfil`, and the center-logo semantics with the existing index mapping.
- The layout has no overflow at 375 dp and 430 dp widths with text scale 1.0, 1.3, and 2.0.
- Reduced-motion and safe-area configurations build without exceptions.

Static validation includes `dart format`, `flutter analyze`, focused widget/unit tests, and the complete Flutter test suite. A final visual pass compares the implemented Home to the approved mockup.

## Out of Scope

- Changing backend ranking endpoints.
- Adding reverse-geocoding or a notifications screen.
- Refactoring the app into routed shell tabs.
- Redesigning workshops/mechanics list pages, chat pages, purchase pages, profile, or the store dashboard.
- Adding dark mode.
