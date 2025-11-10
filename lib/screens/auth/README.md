# Authentication Screens - Design Documentation

## Overview
Clean, modern authentication flow for FamilyCal following Material Design 3 principles with emphasis on simplicity and trust.

## Screens

### 1. Welcome Screen (`welcome_screen.dart`)
**Purpose:** First impression - introduce the app and provide clear CTAs

**Key Features:**
- Large app icon with brand color
- Clear app name and value proposition
- Two prominent buttons: "Get Started" (filled) and "I already have an account" (outlined)
- Terms & Privacy disclaimer at bottom
- No clutter - focuses user attention on actions

**Design Decisions:**
- Uses spacers to create breathing room and visual hierarchy
- Primary action (Get Started) is more prominent than secondary (Login)
- Tagline communicates immediate value: "Never miss a drop-off or pickup"

---

### 2. Signup Screen (`signup_screen.dart`)
**Purpose:** Collect minimal info and choose verification method

**Key Features:**
- Full name input (builds trust, personalization)
- Segmented button to choose Email or Phone
- Single input field that changes based on selection
- Info box explaining what happens next (magic link or SMS code)
- Real-time validation with helpful error messages
- Loading state during submission

**Design Decisions:**
- **Minimal friction:** Only asks for name and contact method
- **Choice is visible:** Segmented button makes both options equally accessible
- **Transparent process:** Info box sets expectations before user commits
- **Progressive disclosure:** Only shows relevant field based on selection
- **Validation:** Client-side validation prevents submission errors

**UX Flow:**
1. User enters name
2. Selects email or phone
3. Enters contact info
4. Reads what will happen (magic link/SMS)
5. Clicks Continue
6. Loading indicator provides feedback
7. Navigates to verification

---

### 3. Login Screen (`login_screen.dart`)
**Purpose:** Return users can quickly sign back in

**Key Features:**
- Similar to signup but streamlined (no name field)
- Segmented button for email/phone selection
- Autofill hints for better UX
- Clear messaging: "No password needed"
- Link to sign up if wrong screen

**Design Decisions:**
- **Familiar pattern:** Mirrors signup screen for consistency
- **No passwords:** Emphasizes passwordless authentication benefit
- **Easy escape:** "Don't have an account?" link at bottom
- **Trust signals:** Lock icon and security messaging

**UX Flow:**
1. User chooses email or phone
2. Enters contact info (can use autofill)
3. Reads security info
4. Clicks Sign In
5. Navigates to verification

---

### 4. Verification Screen (`verification_screen.dart`)
**Purpose:** Verify ownership of email/phone

**Key Features:**
- **For Phone:** 6-digit OTP input with auto-advance
- **For Email:** Magic link instructions with visual guidance
- Clear icon showing which method (email/message)
- Shows where code/link was sent
- Resend functionality with 60s cooldown
- Option to go back and change contact

**Design Decisions:**
- **Different UX per method:**
  - Phone: OTP input boxes for quick entry
  - Email: Instructions to check inbox
- **Auto-advance:** OTP fields automatically move focus
- **Auto-verify:** When 6th digit entered, automatically verifies
- **Cooldown timer:** Prevents spam, shows countdown
- **Clear feedback:** Success/error messages via snackbar
- **Escape hatch:** "Use different number/email" button

**Phone OTP UX:**
1. User sees 6 boxes with keyboard ready
2. Types digits, auto-advances
3. On 6th digit, auto-submits
4. Loading state, then success
5. If wrong, can clear and retry

**Email Magic Link UX:**
1. User sees large info box explaining next step
2. Checks email in separate app
3. Clicks link, returns to app (deep link)
4. Can resend if needed

---

## Design Principles Applied

### 1. **Progressive Disclosure**
- Only show what's needed at each step
- Segmented buttons reveal relevant fields
- Info boxes appear contextually

### 2. **Clear Hierarchy**
- Headers are bold and large
- Body text is readable with proper color contrast
- Primary actions use filled buttons
- Secondary actions use text/outlined buttons

### 3. **Feedback & Affordance**
- Loading states on all async actions
- Validation errors inline
- Success/error snackbars
- Disabled states when appropriate

### 4. **Trust & Transparency**
- Info boxes explain what happens next
- Show exactly where code/link is sent
- Timer shows when resend is available
- Terms & privacy mentioned upfront

### 5. **Accessibility**
- Proper label/hint text on all inputs
- Autofill hints for known field types
- Focus management in OTP inputs
- Sufficient touch targets (56dp height)
- Color contrast meets WCAG standards

### 6. **Error Prevention**
- Client-side validation before submission
- Clear format hints (e.g., "you@example.com")
- Input formatters for phone numbers
- Disabled submit until form valid

---

## Color & Typography

### Colors (Material Design 3)
- **Primary:** Brand blue (#1A73E8)
- **Primary Container:** Light blue background for info boxes
- **Surface Variant:** Subtle backgrounds for segmented buttons
- **On Surface Variant:** Secondary text color
- **Error:** Red for validation messages

### Typography
- **Headline Medium (28sp):** Screen titles
- **Body Large (16sp):** Descriptions, input labels
- **Body Medium (14sp):** Supporting text
- **Body Small (12sp):** Captions, disclaimers

### Spacing
- Section spacing: 24-32dp
- Between related elements: 8-16dp
- Button height: 56dp (Material recommended)
- Input height: 56dp (consistent touch targets)

---

## Implementation Notes

### Form Validation
```dart
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter your email';
  }
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Please enter a valid email';
  }
  return null;
}
```

### State Management
- Local state with `setState` (appropriate for auth flows)
- Loading states prevent double-submission
- Form keys for validation management

### Navigation
- Simple `Navigator.push` for forward flow
- `Navigator.pop` for back navigation
- Deep linking support needed for magic links

---

## Future Enhancements

### Phase 2
- [ ] Social login (Google, Apple)
- [ ] Biometric quick login (after first auth)
- [ ] Remember device toggle
- [ ] Multi-device management

### Phase 3
- [ ] SMS autofill on Android
- [ ] Apple Sign In with iCloud relay
- [ ] Account recovery flow
- [ ] Two-factor authentication option

---

## Testing Checklist

- [ ] Email validation works correctly
- [ ] Phone validation accepts various formats
- [ ] Segmented button switches correctly
- [ ] Loading states prevent double-tap
- [ ] Back button works from all screens
- [ ] OTP auto-advance works
- [ ] Resend cooldown timer accurate
- [ ] Error messages are helpful
- [ ] Success states navigate correctly
- [ ] Works on both iOS and Android
- [ ] Works in dark mode
- [ ] Keyboard behavior is correct
- [ ] Focus management is intuitive
- [ ] Screen reader compatibility
