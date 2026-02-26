<?php
ini_set('display_errors', 0); // Turned off to prevent HTML warnings breaking JSON
ini_set('display_startup_errors', 0);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$target_dir = "uploads/";
if (!file_exists($target_dir)) {
    if (!mkdir($target_dir, 0777, true)) {
        http_response_code(500);
        echo json_encode(["message" => "Failed to create directory. Check permissions."]);
        exit();
    }
}

if (!empty($_FILES['file'])) {
    $file_name = basename($_FILES["file"]["name"]);
    $target_file = $target_dir . uniqid() . "_" . $file_name;
    $imageFileType = strtolower(pathinfo($target_file, PATHINFO_EXTENSION));

    // Allow certain file formats
    $allowed_types = ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'];
    if (!in_array($imageFileType, $allowed_types)) {
        http_response_code(400);
        echo json_encode(["message" => "File type not allowed"]);
        exit();
    }

    if (move_uploaded_file($_FILES["file"]["tmp_name"], $target_file)) {
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
        $url = $protocol . "://" . $_SERVER['HTTP_HOST'] . "/BACKEND/" . $target_file;
        echo json_encode(["url" => $url]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Sorry, there was an error uploading your file."]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "No file uploaded"]);
}
?>
