<?php
include_once 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];
$endpoint = $_GET['endpoint'] ?? $_SERVER['PATH_INFO'] ?? '';

if ($method == 'GET') {
    if (strpos($endpoint, '/teachers') !== false) {
        $query = "SELECT * FROM users WHERE role = 'Teacher Admin' AND status = 'pending'";
        $stmt = $conn->prepare($query);
        $stmt->execute();
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($users as &$user) {
            $user['approved_subjects'] = json_decode($user['approved_subjects']);
        }
        echo json_encode(["data" => $users]);
    } elseif (strpos($endpoint, '/students/') !== false) {
        $dept = urldecode(basename($endpoint));
        $query = "SELECT * FROM users WHERE role = 'Student' AND status = 'pending' AND department = :dept";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':dept', $dept);
        $stmt->execute();
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($users as &$user) {
            $user['approved_subjects'] = json_decode($user['approved_subjects']);
        }
        echo json_encode(["data" => $users]);
    }
}

if ($method == 'POST' && strpos($endpoint, '/update') !== false) {
    $data = json_decode(file_get_contents("php://input"));

    if (!empty($data->user_id) && !empty($data->status)) {
        $query = "UPDATE users SET status = :status WHERE id = :id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':status', $data->status);
        $stmt->bindParam(':id', $data->user_id);

        if ($stmt->execute()) {
            // Create notification for the user
            $msg = "Your account has been " . $data->status;
            $notif = "INSERT INTO notifications (user_id, type, message) VALUES (:uid, 'approval', :msg)";
            $nstmt = $conn->prepare($notif);
            $nstmt->bindParam(':uid', $data->user_id);
            $nstmt->bindParam(':msg', $msg);
            $nstmt->execute();

            echo json_encode(["message" => "Status updated successfully"]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Unable to update status"]);
        }
    }
}
?>
