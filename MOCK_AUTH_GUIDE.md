# Mock Authentication - Testing Guide

## ✅ What's Been Connected

The authentication system is now fully integrated with your FamilyCal app using **mock data** for testing. Firebase integration can be added later without changing the UI flow.

---

## 🎯 How It Works

### App Flow
1. **App starts** → Shows `WelcomeScreen` if not logged in
2. **User signs up/logs in** → Goes through verification
3. **Verification succeeds** → Navigates to main `FamilyCalApp` (calendar)
4. **User can sign out** → Returns to `WelcomeScreen`

### Mock Authentication
- Any **6-digit code** is accepted as valid (123456, 000000, etc.)
- No actual emails or SMS sent (console logs only)
- User data stored in memory (lost on app restart)
- Perfect for UI testing and development

---

## 🧪 Testing the Flow

### Test Signup (New User)
1. Launch app → See Welcome screen
2. Tap **"Get Started"**
3. Enter name: `Test User`
4. Choose **Email** or **Phone**
5. Enter: `test@example.com` or `+15551234567`
6. Tap **"Continue"**
7. Enter any 6-digit code: `123456`
8. ✅ You're now in the calendar app!

### Test Login (Returning User)
1. From Welcome screen, tap **"I already have an account"**
2. Choose **Email** or **Phone**
3. Enter same contact as before
4. Tap **"Sign In"**
5. Enter any 6-digit code: `000000`
6. ✅ You're in!

### Test Sign Out
1. Navigate to **Settings** tab
2. Scroll to **Account** section
3. Tap **"Sign Out"**
4. Confirm in dialog
5. ✅ Back to Welcome screen

---

## 🔍 What to Look For

### ✅ Features Working
- [ ] App starts at Welcome screen
- [ ] Can navigate to Signup
- [ ] Can navigate to Login
- [ ] Email/Phone toggle works
- [ ] Form validation catches errors
- [ ] Loading states show during "API calls"
- [ ] OTP input auto-advances
- [ ] Any 6-digit code works
- [ ] Successful verification goes to calendar
- [ ] Settings shows logged in user name
- [ ] Sign out returns to Welcome
- [ ] Back button works correctly

### 📱 Console Messages
Watch for these in your terminal:
```
📧 Mock: Email verification sent to test@example.com
✅ Mock: Email verified for test@example.com
📱 Mock: SMS verification sent to +15551234567
✅ Mock: Phone verified for +15551234567
👋 Mock: User signed out
```

---

## 🎨 UI Highlights

### Welcome Screen
- Clean first impression
- Two clear buttons
- Modern Material Design 3

### Signup/Login Screens
- Segmented button for method selection
- Single input field changes based on choice
- Real-time validation
- Info boxes explain next steps
- Loading states on submit

### Verification Screen
- **Phone**: 6-digit OTP boxes with auto-advance
- **Email**: Instructions for magic link (auto-succeeds in mock)
- Resend with 60-second cooldown
- Back navigation to change contact

### Settings (New)
- Account section shows logged-in user
- Sign Out button with confirmation

---

## 📝 Mock Service Details

### File: `lib/services/mock_auth_service.dart`

**Key Methods:**
```dart
// Send verification (simulates 1s delay)
MockAuthService.sendEmailVerification(email, name)
MockAuthService.sendPhoneVerification(phone, name)

// Verify code (accepts any 6 digits)
MockAuthService.verifyEmailCode(email, code)
MockAuthService.verifyPhoneCode(phone, code)

// Check login status
MockAuthService.isLoggedIn  // bool
MockAuthService.currentUserName  // String?
MockAuthService.currentUserId  // String?

// Sign out
MockAuthService.signOut()
```

**Pre-loaded Test Users:**
- `test@example.com` → "Test User"
- `+15551234567` → "Phone User"
- Any new contact creates a new user automatically

---

## 🔄 What Happens Next

### Data Persistence (Optional)
Currently, auth state is lost on app restart. To persist:
```dart
// Add to pubspec.yaml
shared_preferences: ^2.2.2

// Save on login
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('is_logged_in', true);
await prefs.setString('user_name', userName);

// Check on app start
final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
```

### Firebase Integration (When Ready)
Replace `MockAuthService` with real Firebase Auth:
1. Add Firebase packages to `pubspec.yaml`
2. Initialize Firebase in `main.dart`
3. Create `FirebaseAuthService` with same method signatures
4. Replace import in screens
5. Update verification screen for real OTP/magic links

**No UI changes needed!** The screens already have the right structure.

---

## 🐛 Troubleshooting

### "App starts but shows blank screen"
- Check that `main.dart` imports are correct
- Verify `AuthGate` is rendering

### "Can't navigate to calendar after verification"
- Check console for errors
- Ensure `FamilyCalApp` exists and renders
- Verify `Navigator.pushAndRemoveUntil` isn't throwing

### "Sign out doesn't work"
- Check `MockAuthService.signOut()` is being called
- Ensure navigation removes all previous routes

### "Form validation not working"
- Check email regex pattern
- Ensure phone validation allows various formats
- Look for `validator` returning error strings

---

## 🎯 Next Steps

### Phase 1: Mock Testing (Current)
- ✅ Test all auth flows
- ✅ Verify UI/UX polish
- ✅ Check error handling
- ✅ Test on both iOS & Android

### Phase 2: Persistence (Optional for now)
- [ ] Add SharedPreferences
- [ ] Save auth state
- [ ] Restore on app launch

### Phase 3: Firebase Integration
- [ ] Set up Firebase project
- [ ] Add Firebase Auth
- [ ] Configure phone auth
- [ ] Set up email links
- [ ] Test with real SMS/emails

### Phase 4: Family Setup
- [ ] After signup, show family creation flow
- [ ] Add children
- [ ] Invite partner
- [ ] Then navigate to calendar

---

## 📊 Testing Checklist

### Functionality
- [ ] Signup with email works
- [ ] Signup with phone works
- [ ] Login with email works
- [ ] Login with phone works
- [ ] OTP auto-advance works
- [ ] Any 6-digit code accepts
- [ ] Success navigates to calendar
- [ ] Calendar app shows correctly
- [ ] Settings shows user name
- [ ] Sign out works
- [ ] Sign out confirmation shows
- [ ] After sign out, see Welcome again

### Visual Polish
- [ ] No layout overflow errors
- [ ] Loading states work smoothly
- [ ] Back button behavior is correct
- [ ] SnackBar messages appear
- [ ] Colors match design spec
- [ ] Spacing looks consistent
- [ ] Icons are appropriate

### Edge Cases
- [ ] Invalid email shows error
- [ ] Invalid phone shows error
- [ ] Incomplete OTP blocks submit
- [ ] Back button works from all screens
- [ ] Fast tapping doesn't break flow
- [ ] Resend cooldown timer works

---

## 🎉 Success Criteria

You'll know it's working when:
1. ✅ App starts at Welcome screen (not logged in)
2. ✅ Can complete signup flow end-to-end
3. ✅ Lands on calendar with mock data
4. ✅ Can sign out and return to Welcome
5. ✅ Can login again with same credentials
6. ✅ Console shows mock service messages

---

## 💡 Tips for Development

**Quick Login Shortcut:**
- Email: `test@example.com`
- Code: `123456`
- Always works!

**Testing Different Scenarios:**
- Try email first, then phone
- Test invalid inputs
- Test the resend flow
- Test back navigation
- Test sign out → sign in again

**Console Debugging:**
The mock service prints helpful messages:
- `📧` = Email sent
- `📱` = SMS sent
- `✅` = Verification succeeded
- `👋` = User signed out

---

Ready to test! Run the app and enjoy the smooth authentication flow. When you're ready for Firebase, the migration will be straightforward. 🚀

