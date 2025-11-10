# FamilyCal - Authentication Design Specification

## Visual Design System

### 🎨 Color Palette

```
Primary Colors:
├─ Primary:              #1A73E8 (Blue)
├─ Primary Container:    #D3E3FD (Light Blue)
└─ On Primary:           #FFFFFF (White)

Surface Colors:
├─ Surface:              #FFFFFF (White)
├─ Surface Variant:      #F5F5F5 (Light Gray)
└─ On Surface:           #1C1B1F (Near Black)

Feedback Colors:
├─ Success:              #2E7D32 (Green)
├─ Error:                #D32F2F (Red)
└─ Warning:              #F57C00 (Orange)

Text Colors:
├─ High Emphasis:        #1C1B1F (87% opacity)
├─ Medium Emphasis:      #49454F (60% opacity)
└─ Disabled:             #1C1B1F (38% opacity)
```

---

### 📐 Layout & Spacing

```
Screen Padding:          24dp
Section Spacing:         32dp
Element Spacing:         16dp
Tight Spacing:           8dp
Component Spacing:       4dp

Border Radius:
├─ Small (chips):        8dp
├─ Medium (inputs):      12dp
├─ Large (cards):        16dp
└─ Extra Large (icon):   32dp

Elevation:
├─ Level 0 (flat):       0dp
├─ Level 1 (raised):     2dp
└─ Level 2 (modal):      8dp
```

---

### 🔤 Typography Scale

```
Display Small:
├─ Size:                 36sp
├─ Weight:               Bold (700)
└─ Use:                  App name, hero titles

Headline Medium:
├─ Size:                 28sp
├─ Weight:               Bold (700)
└─ Use:                  Screen titles

Headline Small:
├─ Size:                 24sp
├─ Weight:               SemiBold (600)
└─ Use:                  Section headers

Body Large:
├─ Size:                 16sp
├─ Weight:               Regular (400)
└─ Use:                  Descriptions, labels

Body Medium:
├─ Size:                 14sp
├─ Weight:               Regular (400)
└─ Use:                  Supporting text

Body Small:
├─ Size:                 12sp
├─ Weight:               Regular (400)
└─ Use:                  Captions, disclaimers

Button:
├─ Size:                 16sp
├─ Weight:               SemiBold (600)
└─ Use:                  All buttons
```

---

### 🎯 Component Specifications

#### Buttons

**Primary Button (FilledButton)**
```
Height:                  56dp
Width:                   match_parent or wrap_content
Padding Horizontal:      24dp
Padding Vertical:        16dp
Background:              Primary color
Text Color:              On Primary
Border Radius:           12dp
Font:                    Button style
Shadow:                  Elevation 2dp
States:
├─ Default:              Primary background
├─ Hovered:              10% darker
├─ Pressed:              20% darker
└─ Disabled:             38% opacity
```

**Secondary Button (OutlinedButton)**
```
Height:                  56dp
Width:                   match_parent or wrap_content
Padding:                 Same as Primary
Background:              Transparent
Text Color:              Primary
Border:                  1.5dp Primary color
Border Radius:           12dp
States:
├─ Default:              Outlined
├─ Hovered:              5% primary tint
├─ Pressed:              10% primary tint
└─ Disabled:             38% opacity
```

**Text Button (TextButton)**
```
Height:                  48dp
Padding Horizontal:      16dp
Background:              Transparent
Text Color:              Primary
No Border
States:
├─ Default:              Primary text
├─ Hovered:              5% primary tint
├─ Pressed:              10% primary tint
└─ Disabled:             38% opacity
```

---

#### Input Fields (TextFormField)

```
Height:                  56dp
Width:                   match_parent
Padding Horizontal:      16dp
Padding Vertical:        16dp
Border:                  1dp outline color
Border Radius:           12dp
Label Position:          Floating above when focused
Icon Size:               24dp
Icon Padding:            12dp

States:
├─ Default:              Outline color
├─ Focused:              Primary color, 2dp border
├─ Error:                Error color, helper text
└─ Disabled:             38% opacity

Icon Prefix:
├─ Position:             Start, 12dp from edge
├─ Size:                 24dp
└─ Color:                Medium emphasis

Label:
├─ Unfocused:            Inside field, medium emphasis
├─ Focused:              Above field, primary color, small
└─ Error:                Error color
```

---

#### Info Boxes

```
Width:                   match_parent
Padding:                 16dp all sides
Background:              Primary container (50% opacity)
Border:                  1dp Primary (20% opacity)
Border Radius:           12dp
Icon Size:               20dp
Icon Color:              Primary
Text:                    Body small, on-surface color
Spacing:                 12dp between icon and text
```

---

#### Segmented Button

```
Height:                  48dp
Segment Min Width:       120dp
Background:              Surface variant (30% opacity)
Border Radius:           12dp
Selected Background:     Primary (12% opacity)
Selected Border:         None
Text:                    Button style
Icon Size:               20dp
Icon-Text Spacing:       8dp
```

---

#### OTP Input Boxes

```
Size:                    48dp × 56dp
Border:                  1dp outline
Border Radius:           12dp
Background:              Surface
Text:                    Headline small, bold, centered
Spacing Between:         8-12dp

States:
├─ Empty:                Outline color
├─ Focused:              Primary color, 2dp border
├─ Filled:               Primary color border
└─ Error:                Error color border
```

---

### 📱 Screen Layouts

#### Welcome Screen
```
┌─────────────────────────┐
│                         │
│      [Spacer 2x]        │
│                         │
│    ┌─────────────┐      │
│    │   App Icon  │      │ 120×120dp, rounded 32dp
│    └─────────────┘      │
│                         │
│      FamilyCal          │ Display Small
│                         │
│   Coordinate family     │ Body Large, centered
│   schedules. Never      │ 2 lines
│   miss a drop-off...    │
│                         │
│      [Spacer 3x]        │
│                         │
│  ┌──────────────────┐   │
│  │  Get Started  ───┤   │ Filled Button
│  └──────────────────┘   │
│                         │
│  ┌──────────────────┐   │
│  │ I already have   │   │ Outlined Button
│  │   an account     │   │
│  └──────────────────┘   │
│                         │
│      [Spacer 1x]        │
│                         │
│  By continuing, you     │ Body Small, centered
│  agree to our Terms...  │ 2 lines
│                         │
└─────────────────────────┘
```

#### Signup/Login Screen
```
┌─────────────────────────┐
│  ← Back                 │ AppBar
├─────────────────────────┤
│                         │
│  Create Account         │ Headline Medium, bold
│  Let's get started...   │ Body Large, gray
│                         │
│  ┌──────────────────┐   │
│  │ 👤 Full Name     │   │ TextFormField
│  └──────────────────┘   │
│                         │
│  ┌──────────────────┐   │
│  │ Email │ Phone    │   │ Segmented Button
│  └──────────────────┘   │
│                         │
│  ┌──────────────────┐   │
│  │ ✉ Email Address  │   │ TextFormField (conditional)
│  └──────────────────┘   │
│                         │
│  ┌──────────────────┐   │
│  │ ℹ️ We'll send a   │   │ Info Box
│  │   magic link...  │   │
│  └──────────────────┘   │
│                         │
│  ┌──────────────────┐   │
│  │    Continue   ───┤   │ Filled Button
│  └──────────────────┘   │
│                         │
└─────────────────────────┘
```

#### Verification Screen (Phone)
```
┌─────────────────────────┐
│  ← Back                 │ AppBar
├─────────────────────────┤
│                         │
│       ┌─────┐           │
│       │ 💬  │           │ Icon, 80dp circle
│       └─────┘           │
│                         │
│  Enter Verification     │ Headline Medium
│        Code             │
│                         │
│  We sent a 6-digit      │ Body Large, centered
│  code to +1...          │ 2 lines
│                         │
│  ┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐ │ OTP boxes
│  │1 ││2 ││3 ││4 ││5 ││6 │ │ 48×56dp each
│  └──┘└──┘└──┘└──┘└──┘└──┘ │
│                         │
│  ┌──────────────────┐   │
│  │    Verify     ───┤   │ Filled Button
│  └──────────────────┘   │
│                         │
│  Resend code in 60s     │ Body Medium, gray
│                         │
│  [Use different number] │ TextButton
│                         │
└─────────────────────────┘
```

---

### ✨ Animations & Transitions

**Page Transitions**
```
Duration:                300ms
Curve:                   easeInOut
Type:                    Slide from right (forward)
                        Slide to right (back)
```

**Button Press**
```
Duration:                100ms
Scale:                   0.98
Feedback:                Haptic light
```

**Loading States**
```
Spinner Size:            24dp
Stroke Width:            2dp
Color:                   On Primary (for filled buttons)
                        Primary (for outlined buttons)
```

**Focus Change**
```
Duration:                200ms
Curve:                   easeOut
Border Color:            Animate to Primary
Border Width:            1dp → 2dp
```

---

### 🔒 States & Feedback

#### Success State
```
Color:                   Success green
Icon:                    ✓ Check circle
SnackBar Duration:       2 seconds
Position:                Bottom
```

#### Error State
```
Color:                   Error red
Icon:                    ⚠ Warning
Helper Text:             Below field, error color
SnackBar Duration:       4 seconds
Position:                Bottom
```

#### Loading State
```
Button Content:          Replace text with spinner
Disabled:                True (prevent double-tap)
Spinner:                 24dp circular progress
```

---

### 📏 Responsive Breakpoints

```
Compact:                 < 600dp width
├─ Padding:              24dp
├─ Content Width:        100%
└─ Button Layout:        Stack vertical

Medium:                  600dp - 840dp
├─ Padding:              40dp
├─ Content Width:        80%
└─ Button Layout:        Stack vertical

Expanded:                > 840dp
├─ Padding:              Center content
├─ Content Width:        480dp max
└─ Button Layout:        Horizontal option
```

---

### ♿ Accessibility

**Minimum Touch Target**
```
Size:                    48dp × 48dp (WCAG 2.1)
Buttons:                 56dp height (more comfortable)
Spacing:                 8dp minimum between targets
```

**Color Contrast**
```
Text on Background:      4.5:1 minimum (WCAG AA)
Large Text:              3:1 minimum
Interactive Elements:    3:1 minimum
```

**Screen Reader Labels**
```
All inputs:              Semantic labels
All buttons:             Clear action labels
Icons:                   Semantic descriptions
State changes:           Announcements
```

**Focus Indicators**
```
Visible:                 Always
Color:                   Primary
Width:                   2dp
Style:                   Solid border
```

---

### 🎨 Dark Mode Considerations

```
Background:              #121212 instead of white
Surface:                 #1E1E1E instead of #F5F5F5
On Surface:              #E0E0E0 instead of #1C1B1F
Primary:                 #8AB4F8 (lighter blue)
Elevation:               Use shadows + surface tint
```

---

This design specification ensures consistency across all authentication screens while maintaining a modern, clean, and accessible user experience.

