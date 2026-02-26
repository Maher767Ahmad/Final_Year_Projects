<?php
include_once 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];
$endpoint = $_GET['endpoint'] ?? $_SERVER['PATH_INFO'] ?? '';

if ($method == 'GET') {
    if (strpos($endpoint, '/student/') !== false) {
        $sid = basename($endpoint);
        $query = "SELECT r.*, u.name as fulfilled_by_name FROM book_requests r LEFT JOIN users u ON r.fulfilled_by = u.id WHERE r.student_id = :sid";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':sid', $sid);
        $stmt->execute();
        $reqs = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(["data" => $reqs]);
    } elseif (strpos($endpoint, '/department/') !== false) {
        $dept = urldecode(basename($endpoint));
        $query = "SELECT r.*, u.name as student_name FROM book_requests r JOIN users u ON r.student_id = u.id WHERE r.department = :dept ORDER BY (r.status = 'pending') DESC, r.requested_date DESC";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':dept', $dept);
        $stmt->execute();
        $reqs = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(["data" => $reqs]);
    } elseif (strpos($endpoint, '/all') !== false) {
        // For Super Admin: Fetch ALL requests across departments
        $query = "SELECT r.*, u.name as student_name FROM book_requests r JOIN users u ON r.student_id = u.id ORDER BY (r.status = 'pending') DESC, r.department, r.requested_date DESC";
        $stmt = $conn->prepare($query);
        $stmt->execute();
        $reqs = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(["data" => $reqs]);
    }
}

if ($method == 'POST' && strpos($endpoint, '/submit') !== false) {
    $data = json_decode(file_get_contents("php://input"));

    if (!empty($data->student_id) && !empty($data->book_name)) {
        $query = "INSERT INTO book_requests (student_id, department, book_name) VALUES (:sid, :dept, :name)";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':sid', $data->student_id);
        $stmt->bindParam(':dept', $data->department);
        $stmt->bindParam(':name', $data->book_name);

        if ($stmt->execute()) {
            echo json_encode(["message" => "Request submitted successfully"]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Unable to submit request"]);
        }
    }
}
?>
