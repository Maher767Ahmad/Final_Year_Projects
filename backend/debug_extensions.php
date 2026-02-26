<?php
include 'db_connect.php';
$stmt = $conn->query("SELECT id, title, file_url FROM books");
$books = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo json_encode($books, JSON_PRETTY_PRINT);
?>
