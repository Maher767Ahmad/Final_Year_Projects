<?php
include 'db_connect.php';
$stmt = $conn->query("SELECT * FROM book_requests");
$reqs = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo json_encode($reqs, JSON_PRETTY_PRINT);
?>
