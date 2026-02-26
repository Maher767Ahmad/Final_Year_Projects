<?php
header("Content-Type: application/json");
echo json_encode([
    "PATH_INFO" => $_SERVER['PATH_INFO'] ?? 'NOT SET',
    "REQUEST_URI" => $_SERVER['REQUEST_URI'] ?? 'NOT SET',
    "SCRIPT_NAME" => $_SERVER['SCRIPT_NAME'] ?? 'NOT SET',
    "PHP_SELF" => $_SERVER['PHP_SELF'] ?? 'NOT SET'
]);
?>
