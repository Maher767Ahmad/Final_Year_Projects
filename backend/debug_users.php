<?php
include 'db_connect.php';
$stmt = $conn->query("SELECT id, name, email, role, status, department FROM users");
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo json_encode($users, JSON_PRETTY_PRINT);
?>
