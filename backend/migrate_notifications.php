<?php
include_once 'db_connect.php';

echo "Starting Notifications Migration...<br>";

try {
    // 1. Add related_id column
    $checkColumn = $conn->query("SHOW COLUMNS FROM notifications LIKE 'related_id'");
    if ($checkColumn->rowCount() == 0) {
        $conn->exec("ALTER TABLE notifications ADD COLUMN related_id INT NULL AFTER message");
        echo "Added 'related_id' column.<br>";
    } else {
        echo "'related_id' column already exists.<br>";
    }

    // 2. Update type ENUM to include book_upload
    // Note: In local development, we can modify column types. 
    // In production, carefully check database compatibility.
    $conn->exec("ALTER TABLE notifications MODIFY COLUMN type ENUM('approval', 'book_request', 'book_upload') NOT NULL");
    echo "Updated 'type' ENUM to include 'book_upload'.<br>";

    echo "Migration completed successfully.";
} catch (PDOException $e) {
    echo "Migration failed: " . $e->getMessage();
}
?>
