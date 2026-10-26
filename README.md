JoinMe 

> Course Project: a working Flutter app backed by Supabase (accounts, events, real-time group chats, ratings).

---

📌 Project Description

JoinMe is a location-based mobile app that helps people create and discover spontaneous nearby activities in real time. It makes it easy to turn free time into shared experiences by connecting individuals for study sessions, sports, and casual hangouts within their local community.


---

👥 Group Members

1. Edna Mesfin — ED5804

2. Rufael Melese — HA5984

---

🚀 Features

📍 Interactive map for discovering nearby activities

🎉 Create spontaneous events — long-press the map to pin one, set the time and how many people fit in a group

🤝 Join events — you're placed in the first group with room; when every group is full a new one opens automatically

💬 Real-time group chat per group to introduce yourselves and plan where to meet

⭐ After the event, rate the event, the host, and your group mates — ratings build each person's reputation

🔐 Email/password accounts with editable profile (name, bio)

👥 Friends and direct messages (UI only, mock data)

🌙 Dark and light theme support

🎨 Premium mobile-first UI built with Flutter

---

📱 Screens Included

Onboarding

Login / Signup

Main Map Screen

Create Event

Event Detail

Messages

Profile

Edit Profile

Rate Event

---

🛠️ Tech Stack

Flutter

Dart

Material Design 3

flutter_map (OpenStreetMap)

Supabase (Postgres, Auth, Realtime, row level security)



---

⚠️ Project Scope

Working: accounts, events on the map, auto-splitting groups, live group chat, ratings and reputation.

UI only (mock data): friends, direct messages, notifications. Not included: push notifications, production deployment.



---

▶️ Running the Project

1. Database (once): open your Supabase project → SQL Editor, paste all of `supabase/schema.sql`, and run it.
2. For testing, turn off Authentication → Providers → Email → "Confirm email".
3. The project URL and publishable key live in `lib/config/supabase_config.dart`.

```
git clone https://github.com/Rufaelu/joinme.git
cd joinme
flutter pub get
flutter run
```

Backend check (signs up 3 test users and runs through joining, chat permissions and ratings):

```
dart run tool/smoke_test.dart
```

Unit tests: `flutter test`

If the Android build fails with a bare Java version number (e.g. "27"), build with JDK 17:
`JAVA_HOME=/usr/lib/jvm/java-17-openjdk flutter build apk`


---

📂 Repository

https://github.com/Rufaelu/joinme.git


---

👨‍🏫 Instructor Note

JoinMe is a Flutter app with a Supabase backend. Data rules (who can read a group chat, who can rate whom, when ratings open) are enforced in the database with row level security, and joining a group is done atomically in a Postgres function so two people can never take the same last spot.


---

📄 License

This project is intended for educational purposes.