---
name: Ganimedes Business & POS Engine
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#c4c5d7'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#8e90a0'
  outline-variant: '#434655'
  surface-tint: '#b7c4ff'
  primary: '#b7c4ff'
  on-primary: '#002682'
  primary-container: '#1d4ed8'
  on-primary-container: '#cad3ff'
  inverse-primary: '#2151da'
  secondary: '#4cd6fb'
  on-secondary: '#003642'
  secondary-container: '#00b2d6'
  on-secondary-container: '#003f4e'
  tertiary: '#b9c7e4'
  on-tertiary: '#233148'
  tertiary-container: '#4f5c75'
  on-tertiary-container: '#c7d5f3'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#dce1ff'
  primary-fixed-dim: '#b7c4ff'
  on-primary-fixed: '#001551'
  on-primary-fixed-variant: '#0039b5'
  secondary-fixed: '#b3ebff'
  secondary-fixed-dim: '#4cd6fb'
  on-secondary-fixed: '#001f27'
  on-secondary-fixed-variant: '#004e5f'
  tertiary-fixed: '#d6e3ff'
  tertiary-fixed-dim: '#b9c7e4'
  on-tertiary-fixed: '#0d1c32'
  on-tertiary-fixed-variant: '#39475f'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: 0em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style
The design system establishes a high-performance, crisp, and technologically advanced environment tailored for business management and fast-paced barber shop point-of-sale (POS) operations. The aesthetic marries high-contrast modern corporate precision with a sleek, cyber-geometric edge inspired by network nodes and structured data flows.

Primary emotional responses targeted:
- **Operational Confidence:** Immediate clarity and reliability during busy checkout rushes and chair scheduling.
- **Modern Craftsmanship:** Elevates barbering from traditional trade to an organized, high-end business service.
- **Speed & Fluency:** Fluid micro-interactions and tactile feedback optimized for mobile screens, POS terminals, and tablets.

The aesthetic direction integrates **Corporate Tech Modernism** with subtle **Neo-Digital Glass** accents: deep obsidian and navy canvas tones, electric cyan focal triggers, and pristine card surfaces defined by soft ambient elevation.

## Colors
The color architecture provides high contrast and visual hierarchy across light POS registers and dark administrative control dashboards.

### Core Swatches
- **Primary (`#1D4ED8`):** The primary interaction driver. Used for active navigation states, primary transaction buttons (e.g., "Cobrar", "Confirmar Cita"), and focal highlights.
- **Secondary / Accent (`#00B4D8`):** Dynamic electric cyan. Serves as the key feedback beacon—used for live status indicators, active stylist chair availability, progress bars, and glowing touchpoints.
- **Deep Navy Container (`#0A192F`):** Architectural foundation for persistent sidebars, modal backdrops, and navigation shells.
- **Neutral Deep / Dark Canvas (`#0F172A`):** The primary dark mode background surface. Paired with `#1E293B` for elevated surface cards.
- **Light Clean Canvas (`#F8FAFC`):** The default clean surface for bright retail counter setups and physical receipt printing previews.

### Functional Roles & Flutter Semantic Mapping
- **Surface Canvas (Dark):** `#0F172A` | **Surface Canvas (Light):** `#F8FAFC`
- **Surface Container (Dark):** `#1E293B` | **Surface Container (Light):** `#FFFFFF`
- **Border / Stroke Soft:** `rgba(255, 255, 255, 0.08)` in dark; `#E2E8F0` in light.
- **Success:** `#10B981` (Completed payments, active service)
- **Warning:** `#F59E0B` (Pending payouts, low barber supplies)
- **Destructive:** `#EF4444` (Canceled bookings, refunds)

## Typography
The system uses **Inter** across all typography scales to maximize legibility on high-density mobile screens and compact handheld POS terminals. 

Key principles:
- **Numeric Clarity:** Numbers in checkout balances, totals, and commission tables benefit from tabular numeric styling (`tnum`) to maintain vertical alignment during dynamic price recalculations.
- **Tight Headings:** Negative letter-spacing on headline scales gives an intentional, high-tech dashboard presence.
- **Micro-Labels:** Uppercase tracking applied sparingly to `label-sm` for category indicators (e.g., "CORTE", "BARBA", "PAGADO").

## Layout & Spacing
The layout model is driven by a flexible 8-point rhythmic grid tailored for touch-first handheld POS devices (5.5" to 6.7"), counter tablets (10" to 12.9"), and desktop admin portals.

### Breakpoint Strategy
- **Compact (Mobile & POS Handhelds: < 600px):** Single column stack. `margin: 1rem (16px)`, `gutter: 0.75rem (12px)`. Action sheets and sticky bottom interaction bars anchor primary actions (e.g., "Cobrar Total").
- **Medium (Tablet / POS Countertop: 600px - 1024px):** Dual-pane layout. Left pane dedicates 60% width to catalog & service selection; right pane fixes 40% width to active ticket/cart.
- **Expanded (Desktop / Web Admin: > 1024px):** Multi-column dashboard with collapsible navigation rail (`72px` collapsed, `240px` expanded).

All interactive tap targets adhere to a strict minimum hit dimension of `48x48px` to ensure effortless usability during fast-moving barber floor operations.

## Elevation & Depth
Elevation is achieved using balanced tonal layers coupled with diffuse ambient shadows rather than stark drop drops.

### Elevation Levels
- **Level 0 (Canvas):** Pure `#0F172A` in dark mode, `#F8FAFC` in light mode. Base level.
- **Level 1 (Card / Tile Default):** Surface `#1E293B` (dark) or `#FFFFFF` (light). Border: `1px solid rgba(255, 255, 255, 0.06)` or `1px solid #E2E8F0`. Shadow: `0px 4px 16px rgba(0, 0, 0, 0.12)`.
- **Level 2 (Active / Hover / Selected Service):** Surface with subtle cyan glow border `1px solid rgba(0, 180, 216, 0.4)`. Shadow: `0px 8px 24px rgba(0, 180, 216, 0.15)`.
- **Level 3 (Modals / Floating Bottom Sheets):** Deep glass layer with backdrop filter (`blur(16px)`), surface `#0A192F` with 90% opacity, shadow `0px 20px 40px rgba(0, 0, 0, 0.4)`.

## Shapes
A balanced geometric corner radius creates a tactile, modern feel without sacrificing enterprise density:
- **Base Components (Inputs, Buttons, Segmented Controls):** `12px` (equivalent to standard `rounded-xl`).
- **Surface Cards & Service Tiles:** `16px` to `20px` (equivalent to `rounded-2xl`).
- **Bottom Sheets & Modal Overlays:** Top corners `24px` radius for smooth slide-up gestures.
- **Pill Badges (Status / Role):** Fully rounded `9999px` for chips, status tags, and barber chair tags.

## Components

### Buttons
- **Primary:** Background `#1D4ED8`, text `#FFFFFF`, border-radius `12px`, height `48px` (mobile POS tap target). Pressed state scales to `0.98` with `#1A56DB`.
- **Accent / Pay Action:** Gradient from `#1D4ED8` to `#00B4D8`, white bold text, ambient cyan shadow. Used exclusively for checkout confirmation.
- **Secondary / Ghost:** Transparent surface with `1px solid rgba(255, 255, 255, 0.15)` (dark) or `#CBD5E1` (light). Text `#F8FAFC` or `#0F172A`.

### Service & Product POS Cards
- **Structure:** Vertical card with optional thumbnail, title (`label-lg`), service duration (`body-sm`), and bold price (`headline-sm`).
- **Interactive State:** Fast tap response (`InkWell` in Flutter). When selected, border transitions from neutral to cyan (`#00B4D8`) with an embedded checkmark badge on the top right.

### Input Fields & Search Bars
- **Style:** Filled surface (`#1E293B` in dark / `#FFFFFF` in light) with `1px` subtle outline.
- **Focus State:** Outline shifts to `#00B4D8` with `0 0 0 3px rgba(0, 180, 216, 0.2)` ring.
- **POS Search Bar:** Height `44px`, leading search icon in `#94A3B8`, trailing barcode/camera scanner icon for rapid inventory check.

### Status Chips & Badges
- **Available / Open:** Light emerald tint background with emerald text (`#10B981`).
- **In Service / Chair Occupied:** Electric cyan tint with `#00B4D8`.
- **Scheduled / Reserved:** Soft amber tint with `#F59E0B`.
- **Height & Radius:** Height `24px`, fully rounded pill (`9999px`), horizontal padding `10px`.

### Bottom Navigation & POS Floating Bar
- **Handheld Dock:** Frosted floating capsule dock hovering `12px` above screen bottom. Contains immediate shortcuts: *Terminal / Cobrar*, *Citas*, *Servicios*, and *Ajustes*. Active tab lit with cyan accent glow.