# Identifyer - Face Recognition Attendance System

## Project Overview
Identifyer is a mobile application developed to automate attendance tracking in educational institutions using real-time facial recognition technology. This system eliminates the need for manual roll calls, enhances accuracy, and provides a streamlined attendance solution through an intuitive mobile interface. Built using Flutter for the frontend and Python for the backend, Identifyer leverages WebSockets for efficient real-time communication and Supabase for database management and authentication.

---

## Project Goals
- **Automate attendance** using advanced facial recognition.
- **Reduce administrative workload** by eliminating manual roll calls.
- **Ensure accurate attendance records** through real-time data collection.
- **Enable real-time monitoring** of attendance data by teachers and administrators.
- **Secure data storage** and provide easy data retrieval and export functionalities.
- **Provide seamless user experience** through an intuitive mobile interface.

---

## Key Technologies
- **Frontend:** Flutter (Dart)
- **Backend:** Python (WebSocket Server, DeepFace for facial recognition)
- **Database:** Supabase (PostgreSQL)
- **Storage Buckets:** Supabase Storage (for student images and session exports)
- **Face Detection:** Google ML Kit (on-device)
- **WebSocket Communication:** Real-time data exchange between the app and the server

---

## System Architecture
### Core Components
1. **Flutter Frontend:**
   - Manages the UI and user interactions.
   - Captures images periodically and sends them to the WebSocket server.
   - Displays real-time attendance status.
   - Allows teachers to manage sessions and export attendance reports.

2. **Python WebSocket Server:**
   - Receives image data from the frontend.
   - Uses DeepFace to analyze and recognize faces.
   - Compares incoming face data with stored embeddings.
   - Sends back real-time recognition results.

3. **Supabase Database:**
   - Stores all user, student, session, and attendance data.
   - Provides authentication services for secure login.
   - Enables role-based access to ensure data security.

4. **Supabase Storage Buckets:**
   - **studentinformation:** Stores student images used for facial recognition and profile records.
   - **sessions:** Stores exported Excel files generated at the end of each session containing attendance data.

5. **Real-time Communication:**
   - WebSocket facilitates instant communication between the frontend and backend.
   - Data flows bi-directionally, enabling low-latency attendance marking.

---

## Database Schema Breakdown

### 1. **Students Table**  
**Purpose:**  
Stores core student information and facial recognition embeddings used to verify identities during sessions. This table plays a central role in facial recognition and attendance tracking.  

**Columns:**  
- **id (uuid):** Unique identifier for each student.  
- **first_name (text):** Student’s first name.  
- **last_name (text):** Student’s last name.  
- **year (int2):** Academic year (e.g., 1, 2, 3).  
- **specialty (text):** Student’s field of study.  
- **group (text):** Class or group designation.  
- **email (text):** Student’s email address.  
- **phone (text):** Student’s contact number.  
- **embeddings (jsonb):** Facial embeddings stored in JSON format for facial recognition.  
- **created_at (timestamp):** Record creation date.  
- **isMale (bool):** Gender indicator (true/false).  

**Storage Integration:**  
- **Supabase Bucket:** `studentinformation` - Stores student profile images used for embedding generation.

---

### 2. **Attendance Table**  
**Purpose:**  
Logs attendance records for each session, providing a historical trail of student participation.  

**Columns:**  
- **id (uuid):** Unique identifier for each attendance record.  
- **student_id (uuid):** Links to the `Students` table.  
- **session_id (uuid):** Links to the `Sessions` table.  
- **timestamp (timestamp):** Marks the attendance time.  
- **status (text):** Records attendance status (`present`, `late`, `absent`).  
- **created_at (timestamp):** Attendance record creation date.  

**Storage Integration:**  
- **Supabase Bucket:** `sessions` - Stores attendance logs exported at the end of sessions.

---

### 3. **Sessions Table**  
**Purpose:**  
Defines and manages classroom or event sessions. This table governs session duration, participating groups, and responsible teachers.  

**Columns:**  
- **id (uuid):** Unique identifier for each session.  
- **year (text):** Academic year.  
- **specialty (text):** Associated field of study.  
- **group (text):** Designated class group.  
- **start_time (timestamp):** Session start time.  
- **end_time (timestamp):** Session end time.  
- **created_at (timestamp):** Session creation date.  
- **status (text):** Session status (`active`, `completed`).  
- **teacher (uuid):** Links to the `User` table to designate the responsible teacher.  

**Storage Integration:**  
- **Supabase Bucket:** `sessions` - Stores Excel reports containing final session summaries.

---

### 4. **User Table**  
**Purpose:**  
Holds authentication details for teachers and admins. This table manages login, permissions, and user profiles.  

**Columns:**  
- **id (uuid):** Unique identifier for each user.  
- **first_name (text):** User’s first name.  
- **last_name (text):** User’s last name.  
- **module (text):** Course or module the user manages.  
- **email (text):** User’s email for authentication.  
- **passkey (text):** Hashed password for security.  
- **created_at (timestamp):** Record creation date.  

**Storage Integration:**  
- **Supabase Bucket:** `user-profiles` - Contains profile pictures for teachers and admins.

---

## Workflow
1. **Student Enrollment:**
   - Admins create a new student by entering personal details and selecting the appropriate class.
   - A photo is uploaded and sent to the embeddings WebSocket to generate facial embeddings.
   - The photo is uploaded to the `studentinformation` bucket.
   - The student record, including embeddings, is saved in the database.
2. **Session Creation:**
   - Teachers create sessions and specify relevant class groups.
3. **Attendance Marking:**
   - The app sends real-time face data to the WebSocket server.
   - Matches are logged in the `Attendance` table.
4. **Report Generation:**
   - Upon session completion, Excel files are stored in the `sessions` bucket.

---

## Security
- **Supabase Buckets:** Role-based access control (RBAC) to ensure sensitive data is restricted.
- **Encryption:** Passkeys are encrypted.
- **Audits:** `created_at` timestamps track data changes.

---

## Conclusion
Identifyer leverages cutting-edge technology to simplify and enhance attendance tracking. The integration of Supabase for storage and WebSocket for real-time communication ensures a responsive and secure platform for educational institutions.

=======
# identifyer

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
>>>>>>> d600812 (Fix line endings and embedded git)
