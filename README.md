# DoMyTurn

DoMyTurn is a **Flutter-based cross-platform mobile app** with a **Spring Boot backend**, designed to help households manage chores, tasks, and shopping efficiently. It provides an intuitive interface for assigning chores, tracking absence, and collaborating among home members.  

---

## Features

- **Chores & Task Management**
  - Create, edit, and delete chores
  - Assign chores to home members
  - Set recurring tasks and payment-related chores
  - Track completion status

- **Absence Management**
  - Mark yourself absent
  - Auto or manual approval for absences
  - Notify other home members

- **Shopping Management**
  - Track unbought items
  - Mark items as bought
  - Home-level shopping list overview

- **User & Home Management**
  - Create or join a home
  - Edit home details (address, members)
  - Role-based permissions for home members

- **Notifications**
  - Chore assignment and update alerts
  - Absence approvals notifications

- **Cross-platform**
  - Android, iOS (Flutter)
  - Responsive UI with Material 3 expressive design

---

## Tech Stack

### Mobile App
- **Flutter & Dart**
- Cross-platform (Android & iOS)
- Material 3 expressive design
- State management with Provider / Riverpod (if applicable)

### Backend
- **Spring Boot (Java)**
- JWT-based authentication
- RESTful APIs
- Quartz Scheduler for automated tasks
- Outbox pattern for reliable notifications

### Database
- PostgreSQL / MySQL (depending on deployment)
- Efficient chore, user, and home data storage

### Cloud / Deployment
- Hosted on AWS EC2
- Secure HTTPS endpoints
- CI/CD with GitHub Actions / AWS CodePipeline

---

## Screenshots

<img width="1344" height="2992" alt="DashBoard" src="https://github.com/user-attachments/assets/c09c7bfd-e320-420d-b5fa-408b9129af1c" />
<img width="1344" height="2992" alt="ChoresScreen" src="https://github.com/user-attachments/assets/5ecf4bca-bd33-425e-ae5f-a7bf8b5f1d9f" />
<img width="1344" height="2992" alt="ShoppingScreen" src="https://github.com/user-attachments/assets/595a3120-7200-4281-89ea-b9e22a74f287" />
<img width="1344" height="2992" alt="Homemgmt" src="https://github.com/user-attachments/assets/b4d754e1-0632-4f2f-9ac8-27600f360715" />
<img width="1344" height="2992" alt="Profile Screen" src="https://github.com/user-attachments/assets/00826961-6298-4dc1-876c-7ca860e037b1" />
<img width="1344" height="2992" alt="PaymentChore" src="https://github.com/user-attachments/assets/69023574-263a-4f34-baa5-9c07b19b4e8d" />

---

## Installation

### Prerequisites
- Flutter SDK
- Android Studio / Xcode
- Java 17+ (for Spring Boot backend)
- PostgreSQL / MySQL database

### Running the Flutter App
```bash
git clone https://github.com/sumanthkota-dev/DoMyTurn-Android.git
cd DoMyTurn-Android
flutter pub get
flutter run
