---
name: SocietyOS Admin
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
  title-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
  display-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  rail-width: 240px
  container-max: 1440px
  gutter: 16px
---

## Brand & Style

The design system is engineered for the administrative backbone of residential communities. It balances the gravity of financial and legal management with the accessibility required for daily operational tasks. The aesthetic is **Corporate Modern with a "Soft-Professional" touch**: clean, high-density, and structured, yet approachable through subtle rounding and a warm neutral background.

The target audience is housing society secretaries and estate managers who require high data density without cognitive overload. The UI prioritizes clarity, reliability, and "at-a-glance" status reporting, utilizing a card-based architecture to compartmentalize complex information sets like billing, maintenance requests, and resident directories.

## Colors

The palette is anchored by a deep Indigo primary color to project authority and trust. The Amber accent is used sparingly for primary actions and highlights to guide the eye toward "pending" tasks or critical updates.

- **Primary (#26215C):** Used for navigation rails, primary buttons, and headers.
- **Accent (#F2A93B):** Reserved for high-priority calls to action and "Action Required" states.
- **Background (#F7F7F5):** A slightly warm off-white to reduce eye strain during long administrative sessions.
- **Surface (#FFFFFF):** All cards and data containers use pure white to pop against the background.
- **Semantic Colors:** Green (Success), Amber (Warning), and Red (Danger) follow standard utility patterns for status badges and financial health indicators.

## Typography

The design system utilizes **Inter** for its exceptional legibility in data-heavy environments. The typographic scale is optimized for high information density.

- **Headlines:** Use Semi-Bold (600) or Bold (700) with slight negative letter-spacing to maintain a compact, professional look.
- **Body:** The standard size is 14px (`body-sm`) for table data and 16px (`body-md`) for general reading.
- **Labels:** Uppercase labels with increased tracking (0.05em) are used for table headers and section overlines to distinguish them from interactive data.
- **Data Display:** Numerical values in metric cards should use `headline-md` for maximum visibility.

## Layout & Spacing

This design system uses a **Fluid-Fixed Hybrid Grid**. The navigation rail remains fixed on the left (desktop), while the content area expands to a maximum width of 1440px.

- **Grid:** 12-column system for desktop, 4-column for mobile.
- **Margins:** 24px (Desktop), 16px (Mobile).
- **Rhythm:** An 8px linear scale (4, 8, 16, 24, 32, 48, 64) governs all padding and margins. 
- **Reflow:** On mobile, the left rail disappears in favor of a bottom navigation bar for primary modules (Home, Billing, Complaints, Chat).

## Elevation & Depth

To maintain a "Flat-Card" professional aesthetic, the design system avoids heavy shadows and instead uses **Tonal Layering and Low-Contrast Outlines**.

- **Level 0 (Background):** Surface color #F7F7F5. No elevation.
- **Level 1 (Cards/Tables):** Surface color #FFFFFF. A 1px solid border (#E5E7EB) is the primary separator. A very soft, large-radius ambient shadow (Y: 2px, Blur: 4px, Opacity: 4%) may be used to distinguish cards from the background.
- **Level 2 (Dropdowns/Modals):** These use a more distinct shadow to indicate temporary overlay status (Y: 10px, Blur: 20px, Opacity: 8%).

## Shapes

The design system employs a **Soft** shape language. This provides a modern, approachable feel while maintaining the structural rigidity expected of a management console.

- **Base (0.25rem / 4px):** Used for small elements like checkboxes, input fields, and small badges.
- **Large (0.5rem / 8px):** The standard for cards, metric blocks, and buttons.
- **XL (0.75rem / 12px):** Reserved for large modal containers and empty-state illustrations.

## Components

### Navigation Rail (Desktop)
A fixed 240px width sidebar using the Primary color (#26215C) for the background. Active states use a solid Amber left-border (4px) and a subtle background highlight.

### Metric Cards
White background, 8px rounded corners, 1px border. Feature a large `headline-md` value, a `label-md` title, and a small trend indicator (e.g., "+2% vs last month") using Success or Danger colors.

### Tables
Dense, clean tables with no vertical lines. Horizontal lines are 1px #F3F4F6. Headers are `label-md` with a subtle grey background. Row hover state: #F9FAFB.

### Buttons
- **Primary:** Solid #26215C with white text. 8px rounded.
- **Secondary:** Outlined 1px #26215C.
- **Accent:** Solid #F2A93B with white text (for urgent actions like "Post Announcement").

### Status Badges
Small, pill-shaped tags.
- **Pending:** Light Amber background with dark Amber text.
- **Paid/Resolved:** Light Green background with dark Green text.
- **Overdue:** Light Red background with dark Red text.

### Chat Interfaces
Left-aligned (others) and right-aligned (user) bubbles. User bubbles use Primary (#26215C), others use a light grey (#F3F4F6). Bubbles use 8px rounding, with the tail corner sharpened to 2px.

### Input Fields
1px border #D1D5DB, 4px rounding. On focus, the border changes to Primary (#26215C) with a subtle 2px glow of the same color at 10% opacity.