# FamilyCal Authentication - Design Specification

## 🎨 Visual Design System

### Color Palette
```
Primary: #1A73E8 (Google Blue)
├─ Primary Container: Lighter shade for backgrounds
├─ On Primary: White text on primary
└─ Primary Variant: Darker shade for emphasis

Secondary: Auto-generated from Material 3
├─ Secondary Container: Alternative highlights
└─ On Secondary: Text on secondary

Surface Colors:
├─ Surface: White (#FFFFFF)
├─ Surface Variant: Light gray backgrounds
└─ On Surface Variant: Secondary text (#757575)

Semantic Colors:
├─ Error: Material error red
└─ Success: Material green
```

### Typography Scale

```
Display Small (Headlines)
├─ Size: 32px
├─ Weight: Bold (700)
├─ Line Height: 1.2
└─ Use: Screen titles

Title Medium (Subheadings)
├─ Size: 18px
├─ Weight: Semi-bold (600)
├─ Line Height: 1.4
└─ Use: Subtitles, section headers

Body Large (Primary Content)
├─ Size: 16px
├─ Weight: Regular (400)
├─ Line Height: 1.5
└─ Use: Main body text, input labels

Body Medium (Secondary Content)
├─ Size: 14px
├─ Weight: Regular (400)
├─ Line Height: 1.4
└─ Use: Helper text, captions

Body Small (Tertiary Content)
├─ Size: 12px
├─ Weight: Regular (400)
├─ Line Height: 1.3
└─ Use: Fine print, terms
```

### Spacing System

```
Micro:   4px  - Icon spacing, tight elements
Small:   8px  - Related content spacing
Medium:  12px - Card padding, list spacing
Default: 16px - Standard spacing unit
Large:   20px - Form field spacing
XLarge:  24px - Screen padding, section spacing
XXLarge: 32px - Major section breaks
Hero:    40px - Top-level spacing
Jumbo:   48px - Maximum spacing
```

### Border Radius

```
Small:  8px  - Chips, tags
Medium: 12px - Small containers, icons
Large:  16px - Buttons, inputs, cards
XLarge: 24px - Hero containers
Round:  32px - Full rounded (app icon)
```

---

## 📱 Screen Breakdowns

### Welcome Screen

#### Layout Structure
```
┌─────────────────────────┐
│      [App Icon]         │  120x120px rounded container
│                         │
│     FamilyCal          │  Display Small, bold
│                         │
│  Your family schedule,  │  Title Medium
│   all in one place      │
│                         │
│  [📅] Sync events...    │  Benefit item 1
│                         │
│  [🔔] Never miss...     │  Benefit item 2
│                         │
│  [👨‍👩‍👧‍👦] Coordinate...  │  Benefit item 3
│                         │
│   [Get Started]         │  Filled Button (primary)
│   [Sign In]             │  Outlined Button (secondary)
└─────────────────────────┘
```

#### Interactive States
- **Get Started Button**
  - Default: Primary color fill
  - Hover: Slightly darker
  - Pressed: Darker + scale 0.98
  - Disabled: Grayed out (N/A here)

- **Sign In Button**
  - Default: Primary color outline
  - Hover: Light background tint
  - Pressed: Darker tint + scale 0.98

#### Animations
- Fade in on load (300ms)
- Button press: Scale animation
- Slide transition to next screen

---

### Login Screen

#### Layout Structure
```
┌─────────────────────────┐
│  [←]                    │  Back button
│                         │
│  Welcome back          │  Display Small
│  Sign in to continue   │  Body Large (gray)
│                         │
│  [Email | Phone]        │  Segmented Button
│                         │
│  ┌─────────────────┐   │
│  │ 📧 Email...     │   │  Text input
│  └─────────────────┘   │
│                         │
│  ┌─────────────────┐   │
│  │ 🔒 Password     │ 👁 │  Password input + toggle
│  └─────────────────┘   │
│                         │
│      Forgot password?   │  Text button (right aligned)
│                         │
│   [Sign In]             │  Filled button
│                         │
│   ──────  OR  ──────    │  Divider with text
│                         │
│   [🔗 Send magic link]  │  Outlined button
│                         │
│  Don't have account?    │  Text + Link
│      Sign Up            │
└─────────────────────────┘
```

#### Form Validation States

**Default State:**
- Border: Light gray outline
- Background: Transparent
- Label: Gray color, raised position

**Focus State:**
- Border: Primary color, 2px
- Background: Very light primary tint
- Label: Primary color

**Error State:**
- Border: Error red, 2px
- Background: Light error tint
- Helper text: Error message in red
- Icon: Error icon

**Success State:**
- Border: Success green
- Icon: Checkmark (optional)

#### Input Field Specifications

```dart
TextFormField Style:
├─ Height: 56px (minimum touch target)
├─ Border Radius: 16px
├─ Horizontal Padding: 16px
├─ Font Size: 16px (prevents zoom on iOS)
├─ Label: Floating, animates on focus
└─ Icons: 24px, positioned 12px from edge
```

---

### Register Screen

#### 3-Step Flow Structure

**Progress Indicator:**
```
┌─────────────────────────┐
│ [████████────────] 1/3  │  Linear progress (6px height)
└─────────────────────────┘
```

#### Step 1: Account Setup
```
┌─────────────────────────┐
│ [Progress: 1/3]         │
│                         │
│  Create your account    │  Display Small
│  Let's start by...      │  Body Large (gray)
│                         │
│  ┌─────────────────┐   │
│  │ 👤 Name         │   │  Text input
│  └─────────────────┘   │
│                         │
│  [Email | Phone]        │  Segmented Button
│                         │
│  ┌─────────────────┐   │
│  │ 📧 Email...     │   │  Text input
│  └─────────────────┘   │
│                         │
│  ┌─────────────────┐   │
│  │ 🔒 Password     │ 👁 │  Password input
│  └─────────────────┘   │
│                         │
│  ┌─────────────────┐   │
│  │ 🔒 Confirm...   │ 👁 │  Password confirm
│  └─────────────────┘   │
│                         │
│   [Continue]            │  Filled button
│                         │
│  Already have account?  │  Text + Link
│      Sign In            │
└─────────────────────────┘
```

#### Step 2: Family Setup
```
┌─────────────────────────┐
│ [Progress: 2/3]         │
│                         │
│  Create your family     │  Display Small
│  Give your family...    │  Body Large (gray)
│                         │
│  ┌─────────────────┐   │
│  │                 │   │
│  │     👨‍👩‍👧‍👦       │   │  Large illustration
│  │                 │   │  200px height
│  └─────────────────┘   │
│                         │
│  ┌─────────────────┐   │
│  │ 🏠 Family name  │   │  Text input
│  └─────────────────┘   │
│                         │
│   [Continue]            │  Filled button
│   [Skip for now]        │  Outlined button
└─────────────────────────┘
```

#### Step 3: Children (Optional)
```
┌─────────────────────────┐
│ [Progress: 3/3]         │
│                         │
│  Add your children      │  Display Small
│  You can add them...    │  Body Large (gray)
│                         │
│  ┌─────────────────┐   │
│  │                 │   │
│  │      👶         │   │  Large illustration
│  │                 │   │  200px height
│  └─────────────────┘   │
│                         │
│  ┌─────────────────┐   │
│  │   ℹ️  Info Card  │   │  Info container
│  │                 │   │  Explains next steps
│  │  You'll be able │   │
│  │  to add...      │   │
│  └─────────────────┘   │
│                         │
│   [Create Account]      │  Filled button
│                         │
│  Terms & Privacy text   │  Small gray text
└─────────────────────────┘
```

---

## 🎭 Interaction Design

### Button States

**Filled Button (Primary Action)**
```
Default:
├─ Background: Primary color
├─ Text: White
├─ Shadow: Elevation 0
└─ Border Radius: 16px

Hover (Web):
├─ Background: 8% darker
└─ Cursor: Pointer

Pressed:
├─ Background: 12% darker
├─ Scale: 0.98
└─ Duration: 100ms

Loading:
├─ Background: Primary (maintained)
├─ Content: 24px CircularProgressIndicator
└─ User action: Disabled

Disabled:
├─ Background: Gray 300
├─ Text: Gray 500
└─ Cursor: Not-allowed
```

**Outlined Button (Secondary Action)**
```
Default:
├─ Background: Transparent
├─ Border: 1.5px primary color
├─ Text: Primary color
└─ Border Radius: 16px

Hover:
├─ Background: Primary 5% opacity
└─ Border: Primary color

Pressed:
├─ Background: Primary 10% opacity
├─ Scale: 0.98
└─ Duration: 100ms
```

### Input Field Interactions

**Focus Sequence:**
1. User taps field
2. Border animates to primary (150ms)
3. Label animates up and scales (150ms)
4. Keyboard appears (system)
5. Background tint fades in (200ms)

**Validation Timing:**
- On blur (field loses focus)
- On submit attempt
- Never on typing (not intrusive)

**Error Display:**
1. Border changes to error red (200ms)
2. Helper text appears below (fade in 150ms)
3. Optional shake animation (300ms)

---

## ♿ Accessibility

### Touch Targets
- Minimum: 48x48 dp (Android guideline)
- Implemented: 56px height for all interactive elements
- Spacing: 8px minimum between targets

### Color Contrast
- Body text: 4.5:1 minimum (WCAG AA)
- Large text: 3:1 minimum
- Icons: 3:1 minimum
- All combinations tested

### Screen Reader Support
- Semantic HTML elements
- ARIA labels where needed
- Proper heading hierarchy
- Form labels associated with inputs
- Error messages announced

### Keyboard Navigation
- Tab order follows visual flow
- Enter submits forms
- Escape closes dialogs
- Visual focus indicators

---

## 📐 Responsive Design

### Breakpoints
```
Mobile:  < 600px  (Single column, full width)
Tablet:  600-900px (Centered with max-width)
Desktop: > 900px   (Centered with max-width 600px)
```

### Mobile Optimizations
- Input font size: 16px (prevents iOS zoom)
- Touch targets: 56px height
- Horizontal padding: 24px
- Bottom navigation safe area

### Tablet Optimizations
- Max content width: 600px centered
- Increased spacing
- Larger illustrations

---

## 🎬 Animations

### Page Transitions
```dart
Duration: 300ms
Curve: easeInOut
Type: Slide from right (forward)
      Slide from left (back)
```

### Button Press
```dart
Duration: 100ms
Scale: 0.98
Curve: easeOut
```

### Form Field Focus
```dart
Border animation: 150ms easeInOut
Label animation: 150ms easeInOut
Background tint: 200ms easeIn
```

### Loading States
```dart
Spinner: Continuous rotation
Duration: 1000ms per rotation
Curve: Linear
Size: 24px
```

---

## 🔒 Security UX

### Password Fields
- Always masked by default
- Toggle visibility button (eye icon)
- Never auto-complete on first visit
- Secure text entry mode

### Biometric Prompt (Future)
- System native dialog
- Fallback to password
- Clear messaging

### Error Messages
- Generic for security (e.g., "Invalid credentials")
- Never reveal if email exists
- Rate limiting handled gracefully

---

## 📊 Performance

### Loading States
- Show immediately (<100ms)
- Maintain UI structure (no layout shift)
- Clear indication of progress

### Image Loading
- Illustrations: Load with fade in
- Placeholder: Colored container
- Error state: Icon fallback

### Form Submission
- Optimistic UI where possible
- Clear success/error feedback
- Prevent double submission

---

## 🌍 Internationalization Ready

### Text
- All strings extractable
- RTL layout support considered
- Dynamic text sizing

### Inputs
- Locale-specific keyboards
- Date/phone formats
- Validation rules per locale

---

## 📝 Microcopy Guide

### Tone: Friendly, Clear, Supportive

**Headlines:**
- Action-oriented
- Clear benefit
- 2-5 words when possible

**Body Text:**
- Conversational
- Explain "why"
- One key point per paragraph

**Button Labels:**
- Verb + Object
- "Sign In" not "Submit"
- "Create Account" not "Register"

**Error Messages:**
- What happened
- Why it happened (if helpful)
- How to fix it

**Examples:**
✅ "Welcome back" (friendly)
❌ "Login" (cold)

✅ "Please enter your email"
❌ "Email required"

✅ "Password must be at least 6 characters"
❌ "Invalid password"

---

This design system ensures consistency, accessibility, and delightful user experience across all authentication flows.

