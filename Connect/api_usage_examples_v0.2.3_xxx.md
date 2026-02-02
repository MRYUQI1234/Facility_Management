# Facility Management System - API Usage Examples
Base URL: `http://localhost:3000/api` (Local)
Ngrok URL: `https://<your-id>.ngrok-free.app/api`

> [!IMPORTANT]
> **NGROK USERS**: If you are testing with the **Free Tier of Ngrok**, you MUST add the header `ngrok-skip-browser-warning: true` to **ALL** requests. 
> Without this, Ngrok returns an HTML warning page instead of JSON, causing parsing errors in your app.

## 1. Registration
Endpoint: `POST /auth/register`

### JavaScript (Fetch API)
```javascript
async function registerUser(email, password, name, phone, houseId) {
    try {
        const response = await fetch('http://localhost:3000/api/auth/register', {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'ngrok-skip-browser-warning': 'true' // <--- ADD THIS FOR NGROK
            },
            body: JSON.stringify({
                email: email,
                password: password,
                name: name,         // Required
                phone: phone,       // Required (e.g., +66812345678)
                houseId: houseId,   // Required (e.g., House_A1)
                role: "resident"
            })
        });

        const data = await response.json();
        if (response.ok) {
            console.log("Registration Success:", data);
        } else {
            console.error("Registration Failed:", data.error);
        }
    } catch (error) {
        console.error("Network Error:", error);
    }
}
```

---

## 2. Session Management

### 2.1 Start Session (Login)
Endpoint: `POST /auth/login`
**Instruction**: On success, store the `token` in `localStorage` or `sessionStorage`.

```javascript
async function loginUser(email, password) {
    try {
        const response = await fetch('http://localhost:3000/api/auth/login', {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'ngrok-skip-browser-warning': 'true' // <--- ADD THIS FOR NGROK
            },
            body: JSON.stringify({ email, password })
        });

        const data = await response.json();

        if (response.ok) {
            console.log("Login Success!");
            console.log("Session Token:", data.token);
            
            // INSTRUCTION: Store the token
            localStorage.setItem('authToken', data.token);
            localStorage.setItem('userId', data.userId);
            
            // Optional: Fetch Profile immediately
            await getSessionProfile();
        } else {
            console.error("Login Failed:", data.error);
        }
    } catch (error) {
        console.error("Network Error:", error);
    }
}
```

### 2.2 Get Current Session Profile (Check Session)
Endpoint: `GET /auth/me`
**Instruction**: Call this to check if the user is currently logged in.

```javascript
// Helper to get headers (Updated for Ngrok)
function getAuthHeaders() {
    const token = localStorage.getItem('authToken');
    return {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
        'ngrok-skip-browser-warning': 'true' // <--- CRITICAL FOR NGROK
    };
}

async function getSessionProfile() {
    const token = localStorage.getItem('authToken');
    if (!token) return console.log("No active session");

    try {
        const response = await fetch('http://localhost:3000/api/auth/me', {
            method: 'GET',
            headers: getAuthHeaders() // Use helper
        });

        if (response.status === 401) {
            console.log("Session Expired");
            localStorage.removeItem('authToken'); // Cleanup
            return;
        }

        // Check if response is actually JSON (Ngrok might still block if header missing)
        const contentType = response.headers.get("content-type");
        if (contentType && contentType.indexOf("application/json") === -1) {
             const text = await response.text();
             console.error("Expected JSON but got:", text);
             return;
        }

        const profile = await response.json();
        console.log("Current User:", profile);
    } catch (error) {
        console.error("Error:", error);
    }
}
```

---

## 3. PIN Management

### Set PIN (POST /auth/pin)
```javascript
async function setPin(userId, pin) {
    const response = await fetch('http://localhost:3000/api/auth/pin', {
        method: 'POST',
        headers: { 
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true'
        },
        body: JSON.stringify({ userId, pin })
    });
    console.log(await response.json());
}
```

### Get PIN (GET /auth/pin/:userId)
```javascript
async function getUserPin(userId) {
    const response = await fetch(`http://localhost:3000/api/auth/pin/${userId}`, {
        headers: { 'ngrok-skip-browser-warning': 'true' }
    });
    console.log(await response.json());
}
```

---

## 4. AI Repair Reporting

### Analyze Request (POST /ai/analyze)
```javascript
async function analyzeRepair(userId, prompt, objectsInScene) {
    const response = await fetch('http://localhost:3000/api/ai/analyze', {
        method: 'POST',
        headers: { 
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true'
        },
        body: JSON.stringify({ 
            userId, 
            prompt,
            objects: objectsInScene 
        })
    });
    console.log(await response.json());
}
```
