<?php
include_once 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];
$endpoint = $_GET['endpoint'] ?? $_SERVER['PATH_INFO'] ?? '';

if ($method == 'GET' && strpos($endpoint, '/user/') !== false) {
    $uid = basename($endpoint);
    $query = "SELECT * FROM notifications WHERE user_id = :uid ORDER BY created_at DESC";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':uid', $uid);
    $stmt->execute();
    $notifs = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(["data" => $notifs]);
} elseif ($method == 'GET' && strpos($endpoint, '/unread/') !== false) {
    $uid = basename($endpoint);
    $query = "SELECT COUNT(*) as count FROM notifications WHERE user_id = :uid AND read_status = 0";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':uid', $uid);
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    echo json_encode(["count" => $result['count']]);
}

if ($method == 'PUT' && strpos($endpoint, '/read/') !== false) {
    $nid = basename($endpoint);
    $query = "UPDATE notifications SET read_status = 1 WHERE id = :nid";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':nid', $nid);
    $stmt->execute();
    echo json_encode(["message" => "Notification marked as read"]);
} elseif ($method == 'PUT' && strpos($endpoint, '/read-all/') !== false) {
    $uid = basename($endpoint);
    $query = "UPDATE notifications SET read_status = 1 WHERE user_id = :uid";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':uid', $uid);
    $stmt->execute();
    echo json_encode(["message" => "All notifications marked as read"]);
}
?>
