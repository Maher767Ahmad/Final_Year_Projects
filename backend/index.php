<?php
include_once 'db_connect.php';

$endpoint = $_GET['endpoint'] ?? $_SERVER['PATH_INFO'] ?? '';

// Dispatch based on the first part of the endpoint
if (empty($endpoint)) {
    echo json_encode(["status" => "online", "message" => "BGNU Library API is running"]);
    exit();
}

if (strpos($endpoint, '/users') === 0) {
    // Forward to users.php
    $_GET['endpoint'] = substr($endpoint, 6); // Remove '/users'
    include 'users.php';
} elseif (strpos($endpoint, '/books') === 0) {
    // Forward to books.php
    $_GET['endpoint'] = substr($endpoint, 6); // Remove '/books'
    include 'books.php';
} elseif (strpos($endpoint, '/approvals') === 0) {
    // Forward to approvals.php
    $_GET['endpoint'] = substr($endpoint, 10); // Remove '/approvals'
    include 'approvals.php';
} elseif (strpos($endpoint, '/book_requests') === 0) {
    // Forward to book_requests.php
    $_GET['endpoint'] = substr($endpoint, 14); // Remove '/book_requests'
    include 'book_requests.php';
} elseif (strpos($endpoint, '/notifications') === 0) {
    // Forward to notifications.php
    $_GET['endpoint'] = substr($endpoint, 14); // Remove '/notifications'
    include 'notifications.php';
} elseif (strpos($endpoint, '/upload') === 0) {
    // Forward to upload.php
    include 'upload.php';
} else {
    http_response_code(404);
    echo json_encode(["message" => "Endpoint not found: " . $endpoint]);
}
?>
