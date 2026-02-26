<?php
include 'db_connect.php';
$stmt = $conn->query("SELECT * FROM notifications ORDER BY created_at DESC");
$notifs = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo json_encode($notifs, JSON_PRETTY_PRINT);
?>
