<?php
include 'db_connect.php';

$name = 'Super Admin';
$email = 'admin@bgnu.edu.pk';
$password = password_hash('admin123', PASSWORD_DEFAULT);
$role = 'Super Admin';
$dept = 'Administration';

$query = "INSERT INTO users (name, email, password_hash, role, department, status) 
          VALUES (:name, :email, :pass, :role, :dept, 'approved')";
$stmt = $conn->prepare($query);
$stmt->bindParam(':name', $name);
$stmt->bindParam(':email', $email);
$stmt->bindParam(':pass', $password);
$stmt->bindParam(':role', $role);
$stmt->bindParam(':dept', $dept);

if ($stmt->execute()) {
    echo "Super Admin account created successfully! <br>";
    echo "Email: $email <br>";
    echo "Password: admin123";
} else {
    echo "Creation failed. Account might already exist.";
}
?>
