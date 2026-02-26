<?php
include_once 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];
$endpoint = $_GET['endpoint'] ?? $_SERVER['PATH_INFO'] ?? '';

if ($method == 'GET') {
    if (strpos($endpoint, '/search') !== false) {
        // Search endpoint - searches across title, author, department, and subject
        $searchQuery = $_GET['q'] ?? '';
        
        if (!empty($searchQuery)) {
            $searchTerm = '%' . $searchQuery . '%';
            $query = "SELECT b.*, u.name as uploader_name 
                      FROM books b 
                      JOIN users u ON b.uploaded_by = u.id 
                      WHERE b.title LIKE :search 
                         OR b.author LIKE :search 
                         OR b.department LIKE :search 
                         OR b.subject LIKE :search 
                      ORDER BY b.created_at DESC";
            $stmt = $conn->prepare($query);
            $stmt->bindParam(':search', $searchTerm);
            $stmt->execute();
            $books = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(["data" => $books]);
        } else {
            echo json_encode(["data" => []]);
        }
    } elseif (strpos($endpoint, '/recent') !== false) {
        $query = "SELECT b.*, u.name as uploader_name FROM books b JOIN users u ON b.uploaded_by = u.id ORDER BY b.created_at DESC LIMIT 10";
        $stmt = $conn->prepare($query);
        $stmt->execute();
        $books = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(["data" => $books]);
    } elseif (strpos($endpoint, '/department/') !== false) {
        $dept = urldecode(basename($endpoint));
        $query = "SELECT b.*, u.name as uploader_name FROM books b JOIN users u ON b.uploaded_by = u.id WHERE b.department = :dept ORDER BY b.subject";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':dept', $dept);
        $stmt->execute();
        $books = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(["data" => $books]);
    } elseif (strpos($endpoint, '/id/') !== false) {
        $id = basename($endpoint);
        $query = "SELECT b.*, u.name as uploader_name FROM books b JOIN users u ON b.uploaded_by = u.id WHERE b.id = :id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $book = $stmt->fetch(PDO::FETCH_ASSOC);
        echo json_encode(["data" => $book]);
    }
}

if ($method == 'POST' && strpos($endpoint, '/upload') !== false) {
    $data = json_decode(file_get_contents("php://input"));

    if (!empty($data->title) && !empty($data->file_url)) {
        $query = "INSERT INTO books (title, author, department, subject, file_url, access_type, uploaded_by) 
                  VALUES (:title, :author, :dept, :subject, :url, :access, :uploader)";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':title', $data->title);
        $stmt->bindParam(':author', $data->author);
        $stmt->bindParam(':dept', $data->department);
        $stmt->bindParam(':subject', $data->subject);
        $stmt->bindParam(':url', $data->file_url);
        $stmt->bindParam(':access', $data->access_type);
        $stmt->bindParam(':uploader', $data->uploaded_by);

        if ($stmt->execute()) {
            $newBookId = $conn->lastInsertId();

            // 1. Mark request as fulfilled if request_id is provided
            if (!empty($data->request_id)) {
                $fulfillQuery = "UPDATE book_requests 
                                 SET status = 'fulfilled', 
                                     fulfilled_by = :uploader, 
                                     fulfilled_date = CURRENT_TIMESTAMP 
                                 WHERE id = :rid";
                $fstmt = $conn->prepare($fulfillQuery);
                $fstmt->bindParam(':uploader', $data->uploaded_by);
                $fstmt->bindParam(':rid', $data->request_id);
                $fstmt->execute();

                // Notify the student who requested the book
                $studentNotifMsg = "Your request for '" . $data->title . "' has been fulfilled!";
                $sNotifQuery = "INSERT INTO notifications (user_id, type, message, related_id) 
                                SELECT student_id, 'book_request', :msg, :bid 
                                FROM book_requests WHERE id = :rid";
                $snstmt = $conn->prepare($sNotifQuery);
                $snstmt->bindParam(':msg', $studentNotifMsg);
                $snstmt->bindParam(':bid', $newBookId);
                $snstmt->bindParam(':rid', $data->request_id);
                $snstmt->execute();
            }

            // 2. Notify all users in the department about the new book
            $msg = "New book uploaded in " . $data->department . ": " . $data->title;
            // Select all users in dept except uploader
            $notifQuery = "INSERT INTO notifications (user_id, type, message, related_id) 
                           SELECT id, 'book_upload', :msg, :bid FROM users 
                           WHERE department = :dept AND id != :uploader";
            $nstmt = $conn->prepare($notifQuery);
            $nstmt->bindParam(':msg', $msg);
            $nstmt->bindParam(':bid', $newBookId);
            $nstmt->bindParam(':dept', $data->department);
            $nstmt->bindParam(':uploader', $data->uploaded_by);
            $nstmt->execute();

            echo json_encode(["message" => "Book uploaded successfully"]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Unable to upload book"]);
        }
    }
}

if ($method == 'DELETE' && strpos($endpoint, '/delete/') !== false) {
    $id = basename($endpoint);
    $query = "DELETE FROM books WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':id', $id);

    if ($stmt->execute()) {
        echo json_encode(["message" => "Book deleted successfully"]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Unable to delete book"]);
    }
}
?>
