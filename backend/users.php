<?php
include_once 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];
$endpoint = $_GET['endpoint'] ?? $_SERVER['PATH_INFO'] ?? '';

if ($method == 'POST' && strpos($endpoint, '/register') !== false) {
    $data = json_decode(file_get_contents("php://input"));

    if (!empty($data->email) && !empty($data->password)) {
        // Check if user exists
        $check = $conn->prepare("SELECT id FROM users WHERE email = :email");
        $check->bindParam(':email', $data->email);
        $check->execute();
        
        if ($check->rowCount() > 0) {
            http_response_code(400);
            echo json_encode(["message" => "Email already exists"]);
            exit();
        }

        $query = "INSERT INTO users (name, email, password_hash, role, department, approved_subjects, id_card_url, status) 
                  VALUES (:name, :email, :pass, :role, :dept, :subjects, :id_card, :status)";
        
        $stmt = $conn->prepare($query);
        
        $subjects = json_encode($data->approved_subjects ?? []);
        // Check for existing users to determine if this is the First Admin
        $countStmt = $conn->query("SELECT COUNT(*) FROM users");
        $userCount = $countStmt->fetchColumn();

        if ($userCount == 0 || $data->email === 'ahmad@gmail.com') {
            $data->role = 'Super Admin';
            $status = 'approved';
        } else {
            $status = 'pending';
        }
        $password_hash = password_hash($data->password, PASSWORD_DEFAULT);

        $stmt->bindParam(':name', $data->name);
        $stmt->bindParam(':email', $data->email);
        $stmt->bindParam(':pass', $password_hash);
        $stmt->bindParam(':role', $data->role);
        $stmt->bindParam(':dept', $data->department);
        $stmt->bindParam(':subjects', $subjects);
        $stmt->bindParam(':id_card', $data->id_card_url);
        $stmt->bindParam(':status', $status);

        if ($stmt->execute()) {
            echo json_encode(["message" => "User registered successfully", "id" => $conn->lastInsertId()]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Unable to register user"]);
        }
    }
}

if ($method == 'POST' && strpos($endpoint, '/login') !== false) {
    $data = json_decode(file_get_contents("php://input"));

    if (!empty($data->email) && !empty($data->password)) {
        $query = "SELECT * FROM users WHERE email = :email";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':email', $data->email);
        $stmt->execute();
        
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($user && password_verify($data->password, $user['password_hash'])) {
            // Remove password from response
            unset($user['password_hash']);
            $user['approved_subjects'] = json_decode($user['approved_subjects']);
            echo json_encode($user);
        } else {
            http_response_code(401);
            echo json_encode(["message" => "Invalid email or password"]);
        }
    }
}

if ($method == 'GET' && strpos($endpoint, '/profile') !== false) {
    $id = $_GET['id'] ?? '';

    $query = "SELECT * FROM users WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':id', $id);
    $stmt->execute();
    
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($user) {
        unset($user['password_hash']);
        $user['approved_subjects'] = json_decode($user['approved_subjects']);
        echo json_encode($user);
    } else {
        http_response_code(404);
        echo json_encode(["message" => "User not found"]);
    }
}
?>
