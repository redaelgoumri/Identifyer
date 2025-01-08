# Identifyer - Face Recognition Attendance System

## Project Overview
Identifyer is a mobile application designed to automate attendance tracking in educational institutions using real-time facial recognition. Built with Flutter for the frontend and Python for the backend, Identifyer leverages WebSockets for seamless communication and Supabase for authentication and database management. The app aims to streamline administrative tasks, improve accuracy, and provide real-time data insights for teachers and administrators.

---

## Project Goals
- **Automate attendance** using facial recognition technology.
- **Enhance accuracy** and minimize manual entry errors.
- **Improve efficiency** by reducing the time taken for roll calls.
- **Enable real-time tracking** and reporting of attendance.
- **Simplify system access** through an intuitive mobile interface.
- **Store data securely** in Supabase, with backup and export options.

---

## Key Technologies
- **Frontend:** Flutter (Dart)
- **Backend:** Python (WebSocket Server, DeepFace for facial recognition)
- **Database:** Supabase (PostgreSQL, Supabase Storage for media files)
- **Face Detection:** Google ML Kit (on-device)
- **WebSocket Communication:** Real-time data transfer between app and server

---

## System Architecture
### Core Components
1. **Flutter Frontend:**
   - Handles user interactions (teacher/admin views).
   - Captures and sends images periodically to the WebSocket server.
   - Displays real-time attendance data and session management features.

2. **Python WebSocket Server:**
   - Receives images from the app.
   - Runs facial recognition using DeepFace.
   - Compares detected faces with stored embeddings to mark attendance.

3. **Supabase Database:**
   - Manages user authentication and role-based access.
   - Stores attendance records and session details.
   - Uploads and stores student photos for embedding.

4. **Real-time Communication:**
   - WebSocket ensures low-latency data exchange between the mobile app and backend.

---

## User Roles
1. **Admin:**
   - Manage teacher and student records.
   - Oversee attendance records and sessions.
   - Handle user permissions and roles.

2. **Teacher:**
   - Start and manage attendance sessions.
   - View real-time attendance data.
   - Export attendance reports.

3. **Student:**
   - Identified through facial recognition.
   - Attendance is recorded automatically.

---

## Application Workflow
### Login Process
- Unified login for both admins and teachers.
- Admins are redirected to the admin dashboard.
- Teachers proceed to session creation and management.

### Session Management
- Teachers create sessions specifying **year**, **specialty**, and **group**.
- WebSocket initializes a connection with session data.
- The app captures images periodically and sends them to the backend.

### Real-time Face Recognition
- The backend processes images, extracts embeddings, and compares them to stored student embeddings.
- Attendance records are updated instantly in Supabase.

### Data Export and Reports
- Admins and teachers can export attendance records to Excel.
- Data is securely stored and retrievable from Supabase Storage.

---

## UML Diagrams
### Use Case Diagram
```plaintext
+------------------+           +---------------+
|   Admin          |           |   Teacher     |
+------------------+           +---------------+
| - Manage Users   |           | - Start Session|
| - View Reports   |           | - Track Atten. |
| - Manage Classes |           | - Export Data  |
+------------------+           +---------------+
                |                         |
                +-------------------------+
                                |
                           +---------+
                           | Student |
                           +---------+
                           | - Attend|
                           +---------+
```

### Class Diagram
```plaintext
+------------------+       +------------------+
|    User          |       |     Session      |
+------------------+       +------------------+
| - id             |       | - sessionId      |
| - name           |       | - year           |
| - role           |       | - specialty      |
| - email          |       | - group          |
+------------------+       +------------------+
            |                     |
            +---------------------+
                          |
                    +---------+
                    |   Att.  |
                    +---------+
```

---

## Gantt Chart

```plaintext
+----------------------------+---------------+----------------+----------------+
|        Task                |  Start Date   |   End Date     |    Duration    |
+----------------------------+---------------+----------------+----------------+
| Project Initialization     |  Jan 1, 2025  |  Jan 15, 2025  |     15 Days    |
| Frontend Development       |  Jan 16, 2025 |  Feb 15, 2025  |     30 Days    |
| Backend Development        |  Feb 16, 2025 |  Mar 20, 2025  |     33 Days    |
| WebSocket Integration      |  Mar 21, 2025 |  Apr 10, 2025  |     20 Days    |
| Testing & Debugging        |  Apr 11, 2025 |  May 10, 2025  |     30 Days    |
| Deployment & Review        |  May 11, 2025 |  May 30, 2025  |     19 Days    |
+----------------------------+---------------+----------------+----------------+
```

---

## Next Steps
1. **Resolve ML Kit Plugin Issues** for local face detection.
2. **Implement Multi-Instance WebSocket Mapping** to manage multiple teacher sessions simultaneously.
3. **Optimize Image Capture** to transmit only when faces are detected.

---

## Security Considerations
- **Role-Based Access Control** (RBAC) ensures sensitive operations are restricted.
- **Data Encryption** during communication.
- **Supabase Authentication** ensures secure access to resources.

---

## Conclusion
Identifyer represents a scalable and efficient solution for attendance tracking in educational institutions. By integrating modern technologies like facial recognition and real-time data synchronization, the system significantly reduces administrative overhead, improves accuracy, and enhances the overall educational experience.

