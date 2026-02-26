<?php
include 'db_connect.php';

$updates = [
    'Botany' => [
        'BS Botany',
        'Plant Physiology',
        'Plant Genetics',
        'Ecology',
        'Ethnobotany',
        'Environmental Biology',
        'Stress Physiology',
        'Plant Tissue Culture',
        'Plant Eco-toxicology'
    ],
    'Chemistry' => [
        'BS Chemistry',
        'Analytical Chemistry',
        'Inorganic Chemistry',
        'Organic Chemistry',
        'Physical Chemistry',
        'Biochemistry',
        'Environmental Chemistry',
        'Industrial Chemistry'
    ],
    'Zoology' => [
        'BS Zoology',
        'Principles of Animal Physiology',
        'Biodiversity & Conservation',
        'Cellular & Ecological aspects of animals'
    ],
    'Biology / Computational Biology' => [
        'BS Biology (Computational Biology)',
        'Computational Biology',
        'Biological Sciences'
    ],
    'Environmental Sciences' => ['BS Environmental Sciences'],
    'Food Science & Technology' => ['BS Food Science & Technology'],
    'Physics' => [
        'BS Physics',
        'Mechanics',
        'Electricity & Magnetism',
        'Quantum Physics',
        'Thermodynamics',
        'Modern Physics'
    ],
    'Mathematics' => [
        'BS Mathematics',
        'Calculus',
        'Algebra',
        'Statistics',
        'Mathematical Foundations of AI/Data Science'
    ],
    'Data Science & Analytics' => [
        'BS Data Science & Analytics',
        'Data Management',
        'Statistical Modeling',
        'Data Analytics tools & techniques'
    ],
    'Bioinformatics' => [
        'BS Bioinformatics',
        'Computational Biology',
        'Bioinformatics applications'
    ],
    'Artificial Intelligence' => [
        'BS Artificial Intelligence',
        'Machine Learning',
        'Intelligent Systems',
        'AI fundamentals'
    ],
    'Computer Science' => [
        'BS Computer Science',
        'Digital Logic & Design',
        'Object-Oriented Programming',
        'Data Structures & Algorithms',
        'Database Systems',
        'Software Engineering',
        'Web & Multimedia Technologies',
        'Operating Systems',
        'Compiler Construction'
    ],
    'Information Technology' => [
        'BS Information Technology',
        'IT fundamentals',
        'Programming & software tools',
        'Practical IT problem solving'
    ],
    'Psychology' => [
        'BS Psychology',
        'History & Systems of Psychology',
        'Experimental Psychology',
        'Social Psychology',
        'Educational Psychology',
        'Personality Psychology',
        'Clinical Psychology',
        'Statistical Methods in Psychology'
    ],
    'Education' => ['B.Ed. Educational Technology & Innovation'],
    'English Language & Literature' => [
        'BS English Language & Literature',
        'Phonetics & Phonology',
        'Classical & World English Literature',
        'Applied Linguistics',
        'Literary Criticism',
        'Research Methodology'
    ],
    'Punjabi Language & Literature' => [
        'BS Punjabi Language & Literature',
        'Punjabi language studies',
        'Literature & cultural texts'
    ],
    'Faculty of Fine Arts & Design' => [
        'BFA Fine Arts',
        'BFA Graphic Design',
        'BFA Fashion Design',
        'BFA Textile Design',
        'BFA Animation & Game Design',
        'Drawing',
        'Painting',
        'Art History',
        'Sculpture'
    ],
    'Management Sciences' => [
        'BBA',
        'BS Accounting & Finance',
        'BS FinTech & E-Commerce',
        'Financial Accounting',
        'Introduction to Management',
        'Microeconomics & Macroeconomics',
        'Marketing Principles',
        'Business Ethics',
        'Entrepreneurship & SME Management'
    ],
    'Islamic Studies' => [
        'BS Islamic Studies',
        'Quranic studies',
        'Hadith & Seerah',
        'Islamic law & theology',
        'Islamic history'
    ]
];

echo "Starting Date Fix...<br>";

foreach ($updates as $dept => $subjects) {
    echo "Fixing $dept...<br>";
    foreach ($subjects as $subject) {
        $sql = "UPDATE books SET department = :dept WHERE subject = :subject";
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(':dept', $dept);
        $stmt->bindParam(':subject', $subject);
        if ($stmt->execute()) {
             $count = $stmt->rowCount();
             if ($count > 0) echo "Updated $count books for subject '$subject' to '$dept'<br>";
        }
    }
}
echo "Done.";
?>
