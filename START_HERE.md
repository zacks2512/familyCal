# 🚀 START HERE - FamilyCal Quick Start

**Status:** ✅ **PRODUCTION READY**  
**Last Updated:** November 10, 2025  
**Platform:** Android (iOS pending macOS)

---

## ⚡ Quick Start (30 seconds)

```bash
/home/shani/personalProjects/familycal/run_app.sh
```

That's it! The script will guide you through running the app.

---

## 📚 Documentation (by use case)

### "I just want to run the app"
→ Read: [`README_DEPLOYMENT.md`](README_DEPLOYMENT.md) (5 min)  
→ Then run: `/home/shani/personalProjects/familycal/run_app.sh`

### "I want to understand what's been set up"
→ Read: [`DEPLOYMENT_COMPLETE.md`](DEPLOYMENT_COMPLETE.md) (10 min)  
→ Shows: Complete checklist of everything deployed

### "I need to know about Firebase"
→ Read: [`FIREBASE_INFO.md`](FIREBASE_INFO.md) (15 min)  
→ Shows: All Firebase services, structure, and links

### "I want all available commands"
→ See: [`COMMANDS_REFERENCE.sh`](COMMANDS_REFERENCE.sh)  
→ Copy/paste any command you need

### "What's the project structure?"
→ Read: [`project.md`](project.md) (architecture overview)

---

## 🎯 3 Ways to Run the App

### Way 1: Interactive Script (RECOMMENDED - Easiest)
```bash
/home/shani/personalProjects/familycal/run_app.sh
# Follow the prompts, choose what you want to do
```

### Way 2: On Your Android Phone
```bash
# Connect phone via USB, enable USB debugging
cd /home/shani/personalProjects/familycal
/home/shani/flutter/bin/flutter devices          # See your phone
/home/shani/flutter/bin/flutter run -d <ID>     # Run on it
```

### Way 3: On Android Emulator
```bash
# First time only - create emulator:
/home/shani/flutter/bin/flutter emulators --create --name pixel_5

# Launch it:
/home/shani/flutter/bin/flutter emulators --launch pixel_5

# Then run the app:
/home/shani/flutter/bin/flutter run
```

---

## ✨ What's Working

✅ **User Management**
- Registration with email/password
- User profiles with display names
- Secure authentication via Firebase

✅ **Family Management**
- Create families
- Add family members
- Invite system ready

✅ **Children Management**
- Add child profiles
- Track date of birth
- Add notes

✅ **Events & Calendar**
- Create events (drop-off/pick-up)
- Assign events to family members
- Recurring events support
- Real-time sync

✅ **Notifications** (framework ready)
- Event assignment notifications
- Event confirmation alerts
- Daily unassigned event checks
- Push notifications backend

✅ **Backend Automation**
- 4 Cloud Functions deployed
- Daily scheduler running
- Real-time Firestore sync
- Security rules active

---

## 📊 System Status

| Component | Status | Details |
|-----------|--------|---------|
| Firebase Backend | ✅ Active | familycal-3b3a9 |
| Firestore Database | ✅ Deployed | us-central1 |
| Cloud Functions | ✅ 4/4 Deployed | All active |
| Android App | ✅ Ready | Can run now |
| iOS App | ⏸️ Pending | Needs macOS |
| Development Setup | ✅ Complete | Node, Flutter ready |

---

## 🔗 Important Links

**Firebase Console:**
https://console.firebase.google.com/project/familycal-3b3a9/overview

**View your data:**
https://console.firebase.google.com/project/familycal-3b3a9/firestore/data

**Function logs:**
https://console.firebase.google.com/project/familycal-3b3a9/functions/list

**User accounts:**
https://console.firebase.google.com/project/familycal-3b3a9/authentication/users

---

## 🔐 Security

✅ All data is encrypted (Firebase handles it)  
✅ Family-based access control enforced  
✅ Users can only see their own family  
✅ Proper Android permissions configured  
✅ Budget alerts set up ($50/month limit)

---

## 💻 Development

### Make Code Changes
```bash
cd /home/shani/personalProjects/familycal
/home/shani/flutter/bin/flutter run

# While running, press 'r' to reload
# Press 'R' to restart
# Press 'q' to quit
```

### Deploy Backend Changes
```bash
export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
cd /home/shani/personalProjects/familycal
firebase deploy
```

### Check Function Logs
```bash
export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
firebase functions:log
```

---

## 🆘 Problems?

### App won't run?
```bash
cd /home/shani/personalProjects/familycal
/home/shani/flutter/bin/flutter clean
/home/shani/flutter/bin/flutter pub get
/home/shani/flutter/bin/flutter run --verbose
```

### Can't find devices?
```bash
/home/shani/flutter/bin/flutter doctor -v
/home/shani/flutter/bin/flutter devices
```

### Need help?
1. Check the logs: `flutter run --verbose`
2. See detailed docs: [`README_DEPLOYMENT.md`](README_DEPLOYMENT.md)
3. Check Firebase Console for errors
4. Search error message in terminal output

---

## 📋 File Guide

| File | Purpose |
|------|---------|
| `run_app.sh` | Interactive app launcher |
| `COMPLETION_SUMMARY.txt` | Visual status overview |
| `README_DEPLOYMENT.md` | Complete deployment guide |
| `DEPLOYMENT_COMPLETE.md` | Detailed checklist |
| `FIREBASE_INFO.md` | Firebase service details |
| `COMMANDS_REFERENCE.sh` | All available commands |
| `SETUP_STATUS.md` | Setup progress tracker |
| `QUICK_START.md` | Quick reference |
| `project.md` | Project architecture |

---

## 🎯 Next Steps

**Choose ONE:**

1️⃣ **"I want to test it now"**
```bash
/home/shani/personalProjects/familycal/run_app.sh
```

2️⃣ **"I want to understand it first"**
→ Read [`README_DEPLOYMENT.md`](README_DEPLOYMENT.md) (takes 5 min)

3️⃣ **"I want to keep developing"**
→ Start making changes in `lib/` directory
→ Run with hot-reload to see changes instantly

4️⃣ **"I need to deploy to Play Store"**
→ Follow guide in [`README_DEPLOYMENT.md`](README_DEPLOYMENT.md) (section "Build & Distribution")

---

## 💡 Pro Tips

### Create Aliases (Optional)
Add to your `~/.bashrc` for quicker access:
```bash
alias familycal='cd /home/shani/personalProjects/familycal'
alias fcal_run='/home/shani/personalProjects/familycal/run_app.sh'
alias fcal_flutter='/home/shani/flutter/bin/flutter'
```

Then use:
```bash
familycal && fcal_flutter run
```

### VSCode Setup (Optional)
1. Install Flutter extension
2. Install Dart extension
3. Open project folder
4. Press F5 to run
5. Enjoy debugging!

### Monitor Your Costs
Track usage at:
https://console.firebase.google.com/project/familycal-3b3a9/usage/database

---

## ✅ Everything Installed & Ready

- ✅ Node.js 20.19.5
- ✅ npm 10.8.2
- ✅ Firebase CLI 14.24.1
- ✅ Flutter with all dependencies
- ✅ All 81 Flutter packages
- ✅ Cloud Functions dependencies
- ✅ Firebase backend deployed

**No additional installation needed!**

---

## 🎉 You're All Set!

Everything is ready. Pick one of the "Next Steps" above and start!

**Questions?** See `README_DEPLOYMENT.md` or `FIREBASE_INFO.md`

**Ready?** Run: `/home/shani/personalProjects/familycal/run_app.sh`

---

**Generated:** November 10, 2025  
**Status:** ✅ Production Ready  
**Platform:** Android (iOS pending)

