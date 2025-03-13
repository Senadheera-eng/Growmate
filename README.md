# GrowMate 🌱

A comprehensive Flutter application for coconut tree management and disease detection, designed to help farmers and tree owners monitor their trees' health, implement treatment plans, and maintain optimal growing conditions.

![MainScreen](https://github.com/user-attachments/assets/c1e903a3-1b58-4436-96b3-d69e1ae4b1a6)
![GrowMate Main Screen](screenshots/main_screen.png)

## 📋 Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Architecture](#architecture)
- [Technologies Used](#technologies-used)
- [Database Structure](#database-structure)
- [Installation](#installation)
- [Usage](#usage)
- [Future Enhancements](#future-enhancements)
- [Contributors](#contributors)
- [License](#license)

## 🔍 Overview

GrowMate is a mobile application that assists users in managing and monitoring the health of their coconut trees. It uses machine learning to detect diseases from photos, provides customized care tips based on the tree's age, and offers step-by-step treatment plans for diseased trees. The app includes a comprehensive dashboard for visualizing tree health statistics and a notification system for timely care reminders.

GrowMate helps users:
- Track tree growth and health
- Detect diseases early using image recognition
- Follow treatment protocols for different diseases
- Receive timely reminders for care activities
- Maintain a comprehensive record of tree care

![MainScreen](https://github.com/user-attachments/assets/97d645f1-a727-48e8-ae3d-eff5002cd189)
![GrowMate Disease Detection](screenshots/disease_detection.png)

## ✨ Features

### 🌳 Tree Management
- **Add and Track Trees**: Register individual trees with photos, age, and location
- **Edit Tree Details**: Update information as trees grow or conditions change
- **Photo Gallery**: Visual history of each tree with multiple images
- **Location Tracking**: Integrates with Google Maps to record tree positions

![Screenshot_20250306_085614](https://github.com/user-attachments/assets/ed281355-1dcf-4572-a6a4-4455fdf27741)
![GrowMate Location Service](screenshots/location_service.png)

### 🔬 Disease Detection & Treatment
- **AI-Powered Analysis**: Image recognition for early disease detection
- **Disease Information**: Comprehensive database of common tree diseases
- **Step-by-Step Treatment**: Guided treatment plans customized for each disease
- **Progress Tracking**: Monitor treatment effectiveness over time

#### ML Disease Detection Results
![Healthy Leaf Detection](screenshots/healthy_leaf.png)
![Yellowing Leaf Detection](screenshots/yellowing_leaf.png)
![Drying Leaf Detection](screenshots/drying_leaf.png)

### 📊 Dashboard & Statistics
- **Health Overview**: Visual summary of tree health status
- **Care Activity History**: Records of all care activities
- **Calendar View**: Scheduled and completed activities
- **Treatment Success Rate**: Metrics on treatment effectiveness

### ⏰ Smart Reminders
- **Watering Reminders**: Based on tree age and last watering date
- **Fertilization Schedule**: Customized based on growth phase
- **Treatment Steps**: Timely reminders for ongoing treatments
- **Personalization**: Adjustable notification preferences

### 👤 User Management
- **Profile Management**: Secure user accounts
- **Data Synchronization**: Cloud storage for accessing data across devices
- **Settings Customization**: Personalized app configuration

![Screenshot_20250306_085752](https://github.com/user-attachments/assets/22dd2b0f-7a8b-42ce-8207-778ecd3cbc2f)
![GrowMate Calendar](screenshots/calendar_view.png)

## 📱 Screenshots

### Home Screen
![MainScreen](https://github.com/user-attachments/assets/b2904921-299e-4edb-92c6-509d77e8056d)
![Home Screen](screenshots/home_screen.png)

### Tree Details
![Screenshot_20250306_085601](https://github.com/user-attachments/assets/9c3162a5-a0ce-48de-aced-3dec3ef85014)
![Tree Details](screenshots/tree_details.png)

### Disease Detection
![Screenshot_20250306_085631](https://github.com/user-attachments/assets/3af0e474-8dc8-4c90-82b7-f76e40069d17)
![Disease Detection](screenshots/disease_detection.png)

### Treatment Steps
![Screenshot_20250306_085704](https://github.com/user-attachments/assets/21aa9a23-49ba-4696-ad2d-564659a038c6)
![Screenshot_20250306_085713](https://github.com/user-attachments/assets/c031de72-8977-444a-a854-74f0d0799015)
![Treatment Steps](screenshots/treatment_steps.png)

### Calendar View
![Screenshot_20250306_085752](https://github.com/user-attachments/assets/9b05f7e3-fedf-4ed7-b869-c33eb2881cbd)
![Calendar View](screenshots/calendar_view.png)

### Statistics Dashboard
![Screenshot_20250306_085808](https://github.com/user-attachments/assets/cf8fbf79-ebbf-4aa7-8a25-a03b5a2d941d)
![Statistics Dashboard](screenshots/statistics_dashboard.png)

## 🏗️ Architecture

GrowMate follows a modular architecture with clear separation of concerns:

### MVC Pattern
- **Model**: Data models for trees, diseases, treatments, etc.
- **View**: UI components and screens
- **Controller**: Business logic and data manipulation

### Key Components
- **Firebase Integration**: Authentication, Firestore, and Storage
- **TensorFlow Lite**: On-device machine learning for disease detection
- **Notification Service**: Local and push notification management
- **Location Services**: Google Maps integration

## 🛠️ Technologies Used

### Frontend
- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **Provider**: State management

### Backend & Services
- **Firebase Authentication**: User management
- **Cloud Firestore**: NoSQL database
- **Firebase Storage**: Image storage
- **Firebase Cloud Messaging**: Push notifications

### Machine Learning
- **TensorFlow Lite**: On-device ML model for disease detection
- **Custom-trained Model**: Image classification for leaf conditions

### Other Libraries
- **google_maps_flutter**: Location services
- **image_picker**: Camera and gallery integration
- **flutter_local_notifications**: Local notification management
- **intl**: Internationalization and formatting

## 💾 Database Structure

GrowMate uses Cloud Firestore with the following collections:

- **users**: User profiles and preferences
- **trees**: Individual tree information
- **diseases**: Disease information and treatments
- **treatment_steps**: Step-by-step treatment instructions
- **treatment_progress**: Records of treatment activities
- **care_tips**: Generic and specific tree care advice
- **care_tip_completions**: Record of completed care activities
- **scheduled_notifications**: Upcoming notifications

## 📥 Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/grow_mate.git
   cd grow_mate
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add Android and iOS apps to your Firebase project
   - Download and add the configuration files (google-services.json for Android, GoogleService-Info.plist for iOS)
   - Enable Authentication, Firestore, and Storage in the Firebase Console

4. **Set up the TensorFlow model**:
   - Download the disease detection model
   - Place it in the `assets` folder

5. **Run the app**:
   ```bash
   flutter run
   ```

## 🚀 Usage

1. **Create an account** using email and password
2. **Add your first tree** with photos, age, and location information
3. **Monitor tree health** by regularly uploading new photos for analysis
4. **Follow care tips** tailored to your tree's age and condition
5. **Track treatment progress** if disease is detected
6. **Check statistics** on the dashboard to monitor overall health
7. **Set up notifications** for regular care activities

## 🔮 Future Enhancements

- **Multi-language Support**: Localization for international users
- **Offline Mode**: Enhanced functionality without internet connection
- **Community Features**: Share tips and advice with other users
- **Advanced Analytics**: More detailed growth and health statistics
- **Expert Consultation**: In-app connection to tree health experts
- **Weather Integration**: Adapt care recommendations based on local weather
- **Expanded Plant Types**: Support for additional tree and plant varieties

## 👥 Contributors

- [Team Member 1](https://github.com/username1) - Role/Responsibility
- [Team Member 2](https://github.com/username2) - Role/Responsibility
- [Team Member 3](https://github.com/username3) - Role/Responsibility
- [Team Member 4](https://github.com/username4) - Role/Responsibility

## 📃 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ by [Your Team Name]
