class AppConstants {
  // App Info
  static const String appName = 'ALU Connect';
  static const String appTagline = 'Bridging ALU Students & Startups';
  static const String appVersion = '1.0.0';

  // ALU Domain for email validation
  static const String aluEmailDomain = 'alueducation.com';
  static const String aluStudentDomain = 'student.alueducation.com';
  static const String aluStudentDomain2 = 'alustudent.com';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String startupsCollection = 'startups';
  static const String opportunitiesCollection = 'opportunities';
  static const String applicationsCollection = 'applications';
  static const String bookmarksCollection = 'bookmarks';
  static const String notificationsCollection = 'notifications';
  static const String messagesCollection = 'messages';
  static const String chatsCollection = 'chats';
  static const String reviewsCollection = 'reviews';

  // User Roles
  static const String roleStudent = 'student';
  static const String roleStartup = 'startup';
  static const String roleAdmin = 'admin';

  // Startup Verification Status
  static const String statusPending = 'pending';
  static const String statusVerified = 'verified';
  static const String statusRejected = 'rejected';

  // Application Status
  static const String appStatusPending = 'pending';
  static const String appStatusReviewing = 'reviewing';
  static const String appStatusShortlisted = 'shortlisted';
  static const String appStatusAccepted = 'accepted';
  static const String appStatusRejected = 'rejected';
  static const String appStatusWithdrawn = 'withdrawn';

  // Opportunity Types
  static const List<String> opportunityTypes = [
    'Software Development',
    'UI/UX Design',
    'Marketing',
    'Business Analysis',
    'Operations',
    'Research',
    'Content Creation',
    'Community Management',
    'Data Science',
    'Finance',
    'Sales',
    'Product Management',
  ];

  // ALU Campuses
  static const List<String> aluCampuses = [
    'Kigali, Rwanda',
    'Mauritius',
    'Lagos, Nigeria',
    'Nairobi, Kenya',
  ];

  // Duration Options
  static const List<String> durationOptions = [
    '1 month',
    '2 months',
    '3 months',
    '4 months',
    '6 months',
    'Flexible',
  ];

  // ALU recognized startup categories
  static const List<String> startupCategories = [
    'EdTech',
    'FinTech',
    'HealthTech',
    'AgriTech',
    'CleanTech',
    'E-commerce',
    'Social Impact',
    'Media & Entertainment',
    'Logistics',
    'SaaS',
    'AI & ML',
    'Other',
  ];

  // ALU Program Years
  static const List<String> programYears = [
    'Year 1',
    'Year 2',
    'Year 3',
    'Year 4',
    'Alumni',
  ];

  // ALU Majors
  static const List<String> aluMajors = [
    'Computer Science',
    'Business Administration',
    'Global Challenges',
    'Electrical Engineering',
    'International Business & Trade',
    'Entrepreneurship',
    'Software Engineering',
    'Data Science & AI',
  ];
}
