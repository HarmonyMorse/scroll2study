# Beginnings

This guide outlines the basic setup from backend to frontend, ensuring you can run an iOS app integrated with Firebase Authentication and a simple personal counter. It also covers writing basic tests to confirm everything works as expected.

---

## 1. Create a New Firebase Project ✅

1. **Go to** [Firebase Console](https://console.firebase.google.com/).  
2. **Click** "Add project" and name it (e.g., `scroll2study`).  
3. **Enable** Google Analytics if needed (optional), then finalize project creation.

---

## 2. Add iOS App to Firebase ✅

1. **In** the Firebase console, **select** your new project.  
2. **Click** "Add app" → Choose the **iOS** icon.  
3. **Enter** your iOS app's Bundle ID (e.g., `com.myorg.scroll2study`).  
4. **Download** the `GoogleService-Info.plist` file when prompted.  
5. **Add** `GoogleService-Info.plist` to your iOS project root (make sure it's included in the Xcode project).

---

## 3. Backend Setup with Firebase Auth and a Simple "Personal Counter" ✅

### 3.1 Node.js + Express Quick Start ✅

1. **Initialize** a Node.js project:
   ```bash
   mkdir scroll2study-backend
   cd scroll2study-backend
   npm init -y
   ```
2. **Install** required dependencies:
   ```bash
   npm install express firebase-admin cors
   ```
3. **Set up** Firebase Admin SDK:
   - **Download** your Firebase Admin SDK service account key JSON file from the Firebase Console → Project Settings → Service Accounts.
   - **Put** it in a secure folder in your backend (commonly `/config` or use environment variables).
4. **Create** an `index.js` with a basic Express server and a personal counter route:
   ```js:path/to/your/backend/index.js
   const express = require('express');
   const cors = require('cors');
   const admin = require('firebase-admin');

   const app = express();
   app.use(cors());
   app.use(express.json());

   // Initialize Firebase Admin SDK
   admin.initializeApp({
     credential: admin.credential.cert(require('./config/serviceAccountKey.json')),
   });

   // Simple in-memory personal counter for demonstration
   // In a production setup, you'd likely store this in Firestore.
   let personalCounter = 0;

   // Test route
   app.get('/', (req, res) => {
     res.send({ message: 'Backend is running!' });
   });

   // Protected route: increment personal counter
   app.post('/incrementCounter', async (req, res) => {
     try {
       // Verify user's ID token
       const idToken = req.headers.authorization?.split('Bearer ')[1] || '';
       await admin.auth().verifyIdToken(idToken);

       // Increment the counter
       personalCounter += 1;
       res.send({ personalCounter });
     } catch (err) {
       res.status(401).send({ error: 'Unauthorized' });
     }
   });

   const PORT = process.env.PORT || 3000;
   app.listen(PORT, () =>
     console.log(`Server listening on port ${PORT}`)
   );
   ```

### 3.2 Testing the Backend ✅

1. **Install** a testing framework (e.g., Jest, supertest):
   ```bash
   npm install --save-dev jest supertest
   ```
2. **Configure** `package.json` for tests:
   ```json
   {
     "scripts": {
       "test": "jest"
     }
   }
   ```
3. **Create** a test file `index.test.js`:
   ```js:path/to/your/backend/index.test.js
   const request = require('supertest');
   const app = require('./index'); // if you export your Express app

   describe('Backend Tests', () => {
     it('should respond with a welcome message on /', async () => {
       const res = await request(app).get('/');
       expect(res.status).toBe(200);
       expect(res.body.message).toBe('Backend is running!');
     });
   });
   ```

4. **Run** tests:
   ```bash
   npm test
   ```

> **Tip:** For thorough testing, you'd mock Firebase Auth, but this basic test ensures your server runs.

---

## 4. iOS App Setup ✅

### 4.1 Create a New Swift/Xcode Project ✅

1. **Open** Xcode → "Create a new Xcode project."  
2. **Select** "App" under iOS.  
3. **Name** your project (e.g., `Scroll2Study`), and confirm the **Bundle Identifier** matches what you used in Firebase.

### 4.2 Integrate Firebase in iOS ✅

1. **Install** Firebase using Swift Package Manager or CocoaPods.

   **Using Swift Package Manager**:  
   - In Xcode, go to "File" → "Add Packages…"  
   - Add `https://github.com/firebase/firebase-ios-sdk.git`.  
   - Select **FirebaseAuth** and any other modules you want (e.g., **FirebaseFirestore** if needed).

2. **Initialize** Firebase at app startup:
   ```swift:path/to/ios/AppDelegate.swift
   import UIKit
   import Firebase

   @main
   class AppDelegate: UIResponder, UIApplicationDelegate {
       func application(
         _ application: UIApplication,
         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
       ) -> Bool {
           FirebaseApp.configure()
           return true
       }
   }
   ```

3. **Add** the `GoogleService-Info.plist` to your Xcode project (drag into the project navigator, ensuring it's included in the build).

---

## 5. Basic UI + Auth + Personal Counter Call ✅

### 5.1 SwiftUI View with Login ✅

Create a simple SwiftUI view that lets users log in anonymously and shows the personal counter:

```swift:YourApp/Views/ContentView.swift
import SwiftUI
import Firebase

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var counter = 0
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            if isLoggedIn {
                Text("Personal Counter: \(counter)")
                Button("Increment Counter") {
                    incrementCounter()
                }
                Button("Sign Out") {
                    signOut()
                }
            } else {
                Button("Sign In Anonymously") {
                    signInAnonymously()
                }
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
    
    private func signInAnonymously() {
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            isLoggedIn = true
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            counter = 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func incrementCounter() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "Not logged in"
            return
        }
        
        user.getIDToken() { token, error in
            guard let token = token else {
                errorMessage = error?.localizedDescription ?? "Failed to get token"
                return
            }
            
            // Replace with your backend URL
            guard let url = URL(string: "http://localhost:3000/incrementCounter") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        errorMessage = error.localizedDescription
                    }
                    return
                }
                
                if let data = data,
                   let response = try? JSONDecoder().decode(CounterResponse.self, from: data) {
                    DispatchQueue.main.async {
                        counter = response.personalCounter
                    }
                }
            }.resume()
        }
    }
}

struct CounterResponse: Codable {
    let personalCounter: Int
}
```

### 5.2 Testing the iOS Implementation ✅

Create basic tests to verify the authentication flow:

```swift:YourApp/Tests/ContentViewTests.swift
import XCTest
@testable import YourApp
import Firebase

class ContentViewTests: XCTestCase {
    var contentView: ContentView!
    
    override func setUp() {
        super.setUp()
        contentView = ContentView()
    }
    
    func testInitialState() {
        XCTAssertFalse(contentView.isLoggedIn)
        XCTAssertEqual(contentView.counter, 0)
        XCTAssertTrue(contentView.errorMessage.isEmpty)
    }
    
    // Note: For more comprehensive testing, you'd want to mock Firebase Auth
    // and the network calls. This is just a basic example.
}
```

---

## 6. Running the Complete System ✅

1. **Start** the backend server:
```bash
cd scroll2study-backend
node index.js
```

2. **Run** the iOS app in Xcode:
- Select your target device/simulator
- Press ⌘R or click the Play button

3. **Test** the flow:
- Launch the app
- Click "Sign In Anonymously"
- Once signed in, try incrementing the counter
- Verify the counter increases and persists
- Try signing out and back in

---

## Next Steps

After confirming this basic setup works, you can:

1. Add more sophisticated authentication methods (Google Sign-In, Email/Password)
2. Implement proper data persistence using Firestore
3. Add more features and UI polish
4. Set up proper environment configuration for different builds (dev/staging/prod)
5. Implement proper error handling and loading states