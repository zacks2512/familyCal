# Family Setup Flow - Complete Guide

## ✅ What Was Added

A complete **3-step family setup wizard** that runs after user registration (both social and email/phone authentication).

---

## 🎯 The Flow

### Registration → Family Setup → Calendar

```
User Registers (Google/Apple/Facebook/Email/Phone)
    ↓
Step 1: Create Family & Set Name
    ↓
Step 2: Add Family Members (optional)
    ↓
Step 3: Add Children (optional)
    ↓
Main Calendar App
```

---

## 📱 The Three Setup Screens

### **Step 1: Family Name Screen**

**Purpose:** Create the family and give it a name

**Features:**
- Progress indicator (Step 1 of 3)
- Family icon visual
- Single text input for family name
- Examples: "The Smiths", "Johnson Family"
- Helper text: "You can change this later in settings"
- Can't proceed without entering a name
- Autofocus on input field

**Example:**
```
┌─────────────────────────┐
│ Step 1 of 3             │
│ ▓▓▓▓░░░░░░░░            │
│                         │
│    [👨‍👩‍👧‍👦 Icon]           │
│                         │
│ Create Your Family      │
│ Let's start by giving   │
│ your family a name      │
│                         │
│ ┌─────────────────────┐ │
│ │🏠 Family Name       │ │
│ │ The Smiths          │ │
│ └─────────────────────┘ │
│                         │
│ ℹ️ You can change this  │
│   later in settings     │
│                         │
│ ┌─────────────────────┐ │
│ │    Continue      ───┤ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

---

### **Step 2: Add Participants Screen**

**Purpose:** Add other adults who will help coordinate (partner, grandparents, etc.)

**Features:**
- Progress indicator (Step 2 of 3)
- People icon visual
- List of added participants
- "Add Family Member" button
- Each participant shows:
  - Name
  - Email or phone (optional)
  - Remove button
- **Can skip this step** (button says "Skip for Now")
- Bottom sheet for adding participants

**Adding a Participant:**
- Name (required)
- Email (optional)
- Phone (optional)
- Validates name field

**Example Flow:**
```
Empty State:
┌─────────────────────────┐
│ Step 2 of 3             │
│ ▓▓▓▓▓▓▓▓░░░░            │
│                         │
│    [👥 Icon]            │
│                         │
│ Add Family Members      │
│ Invite your partner,    │
│ grandparents, or anyone │
│ who helps with the kids │
│                         │
│      [👥 64px icon]     │
│  No family members yet  │
│  Add people who will    │
│  help coordinate        │
│                         │
│ ┌─────────────────────┐ │
│ │ + Add Family Member │ │
│ └─────────────────────┘ │
│                         │
│ ┌─────────────────────┐ │
│ │  Skip for Now    ───┤ │
│ └─────────────────────┘ │
└─────────────────────────┘

With Participants:
┌─────────────────────────┐
│ [Back] Add Family...    │
├─────────────────────────┤
│ Step 2 of 3             │
│ ▓▓▓▓▓▓▓▓░░░░            │
│                         │
│ ┌─────────────────────┐ │
│ │ 👤 Sarah Smith      │ │
│ │    sarah@email.com  │✕│
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │ 👤 Grandma Jones    │ │
│ │    +1 555 123 4567  │✕│
│ └─────────────────────┘ │
│                         │
│ ┌─────────────────────┐ │
│ │ + Add Another...    │ │
│ └─────────────────────┘ │
│                         │
│ ┌─────────────────────┐ │
│ │    Continue      ───┤ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

---

### **Step 3: Add Children Screen**

**Purpose:** Add the children whose schedules will be coordinated

**Features:**
- Progress indicator (Step 3 of 3)
- Child care icon visual
- List of added children
- "Add Child" button
- Each child shows:
  - Name
  - Color (color-coded avatar and card)
  - Remove button
- **Can skip this step** with confirmation dialog
- Bottom sheet for adding children
- Color picker for each child

**Adding a Child:**
- Name (required)
- Color selection (8 colors available)
- Shows color preview in cards

**Example:**
```
Empty State:
┌─────────────────────────┐
│ Step 3 of 3             │
│ ▓▓▓▓▓▓▓▓▓▓▓▓            │
│                         │
│    [👶 Icon]            │
│                         │
│ Add Your Children       │
│ Add the kids you'll be  │
│ coordinating schedules  │
│ for                     │
│                         │
│    [👶 64px icon]       │
│    No children yet      │
│  Add the kids you'll    │
│  track schedules for    │
│                         │
│ ┌─────────────────────┐ │
│ │   + Add Child       │ │
│ └─────────────────────┘ │
│                         │
│ ┌─────────────────────┐ │
│ │  Skip for Now    ───┤ │
│ └─────────────────────┘ │
└─────────────────────────┘

With Children:
┌─────────────────────────┐
│ [Back] Add Children     │
├─────────────────────────┤
│ Step 3 of 3             │
│ ▓▓▓▓▓▓▓▓▓▓▓▓            │
│                         │
│ ┌─────────────────────┐ │
│ │ 🔴 E  Emma          │✕│
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │ 🔵 L  Liam          │✕│
│ └─────────────────────┘ │
│                         │
│ ┌─────────────────────┐ │
│ │ + Add Another Child │ │
│ └─────────────────────┘ │
│                         │
│ ┌─────────────────────┐ │
│ │  Finish Setup    ───┤ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

---

## 🎨 Design Features

### Progress Indicator
- Shows "Step X of 3" text
- Visual progress bars (3 segments)
- Active steps are colored primary
- Inactive steps are surface variant

### Consistent Design
- All screens use same layout structure
- 80px circular icon at top
- Large headline (28sp bold)
- Body text explaining the step
- Form fields or lists in middle
- Action buttons at bottom (56dp height)

### Empty States
- Large icon (64px)
- Clear message
- Call to action button
- Used in steps 2 and 3 when no items added

### Bottom Sheets
- Modern rounded top corners (20dp radius)
- Pull handle at top
- Keyboard-aware padding
- Form fields with validation
- Primary action button at bottom

### Color Palette for Children
- 8 preset colors to choose from
- Pink, Orange, Blue, Green, Purple, Red, Teal, Amber
- Used throughout app for child identification
- Color-coded cards and avatars

---

## 🔄 Navigation Flow

### New Registration (Social or Email/Phone)
```
Welcome Screen
    ↓ Tap "Continue with Google"
Social Auth Success
    ↓ (New user)
Family Name Screen (Step 1)
    ↓ Enter family name
Add Participants Screen (Step 2)
    ↓ Add members or skip
Add Children Screen (Step 3)
    ↓ Add children or skip
Calendar App ✅
```

### Existing User Login
```
Welcome Screen
    ↓ Tap "Log In"
Login Screen
    ↓ Enter credentials
Verification
    ↓ Verify code
Calendar App directly ✅
(Skips family setup)
```

---

## 🧪 Testing the Flow

### Test New Registration
1. Launch app
2. Tap "Continue with Google"
3. Wait 1 second (mock delay)
4. ✅ See **Family Name Screen**
5. Enter: "The Test Family"
6. Tap "Continue"
7. ✅ See **Add Participants Screen**
8. Tap "Add Family Member"
9. Enter name: "Partner Name"
10. Tap "Add Member"
11. See participant in list
12. Tap "Continue"
13. ✅ See **Add Children Screen**
14. Tap "Add Child"
15. Enter name: "Test Child"
16. Select a color
17. Tap "Add Child"
18. See child in list
19. Tap "Finish Setup"
20. ✅ Navigate to Calendar App!

### Test Skipping Steps
1. Go through steps above
2. On **Add Participants**, tap "Skip for Now"
3. ✅ Proceeds to children step
4. On **Add Children**, tap "Skip for Now"
5. ✅ See confirmation dialog
6. Tap "Continue"
7. ✅ Navigate to Calendar App

### Test Login (Existing User)
1. From Welcome, tap "Log In"
2. Enter email/phone
3. Verify with code
4. ✅ Go **directly** to Calendar (skip setup)

---

## 📊 Data Collected

### After Completing Setup

**Family Data:**
```dart
{
  "name": "The Test Family",
  "owner_id": "google_123456",
  "created_at": timestamp,
}
```

**Participants:**
```dart
[
  {
    "name": "Partner Name",
    "email": "partner@email.com",
    "phone": null,
    "role": "parent"
  },
  {
    "name": "Grandma Jones",
    "email": null,
    "phone": "+1 555 123 4567",
    "role": "grandparent"
  }
]
```

**Children:**
```dart
[
  {
    "name": "Emma",
    "color": "#F48FB1", // Pink
    "created_at": timestamp,
  },
  {
    "name": "Liam",
    "color": "#64B5F6", // Blue
    "created_at": timestamp,
  }
]
```

---

## 💾 Data Persistence (TODO)

Currently, the data is collected but not yet persisted. Next steps:

1. **Create FamilyOnboardingState class** to hold collected data
2. **Save to Firestore** when "Finish Setup" is tapped:
   - Create family document
   - Create children documents
   - Send invites to participants
3. **Update AppState** with new family data
4. **Pass data** between screens properly

### Implementation Notes:
```dart
// In family_name_screen.dart
final onboardingData = Provider.of<FamilyOnboardingState>(context);
onboardingData.setFamilyName(familyName);

// In add_children_screen.dart
await onboardingData.saveToFirestore();
```

---

## 🎯 User Experience Highlights

### Progressive Disclosure
- Only shows one step at a time
- Clear progress indicator
- No overwhelming forms

### Flexible Flow
- Can skip participant step entirely
- Can skip children step with confirmation
- Can add multiple items easily

### Clear Affordances
- Large touch targets (56dp buttons)
- Color-coded children for easy identification
- Visual icons reinforce purpose of each step

### Helpful Feedback
- Helper text on family name
- Empty states guide users
- Confirmation dialog prevents accidental skips

### Mobile-First
- Bottom sheets for adding items
- Keyboard-aware layouts
- Single-column design
- Thumb-friendly button placement

---

## 🔧 Technical Implementation

### File Structure
```
lib/screens/onboarding/
├── family_setup_flow.dart         # Entry point
├── family_name_screen.dart        # Step 1
├── add_participants_screen.dart   # Step 2
└── add_children_screen.dart       # Step 3
```

### Key Features
- **StatefulWidget** for managing local state
- **Form validation** on required fields
- **Bottom sheets** for modal forms
- **Progress indicator** component
- **Empty states** for better UX
- **Color picker** for children
- **Confirmation dialogs** for skip actions

### State Management
- Local state in each screen
- Data passed via constructor parameters
- Ready to integrate with Provider/Riverpod

---

## 🚀 Next Steps

### Phase 1 (Current)
- ✅ UI/UX complete
- ✅ Navigation flow working
- ✅ Form validation
- ✅ Empty states
- ⏳ Data persistence

### Phase 2 (Next)
- [ ] Integrate with Firestore
- [ ] Send actual email/SMS invites
- [ ] Create family documents
- [ ] Create children documents
- [ ] Update app state with family data

### Phase 3 (Future)
- [ ] Edit family after setup
- [ ] Allow users to skip and complete later
- [ ] Bulk import from contacts
- [ ] Photo uploads for children
- [ ] Age/birthday fields for children

---

## ✨ Summary

The family setup flow provides a **smooth, guided onboarding experience** that:

1. ✅ Collects essential family information
2. ✅ Allows flexibility (skip optional steps)
3. ✅ Uses familiar UI patterns (bottom sheets, progress)
4. ✅ Provides clear feedback at each step
5. ✅ Maintains consistent design with auth screens
6. ✅ Works seamlessly with both social and email/phone auth

Users can now register with Google/Apple/Facebook, set up their family in 3 easy steps, and start using the calendar app!

---

## 📝 Testing Checklist

- [ ] Register with Google → Goes to family setup
- [ ] Register with Apple → Goes to family setup
- [ ] Register with Email → Verify → Goes to family setup
- [ ] Can enter family name
- [ ] Can't proceed without family name
- [ ] Can add participants
- [ ] Can skip participants
- [ ] Can remove participants
- [ ] Can add children with colors
- [ ] Can skip children (with confirmation)
- [ ] Can remove children
- [ ] "Finish Setup" goes to calendar
- [ ] Login (existing user) skips setup
- [ ] Back button works on steps 2 and 3
- [ ] Bottom sheets open/close correctly
- [ ] Form validation works
- [ ] Color picker works
- [ ] Progress indicator updates correctly

---

Ready to test the complete registration and onboarding flow! 🎉

