<?php
include 'db_connect.php';
$stmt = $conn->query("SELECT DISTINCT department FROM users");
$depts = $stmt->fetchAll(PDO::FETCH_COLUMN);
echo json_encode($depts);
?>
