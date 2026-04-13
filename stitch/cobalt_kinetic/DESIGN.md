# Design System Document: The Kinetic Monolith

## 1. Overview & Creative North Star
**Creative North Star: "The Digital Athlete’s Atelier"**

This design system rejects the "boxed-in" utility of standard fitness trackers in favor of a high-end, editorial "OS" experience. It is designed to feel like a bespoke piece of high-performance equipment—think precision-milled graphite and illuminated glass. 

We move beyond the "template" look by embracing **Kinetic Depth**. Instead of flat grids, the UI utilizes a Z-axis approach where information sits on layered "shards" of varying translucency and tonal depth. By utilizing intentional asymmetry in layout and high-contrast typography scales, we create a rhythmic flow that mirrors the cadence of a professional workout: focused, powerful, and fluid.

---

## 2. Colors: Tonal Depth & Cobalt Energy
The palette is rooted in deep, obsidian neutrals to minimize eye strain and maximize the "pop" of data-heavy Cobalt accents.

### The Palette
*   **Base:** `background` (#0e0e0e) – The void. All elements emerge from here.
*   **Primary (Action):** `primary` (#85adff) to `primary_dim` (#0070eb) – Used for progression, active states, and high-energy CTAs.
*   **Surfaces:** `surface_container_low` (#131313) through `surface_container_highest` (#262626).

### The "No-Line" Rule
**Borders are strictly prohibited.** Do not use 1px solid lines to section off content. Boundaries must be defined through:
1.  **Background Shifts:** Placing a `surface_container_high` card against a `background` base.
2.  **Tonal Transitions:** Using subtle `surface_variant` shifts to suggest containment.
3.  **Negative Space:** Using the spacing scale to create "invisible" grouping.

### The "Glass & Gradient" Rule
To achieve a "Premium OS" feel, floating elements (modals, navigation bars) must use **Glassmorphism**.
*   **Recipe:** `surface_container` at 70% opacity + 20px Backdrop Blur.
*   **CTAs:** Use a subtle linear gradient from `primary_container` to `primary_dim` (at 135°) to give buttons a physical, rounded volume that flat colors lack.

---

## 3. Typography: Editorial Authority
We utilize a pairing of **Manrope** for expressive display and **Inter** for technical precision. 

*   **Display & Headlines (Manrope):** High-contrast weight usage. Use `display-lg` (Bold) for "hero" metrics (e.g., Heart Rate, Weight Lifted) to create an authoritative, "magazine" feel.
*   **Body & Labels (Inter):** Tight tracking and medium weights for readability at small sizes.
*   **Hierarchy Tip:** Never use color alone for hierarchy. Use the scale—pair a `headline-lg` value with a `label-sm` in `on_surface_variant` for a sophisticated, pro-tool data visualization.

---

## 4. Elevation & Depth: The Layering Principle
We do not use "drop shadows" in the traditional sense. We use **Tonal Layering**.

*   **Stacking:** A child element must always be "lighter" (higher tier) than its parent. 
    *   *Example:* A workout card (`surface_container_low`) contains a nested set-tracker (`surface_container_high`).
*   **Ambient Shadows:** For elevated elements (floating buttons), use a shadow color tinted with `surface_tint`.
    *   *Value:* `0px 20px 40px rgba(0, 0, 0, 0.4)` – The shadow should feel like ambient light being blocked, not a black smudge.
*   **The Ghost Border Fallback:** If accessibility requires a stroke, use `outline_variant` at **15% opacity**. It should be felt, not seen.

---

## 5. Components: Fluid Performance

### Buttons
*   **Primary:** `primary_fixed` background, `on_primary_fixed` text. Roundedness: `xl` (3rem/Pill).
*   **Secondary:** `surface_container_highest` background. No border.
*   **Interaction:** On press, scale the button to 96% to simulate a physical "click" into the glass.

### Cards & Lists
*   **Geometry:** Roundedness `lg` (2rem) for main cards; `md` (1.5rem) for nested items.
*   **No Dividers:** Lists are separated by 8px of vertical space or a `surface_container` shift. Forbid the use of horizontal rules.
*   **Progress Indicators:** Use a `primary` glow effect on progress bars to simulate energy.

### Input Fields
*   **Styling:** Instead of a box, use a `surface_container_low` pill.
*   **Focus:** Transition the background to `surface_bright` and add a subtle `primary` outer glow (4px blur).

### Specialized Fitness Components
*   **The Metric Shard:** A semi-transparent glass container for real-time data (e.g., Pace). Positioned asymmetrically to break the "grid" feel.
*   **Vitals Heatmap:** Using `tertiary` (#fab0ff) for recovery data and `primary` for exertion data to create a high-contrast visual story.

---

## 6. Do’s and Don’ts

### Do
*   **DO** use extreme vertical rhythm. Give elements "room to breathe" (32px+ margins).
*   **DO** use `display-lg` typography for single, impactful numbers.
*   **DO** layer glass panels over `primary` gradients for a sense of deep, liquid UI.

### Don’t
*   **DON’T** use pure white (#FFFFFF) for body text; use `on_surface_variant` (#adaaaa) to maintain the premium, moody atmosphere.
*   **DON’T** use hard-edged corners. Every touchpoint must feel "honed" and smooth.
*   **DON’T** use standard system icons. Use custom, thin-stroke (1.5pt) iconography to match the `outline` token weight.