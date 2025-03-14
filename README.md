# GrowMate 🌱

A comprehensive Flutter application for coconut tree management and disease detection, designed to help farmers and tree owners monitor their trees' health, implement treatment plans, and maintain optimal growing conditions.

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

## ✨ Features

### 🌳 Tree Management
- **Add and Track Trees**: Register individual trees with photos, age, and location
- **Edit Tree Details**: Update information as trees grow or conditions change
- **Photo Gallery**: Visual history of each tree with multiple images
- **Location Tracking**: Integrates with Google Maps to record tree positions

### 🔬 Disease Detection & Treatment
- **AI-Powered Analysis**: Image recognition for early disease detection
- **Disease Information**: Comprehensive database of common tree diseases
- **Step-by-Step Treatment**: Guided treatment plans customized for each disease
- **Progress Tracking**: Monitor treatment effectiveness over time

#### ML Disease Detection Results
![4](https://github.com/user-attachments/assets/a4724443-1f1d-4144-83b9-b3b8cbb95dcf)

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

## 📱 Screenshots
![1](https://github.com/user-attachments/assets/b59895c2-ae1b-4a49-b380-ca69f049fe26)
![2](https://github.com/user-attachments/assets/1a0d4237-fdc9-4953-88e3-e67f21bb3bc1)
![3](https://github.com/user-attachments/assets/c0dc1800-a72c-42ee-b872-f842aed04cc9)

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

A comprehensive user guide is available within the app, providing detailed instructions for all features and functionality.

## 🔮 Future Enhancements

- **Multi-language Support**: Localization for international users
- **Offline Mode**: Enhanced functionality without internet connection
- **Live Chat Support**: In-app customer service and expert consultation
- **Dark Mode**: Alternative UI theme for better visibility in low-light conditions
- **Location-based Tips**: Customized advice based on local climate and growing conditions
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
