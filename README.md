# JoinMe - Location-based Spontaneous Activity Finder

JoinMe is a production-ready, location-based mobile application powered by Flutter and Firebase (Authentication, Cloud Firestore, and Firebase Storage) that helps people create and discover spontaneous nearby activities in real time. It makes it easy to turn free time into shared experiences by connecting individuals for study sessions, sports, and casual hangouts within their local community.

---

## 👥 Group Members

1. Edna Mesfin — ED5804
2. Hawi Nemera — AR9524
3. Imran Getu — EH6031
4. Rufael Melese — HA5984
5. Yahwenissi Elias — LS5191

---

## 🚀 Features

- **Authentication**: Email/Password Sign Up, Email/Password Login, Google Sign-In, Forgot Password, and Authentication State Persistence.
- **Interactive Map**: Interactive maps (via OpenStreetMap) for discovering nearby activities and picking locations for new events.
- **Event Management**: Users can create, browse, join, leave, edit, and delete events.
- **Real-time Messaging**: Multi-user group chats for each event utilizing Firestore real-time collection streams.
- **Profile Management**: Profile views, updates, and profile picture uploads powered by Firebase Storage.
- **Favorites System**: Bookmark and list favorite events in real-time.
- **Dark and Light Theme**: Toggle dynamic styling easily across all screens.
- **Robust Security Rules**: Safe backend constraints for users, organizers, participants, and storage assets.

---

## 📂 Project Architecture

The app uses **Clean Architecture** patterns for separation of concerns and maintainability:
- `lib/core/config/`: App configurations (e.g. `firebase_options.dart`).
- `lib/models/`: Type-safe serialization models (`UserModel`, `JoinMeEvent`, `ParticipantModel`, `NotificationModel`).
- `lib/repositories/`: Services abstraction layer (`AuthRepository`, `UserRepository`, `EventRepository`, `StorageRepository`, `NotificationRepository`).
- `lib/providers/`: State management controller (`AppState` using the Provider package).
- `lib/screens/`: High fidelity visual screens.
- `lib/widgets/`: Reusable components (e.g., GlassContainer, BottomNav).

---

## 🛠️ Firebase Setup & Configuration

### 1. Create a Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** and name it (e.g., `joinme-app`).
3. Enable Google Analytics (optional).

### 2. Register Client Applications

#### Android:
1. In the project overview, click the Android icon to register an app.
2. Enter the package name: `com.example.joinme`.
3. Download `google-services.json` and place it in the `android/app/` directory of the project.

#### iOS:
1. Click the iOS icon to register a new app.
2. Enter the bundle ID: `com.example.joinme`.
3. Download `GoogleService-Info.plist` and place it in the `ios/Runner/` directory.

### 3. Generate firebase_options.dart
If FlutterFire CLI is installed:
```bash
flutterfire configure
```
Alternatively, copy your project configuration values from the Firebase console and update `lib/core/config/firebase_options.dart`.

### 4. Enable Services
In the Firebase console, enable:
- **Authentication**: Enable Email/Password and Google providers.
- **Firestore Database**: Create database in Test Mode or Production Mode.
- **Storage**: Create a storage bucket.

### 5. Deploy Security Rules
To deploy rules locally using Firebase CLI:
```bash
# Log in to Firebase CLI
npx firebase login

# Deploy rules
npx firebase deploy --only firestore:rules,storage
```
Alternatively, copy the contents of `firestore.rules` and `storage.rules` directly into the Rules tabs under the Firestore and Storage sections of the Firebase Console.

---

## ▶️ Running the Project

1. Clone the repository:
   ```bash
   git clone https://github.com/Rufaelu/joinme.git
   cd joinme
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application locally:
   ```bash
   flutter run
   ```

---

## 📄 License

This project is intended for educational purposes.