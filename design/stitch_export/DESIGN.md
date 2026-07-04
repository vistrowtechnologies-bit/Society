---
name: SocietyOS
colors:
  surface: '#f9f9f7'
  surface-dim: '#dadad8'
  surface-bright: '#f9f9f7'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f4f2'
  surface-container: '#eeeeec'
  surface-container-high: '#e8e8e6'
  surface-container-highest: '#e2e3e1'
  on-surface: '#1a1c1b'
  on-surface-variant: '#47464f'
  inverse-surface: '#2f3130'
  inverse-on-surface: '#f1f1ef'
  outline: '#787681'
  outline-variant: '#c8c5d1'
  surface-tint: '#5b5795'
  primary: '#110847'
  on-primary: '#ffffff'
  primary-container: '#26215c'
  on-primary-container: '#8e8acb'
  inverse-primary: '#c5c0ff'
  secondary: '#835400'
  on-secondary: '#ffffff'
  secondary-container: '#fdb244'
  on-secondary-container: '#6e4600'
  tertiary: '#001a06'
  on-tertiary: '#ffffff'
  tertiary-container: '#003110'
  on-tertiary-container: '#1ca64c'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e3dfff'
  primary-fixed-dim: '#c5c0ff'
  on-primary-fixed: '#17114d'
  on-primary-fixed-variant: '#443f7b'
  secondary-fixed: '#ffddb5'
  secondary-fixed-dim: '#ffb956'
  on-secondary-fixed: '#2a1800'
  on-secondary-fixed-variant: '#633f00'
  tertiary-fixed: '#7ffc97'
  tertiary-fixed-dim: '#62df7d'
  on-tertiary-fixed: '#002109'
  on-tertiary-fixed-variant: '#005320'
  background: '#f9f9f7'
  on-background: '#1a1c1b'
  surface-variant: '#e2e3e1'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 64px
---

## Brand & Style
The design system for this community-centric application is built on a foundation of clarity, reliability, and modern efficiency. It targets residents and administrators of contemporary Indian housing societies who require a tool that feels both authoritative and approachable.

The aesthetic follows a **Refined Flat Design** philosophy with strong influences from **Material 3**. It prioritizes functional minimalism over decorative flourishes, utilizing generous whitespace and a strict 4px grid system to ensure high legibility and ease of navigation. The visual tone is professional and orderly, avoiding gradients and heavy shadows in favor of crisp borders and flat tonal shifts to signify depth.

## Colors
This design system utilizes a structured, high-contrast palette to drive user action and maintain organizational hierarchy.

- **Primary (Deep Indigo):** Reserved for core structural elements like App Bars, primary action buttons, and active navigation states. It represents the "OS" aspect of the app—stability and infrastructure.
- **Accent (Warm Amber):** Specifically designated for high-priority transaction triggers such as "Pay now" and key feature highlights.
- **Surface & Background:** The background uses a soft off-white to reduce eye strain, while white cards with a subtle 0.5px border create clear containment without needing shadows.
- **Semantic Colors:** Green, amber, and red are strictly mapped to payment and maintenance statuses (Paid, Due Soon, Overdue) to ensure instant visual recognition of urgency.

## Typography
The system uses **Inter** for its neutral, highly legible characteristics. To ensure a modern and friendly tone, all UI text—including headlines, labels, and buttons—must follow **sentence-case** formatting (e.g., "Pay maintenance" instead of "PAY MAINTENANCE").

- **Hierarchy:** Use `display-lg` for dashboard summaries (e.g., total dues amount). Use `headline-sm` for card titles.
- **Clarity:** `label-md` is optimized for secondary metadata such as timestamps or unit numbers.
- **Responsive:** Headlines scale down on mobile to maintain vertical rhythm while preventing awkward line breaks in multi-word society names.

## Layout & Spacing
The layout follows a **fluid grid** model optimized for mobile-first usage. 

- **Grid:** On mobile, use a 4-column grid with 16px margins. On desktop, a 12-column grid with a maximum content width of 1200px.
- **Rhythm:** Spacing should always be a multiple of 4px. Use 16px (`md`) for standard padding within cards and 24px (`lg`) to separate distinct logical sections on a page.
- **Density:** Maintain generous whitespace between cards to emphasize the flat design's "airiness" and prevent the UI from feeling cluttered with data.

## Elevation & Depth
In line with the flat design requirement, this system avoids traditional shadows. Depth is communicated through **Tonal Layers and Outlines**:

- **Level 0 (Background):** #F7F7F5.
- **Level 1 (Cards/Surfaces):** #FFFFFF. These are separated from the background by a **0.5px border** (#E5E4DF) rather than a shadow.
- **Active States:** Elements being pressed or interacted with may use a subtle 4% opacity black overlay or a primary-colored hair-line stroke.
- **Floating Actions:** If a Floating Action Button (FAB) is required, use a very soft, high-diffusion shadow (8% opacity) to provide just enough lift to signify it sits above the scrollable content.

## Shapes
The visual language is defined by a consistent **12px (0.75rem) corner radius** for all major UI components including cards, buttons, and input fields.

- **Small Components:** Tags and chips use a 4px radius for a sharper, more technical feel.
- **Selection:** Checkboxes use a 4px radius, while radio buttons remain fully circular to adhere to standard platform conventions.

## Components
Consistent styling across the application is governed by the following rules:

- **Buttons:** 
  - *Primary:* Filled with #26215C, white text, 12px rounded corners.
  - *Accent (Pay Now):* Filled with #F2A93B, #1A1A2E text.
  - *Secondary:* Ghost style with 0.5px #E5E4DF border and #1A1A2E text.
- **Input Fields:** Material 3 "Outlined" style. 0.5px #E5E4DF border that transitions to a 1.5px #26215C border on focus. Labels should be small and sentence-case.
- **Bottom Navigation:** Solid #FFFFFF background with #26215C for active icons/labels and #9B9AA5 for inactive. Active state is indicated by the icon color change and a subtle pill-shaped background highlight if following full Material 3 spec.
- **Cards:** White background, 12px rounded corners, 0.5px #E5E4DF border. No shadow.
- **Status Badges:** Small chips with 4px rounded corners. Text is always sentence-case (e.g., "Due soon"). Use the semantic colors (Success, Warning, Danger) with a 10% opacity background fill and a 100% opacity text color.
- **Lists:** Clean rows with a 0.5px bottom divider. Ensure a minimum touch target height of 48px for all list items.