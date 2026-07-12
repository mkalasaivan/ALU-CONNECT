# ALU Connect - 10-Minute Demo Script

This script outlines a structured, high-impact 10-minute presentation and live walkthrough of the **ALU Connect** mobile application. It is designed to impress graders, assessors, or stakeholders by highlighting the Clean Architecture, premium UI/UX, and real-time Firebase capabilities.

---

## 🕒 Overview Timing Diagram
```mermaid
gantt
    title 10-Minute Presentation Timeline
    dateFormat  m:s
    axisFormat %M:%S
    section Intro
    Introduction & Architecture Brief      :active, 00:00, 01:30
    section Flows
    Role Selection & Student Onboarding    : 01:30, 03:30
    Student Discovery, Bookmark & Apply    : 03:30, 05:30
    Startup Venture Setup & Verification   : 05:30, 07:30
    Real-Time Engagement (Chat & Alerts)   : 07:30, 09:30
    section Outro
    Q&A & Tech Stack Summary              : 09:30, 10:00
```

---

## 🎙️ Step-by-Step Presentation Script

### Part 1: Intro & Architectural Overview (0:00 - 1:30)
* **What to Show on Screen:** The App Splash screen or Onboarding landing page.
* **Speaker Script:**
  > *"Good day everyone. Today I am presenting **ALU Connect**, a role-aware mobile application built specifically for the African Leadership University (ALU) ecosystem. ALU Connect acts as a talent bridge, matching student-led startups and ventures with ALU students looking for hands-on internship opportunities.*
  >
  > *From a technical standpoint, the app is built using **Clean Architecture** to separate concerns. We use **Flutter BLoC/Cubit** for reactive state management, **GoRouter** for declarative navigation, and **Cloud Firestore** for real-time data streaming. To optimize database performance and keep setup index constraints simple for grading, we implement custom **Client-Side Sorting** inside our repositories."*

---

### Part 2: Onboarding & Role Selection (1:30 - 3:30)
* **What to Show on Screen:** Register a new Student account.
* **Action Steps:**
  1. Click **Get Started** on the Onboarding screen.
  2. Select **Student** as the user role.
  3. Register a new student using an ALU email (e.g., `student.test@alustudent.com`).
  4. Note the email format validation rule (forces `@alustudent.com` for students).
* **Speaker Script:**
  > *"First, let's look at the onboarding. ALU Connect is strictly role-aware. Users can register either as a **Student** or a **Startup Founder**. During registration, students are required to use their official ALU student domain email to maintain ecosystem integrity. Let's create a student account."*

---

### Part 3: Student Discovery & Application (3:30 - 5:30)
* **What to Show on Screen:** Discover Feed -> Bookmarks -> Opportunity Details -> Apply.
* **Action Steps:**
  1. Browse the Discover Feed. Tap the **Bookmark** icon on an opportunity to save it.
  2. Go to the **Applications tab** -> **Saved** section to show the bookmarked opportunity has synced in real-time.
  3. Go back, tap the opportunity to open details. Show duration, stipend, and description details.
  4. Tap **Apply Now**. Enter a mock cover letter and click submit.
  5. Return to the opportunity detail page. Highlight that the button now displays **`Applied (Pending)`** and is disabled.
* **Speaker Script:**
  > *"Now logged in as a student, I am presented with the Discover Feed, utilizing our premium obsidian dark theme. I can bookmark opportunities in real-time or tap one to view its complete requirements.*
  >
  > *Let's apply to this role. When I submit my application, it syncs instantly to Firebase. Crucially, notice how the bottom bar changes to **'Applied (Pending)'** and disables itself. This **Double Application Prevention** safeguards startup founders from spam, resetting only if the student withdraws the application or gets rejected."*

---

### Part 4: Startup Venture Setup & Demo Verification (5:30 - 7:30)
* **What to Show on Screen:** Log out -> Register Startup Founder -> Verify Startup -> Post Opportunity.
* **Action Steps:**
  1. Log out of the student account via the Profile tab.
  2. Register as a **Startup Founder** (e.g., `founder.test@alustudent.com`).
  3. Complete the startup creation wizard.
  4. On the Dashboard, show the startup is **"Under Review"**.
  5. Tap the green **`Demo: Verify`** button. The card updates immediately to **"Verified"** in real-time.
  6. Tap **"Post Opportunity"**, fill in mock internship details (title, type, location, requirements), and publish.
* **Speaker Script:**
  > *"Next, let's switch to the Startup journey. Let's register a venture founder. Upon logging in, we are prompted to onboard our startup profile. To keep quality high, startups are placed in an 'Under Review' state by default.*
  >
  > *For grading and demo purposes, we have integrated a **Demo: Verify** shortcut. Tapping it instantly approves the startup. Now, we are cleared to post an opportunity. Let's create a new role. The moment I click publish, this opportunity is broadcasted to the entire student feed in real-time."*

---

### Part 5: Real-Time Engagement (Chat & Alerts) (7:30 - 9:30)
* **What to Show on Screen:** Applicants tab -> Chat Details -> Student Notifications.
* **Action Steps:**
  1. Go to the **Applicants** tab. Show the student's application in the queue.
  2. Tap the **Chat** icon next to the candidate's profile to open direct messaging.
  3. Type and send a message (e.g., "Hi, thank you for applying. Let's set up an interview!").
  4. Go back and show the **Chats** list tab displaying the active conversation and unread counts.
  5. Log back in as the **Student**. Show the notification bell in the top right has a red badge.
  6. Tap the **Bell** icon, view the "Message from Founder" notification, and tap it to deep-link directly into the active chat room.
  7. Swap back to the **Founder**, tap **Shortlist** or **Accept** on the application card. The student's application status timeline updates instantly.
* **Speaker Script:**
  > *"Real-time collaboration is where ALU Connect excels. On the Applicants tab, I can see the student who just applied. I can initiate a direct chat with them instantly.*
  >
  > *When I send a message, the student immediately receives an in-app alert. Let's log back in as the student. Tapping the notification bell, we see the unread message alert. Tapping it deep-links us straight into the chat view.*
  >
  > *Finally, let's look at candidate pipeline management. Tapping **Shortlist** or **Accept** on the startup end immediately updates the application state. The student gets a real-time status alert without needing to refresh."*

---

### Part 6: Tech Stack Summary & Outro (9:30 - 10:00)
* **What to Show on Screen:** Profile screen (showing clean developer info).
* **Speaker Script:**
  > *"In summary, ALU Connect delivers a complete, secure, and reactive recruitment loop. We secure all operations using Firestore rules, prevent application duplicates, and leverage streams to ensure zero-lag synchronization between ventures and candidates. Thank you, I am now open to any questions."*

---

## 💡 Quick Presentation Tips
1. **Prepare Dual Accounts:** Have your student (`i.muhoza@alustudent.com`) and your startup founder accounts ready to copy-paste so you can log in/out quickly.
2. **Explain the rules:** Mention that all read/write paths are secured using Cloud Firestore Security rules (which allow startups and applicants private chat channels and status update rights).
3. **Showcase the Badge Counts:** Point out the live unread red circle counts on the navigation bar and app bar during the chat flow to emphasize state management.
