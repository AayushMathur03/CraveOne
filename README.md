# 🍽️ CraveOne – A Restaurant App

CraveOne is a sleek and user-friendly restaurant application developed using Flutter. It provides users with an interactive way to explore different cuisines and order their favorite dishes.

> This app was developed as part of a Flutter assignment and follows all specified constraints – **no third-party libraries**, **clean native UI**, and **handling of edge cases**.

---

## 🚀 Features

### 🏠 Home Screen

The main screen includes four major segments:

#### 1. Cuisine Category Cards
- Horizontally scrollable (infinite scroll both sides)
- Displays one card at a time
- Each card includes:
  - Cuisine image
  - Cuisine name
  - Rounded rectangular design
- On tap, navigates to the selected cuisine screen (Screen 2)

#### 2. Top 3 Famous Dishes
- Presented in tile format
- Each tile includes:
  - Image
  - Price
  - Rating
  - Option to add the same dish multiple times

#### 3. Cart Button
- Allows navigation to Cart Screen (Screen 3)

#### 4. Language Toggle
- Toggle between **English** and **Hindi**

---

### 🍽️ Cuisine Screen (Screen 2)

Displays dishes based on the selected cuisine category.

- Each dish card includes:
  - Dish image
  - Price
  - Option to add the dish multiple times

---

### 🛒 Cart Screen (Screen 3)

Shows all selected dishes and pricing breakdown.

- List of selected cuisines and dishes
- Net Total
- CGST and SGST (2.5% each)
- Grand Total (Net Total + Taxes)
- Button to Place Order

---

## 🧑‍💻 Tech Stack

- **Framework**: Flutter
- **Languages**: Dart
- **Architecture**: Widget-based Native UI
- **Multilingual Support**: English and Hindi
- **No third-party packages used** as per assignment requirements

---

## 📦 Setup Instructions

Follow these steps to run the project locally:

### ✅ Prerequisites
- Flutter SDK installed → [Flutter Installation Guide](https://docs.flutter.dev/get-started/install)
- Git installed
- VS Code or Android Studio with Flutter plugin

### 📁 Clone the Repository

```bash
git clone https://github.com/your-username/craveone.git
cd craveone
```
## 📥 Get Dependencies
```bash
flutter pub get
```

##  ▶️ Run the App
Connect a physical device or emulator and run:
```bash
flutter run
```

