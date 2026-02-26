CREATE DATABASE IF NOT EXISTS bgnu_library;
USE bgnu_library;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('Super Admin', 'Teacher Admin', 'Student') NOT NULL,
    department VARCHAR(100) NOT NULL,
    approved_subjects TEXT, -- JSON array of strings
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    id_card_url TEXT,
    profile_picture TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS books (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    department VARCHAR(100) NOT NULL,
    subject VARCHAR(100) NOT NULL,
    file_url TEXT NOT NULL,
    cover_image TEXT,
    access_type ENUM('read', 'download') DEFAULT 'read',
    uploaded_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS book_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    department VARCHAR(100) NOT NULL,
    book_name VARCHAR(255) NOT NULL,
    status ENUM('pending', 'fulfilled', 'rejected') DEFAULT 'pending',
    requested_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fulfilled_by INT,
    fulfilled_date TIMESTAMP NULL,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (fulfilled_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    type ENUM('approval', 'book_request', 'book_upload') NOT NULL,
    message TEXT NOT NULL,
    related_id INT NULL,
    read_status BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
