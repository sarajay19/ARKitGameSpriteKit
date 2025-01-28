import SpriteKit
import ARKit
import Combine
import CoreData
import Foundation
import UIKit
import CloudKit


// MARK: - Data Models
struct Player: Codable {
    let email: String
    let name: String
    var highScore: Double
    var totalTimePlayed: Double
    var gamesPlayed: Int
}

struct GameSession: Codable {
    var playerEmail: String
    let score: Double
    let timeSpent: Double
    let date: Date

    enum CodingKeys: String, CodingKey {
        case playerEmail = "player_email"
        case score
        case timeSpent = "time_spent"
        case date
    }
}

struct QuizQuestion {
    let question: String
    let options: [String]
    let correctAnswer: Int
}


// MARK: - Scene Class

class Scene: SKScene {
    
    static var scores: [PlayerScore] = []
    
    // MARK: - Properties
    
    var unansweredQuestions: [String] = [] // Store ghost names for skipped questions
    var questionAttempts: [String: Int] = [:] // Store attempts for each question
    
    // Point system properties
    var totalPoints: Double = 0.0 {
        didSet {
            pointsLabel.text = String(format: "Points: %.1f", totalPoints)
        }
    }
    var pointsLabel: SKLabelNode!
    
    // Simplified animation properties
    let floatDistance: CGFloat = 90.0
    let floatDuration: TimeInterval = 1.0
    
    var currentGhost: SKNode?
    var currentQuestionIndex: Int = 0
    var currentAttempts: Int {
            // Return the attempts for the current ghost
            return questionAttempts[ghostQuestions[currentQuestionIndex].ghostName] ?? 0
        }
    
    let ghostsLabel = SKLabelNode(text: "Questions")
    let numberOfGhostsLabel = SKLabelNode(text: "10")
    var ghostCount = 10 {
        didSet {
            self.numberOfGhostsLabel.text = "\(ghostCount)"
            if ghostCount == 0 {
                stopTimer()
                print("\n=== Game Completed Successfully! ===")
                print("Player: \(playerName)")
                print("Final Time: \(String(format: "%.2f", elapsedTime)) seconds")
                print("Final Points: \(String(format: "%.1f", totalPoints))/10")
                print("==========================\n")
                showAchievement()
                saveScore()
            }
        }
    }
    
    // MARK: - Ghost Data
    let ghostQuestions: [(ghostName: String, question: QuizQuestion)] = [
            ("ghost1", QuizQuestion(
                question: "What's the primary programming language for iOS development?",
                options: ["Java", "Swift", "Python"],
                correctAnswer: 1
            )),
            ("ghost2", QuizQuestion(
                question: "Which tool is commonly used for version control?",
                options: ["Git", "Word", "Excel"],
                correctAnswer: 0
            )),
            ("ghost3", QuizQuestion(
                question: "What does API stand for?",
                options: ["Application Programming Interface", "Applied Programming Institute", "Advanced Program Integration"],
                correctAnswer: 0
            )),
            ("ghost4", QuizQuestion(
                question: "Which is NOT a common HTTP method?",
                options: ["GET", "POST", "SEND"],
                correctAnswer: 2
            )),
            ("ghost5", QuizQuestion(
                question: "What's the purpose of UIKit in iOS?",
                options: ["Database Management", "User Interface Framework", "Network Calls"],
                correctAnswer: 1
            )),
            ("ghost6", QuizQuestion(
                question: "Which pattern is commonly used in iOS development?",
                options: ["MVC", "ABC", "XYZ"],
                correctAnswer: 0
            )),
            ("ghost7", QuizQuestion(
                question: "What's the default package manager for iOS?",
                options: ["npm", "CocoaPods", "SPM"],
                correctAnswer: 2
            )),
            ("ghost8", QuizQuestion(
                question: "What framework is used for AR in iOS?",
                options: ["ARKit", "CoreAR", "RealityKit"],
                correctAnswer: 0
            )),
            ("ghost9", QuizQuestion(
                question: "Which is a valid Swift variable declaration?",
                options: ["var x = 5", "int x = 5", "x := 5"],
                correctAnswer: 0
            )),
            ("ghost10", QuizQuestion(
                question: "What's the entry point of an iOS app?",
                options: ["main.swift", "AppDelegate", "ViewController"],
                correctAnswer: 1
            ))
        ]
    
        let killSound = SKAction.playSoundFileNamed("ghost", waitForCompletion: true)
        var cameraPosition: simd_float4x4?
        var sceneView: ARSKView?
        
        // Timer properties
        var timerLabel: SKLabelNode!
        var startTime: Date?
        var elapsedTime: TimeInterval = 0
        var timer: Timer?
        
        // Game state properties
        var playerName: String = ""
        var playerEmail: String = ""
        var isGameActive = false
        
    
        // stop game button
        var stopGameButton: SKLabelNode!
    
    
        // Static properties with CoreData fetch results
        private var leaderboardScores: [NSManagedObject] = []
    
    // Ghost positioning
    struct GhostData {
        let position: SIMD3<Float>
        let imageNamed: String
        var anchor: ARAnchor?
    }

    
    var ghosts: [GhostData] = [
            GhostData(position: SIMD3(x: -9.0, y: 0.0, z: -0.5),
                      imageNamed: "ghost1",
                      anchor: nil),
            GhostData(position: SIMD3(x: -4.0, y: 0.0, z: -2.5),
                      imageNamed: "ghost2",
                      anchor: nil),
            GhostData(position: SIMD3(x: -1.5, y: 0.0, z: -1.5),
                      imageNamed: "ghost3",
                      anchor: nil),
            GhostData(position: SIMD3(x: -6.0, y: 0.0, z: -2.0),
                      imageNamed: "ghost4",
                      anchor: nil),
            GhostData(position: SIMD3(x: 0.0, y: 0.0, z: -0.5),
                      imageNamed: "ghost6",
                      anchor: nil),
            GhostData(position: SIMD3(x: 2.0, y: 0.0, z: -2.5),
                      imageNamed: "ghost5",
                      anchor: nil),
            GhostData(position: SIMD3(x: 4.5, y: 0.0, z: -2.0),
                      imageNamed: "ghost7",
                      anchor: nil),
            GhostData(position: SIMD3(x: 9.0, y: 0.0, z: -2.5),
                      imageNamed: "ghost8",
                      anchor: nil),
            GhostData(position: SIMD3(x: 1.0, y: 0.0, z: -4.5),
                      imageNamed: "ghost9",
                      anchor: nil),
            GhostData(position: SIMD3(x: 3.5, y: 0.0, z: -0.5),
                      imageNamed: "ghost10",
                      anchor: nil)
        ]
    
    let interactionThreshold: Float = 1.0
    
    // MARK: - Data Storing
    
    func savePlayerData(email: String, name: String, highScore: Double, totalTimePlayed: Double, gamesPlayed: Int) {
        let player = Player(email: email, name: name, highScore: highScore, totalTimePlayed: totalTimePlayed, gamesPlayed: gamesPlayed)

        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(player)
            let url = getDocumentsDirectory().appendingPathComponent("playerData.json")
            try encoded.write(to: url)
        } catch {
            print("Error saving player data: \(error)")
        }
        
        // Save to UserDefaults
        let playerData: [String: Any] = [
            "email": email,
            "name": name,
            "high_score": highScore,
            "total_time_played": totalTimePlayed,
            "games_played": gamesPlayed
        ]
        UserDefaults.standard.set(playerData, forKey: "playerData")
        
    }

    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        removeAllChildren()
        
        let gameHasBeenPlayed = UserDefaults.standard.bool(forKey: "gameHasBeenPlayed")
        
        if gameHasBeenPlayed {
            // If game has been played, only show leaderboard
            displayLeaderboardOverlay(canExit: true)
        } else {
            // Normal game setup
            if let arView = view as? ARSKView {
                sceneView = arView
            }
            
            showNameInput()
            loadScores()
        }
    }
    
    // MARK: - Game Setup
    
    private func showNameInput() {
        DispatchQueue.main.async {
            if let viewController = self.view?.window?.rootViewController {
                let alert = UIAlertController(
                    title: "Player Information",
                    message: "Please enter your details",
                    preferredStyle: .alert
                )

                alert.addTextField { textField in
                    textField.placeholder = "Your name"
                }
                alert.addTextField { textField in
                    textField.placeholder = "Your email"
                    textField.keyboardType = .emailAddress
                }

                let startAction = UIAlertAction(title: "Start Game", style: .default) { [weak self] _ in
                    guard let name = alert.textFields?[0].text, !name.isEmpty,
                          let email = alert.textFields?[1].text, !email.isEmpty,
                          email.contains("@") else {
                        self?.showError("Invalid Input", "Please enter a valid name and email")
                        return
                    }

                    // Save player data locally
                    self?.savePlayerData(
                        email: email,
                        name: name,
                        highScore: 0.0,
                        totalTimePlayed: 0.0,
                        gamesPlayed: 0
                    )
                    
                    self?.playerName = name
                    self?.playerEmail = email
                    self?.startGame()
                }

                alert.addAction(startAction)
                viewController.present(alert, animated: true)
            }
        }
    }

    private func showError(_ title: String, _ message: String) {
        guard let viewController = self.view?.window?.rootViewController else { return }
        let errorAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController.present(errorAlert, animated: true)
    }

    private func startGame() {
        setupUI()
        setupTimer()
        setupGhostsInRoom()
        isGameActive = true
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func setupUI() {
        setupBackgroundUI()
        setupLabels()
        setupButtons()
    }
    
    private func setupBackgroundUI() {
        let backgroundCircle = SKShapeNode(circleOfRadius: 50)
        backgroundCircle.fillColor = UIColor.black.withAlphaComponent(0.5)
        backgroundCircle.strokeColor = .clear
        backgroundCircle.position = CGPoint(x: size.width / 2, y: size.height - 120)
        addChild(backgroundCircle)
    }
    
    private func setupLabels() {
        ghostsLabel.fontSize = 15
        ghostsLabel.fontName = "DevanagariSangamMN-Bold"
        ghostsLabel.color = .white
        ghostsLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height - 102)
        addChild(ghostsLabel)
        
        numberOfGhostsLabel.fontSize = 50
        numberOfGhostsLabel.fontName = "DevanagariSangamMN-Bold"
        numberOfGhostsLabel.color = .white
        numberOfGhostsLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height - 145)
        addChild(numberOfGhostsLabel)
        
        // points label
        pointsLabel = SKLabelNode(text: "Points: 0")
        pointsLabel.fontSize = 20
        pointsLabel.fontName = "DevanagariSangamMN-Bold"
        pointsLabel.horizontalAlignmentMode = .right
        pointsLabel.position = CGPoint(x: self.size.width - 20, y: self.size.height - 80)
        addChild(pointsLabel)
        
        timerLabel = SKLabelNode(text: "")
        timerLabel.fontSize = 30
        timerLabel.fontName = "DevanagariSangamMN-Bold"
        timerLabel.fontColor = .white
        timerLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height - 200)
        addChild(timerLabel)
        
        
    }
    
    private func setupButtons() {
        stopGameButton = SKLabelNode(text: "End Game")
        stopGameButton.fontSize = 20
        stopGameButton.fontColor = .red
        stopGameButton.fontName = "DevanagariSangamMN-Bold"
        stopGameButton.name = "stopGameButton"
        stopGameButton.position = CGPoint(x: self.size.width - 330, y: self.size.height - 80)
        addChild(stopGameButton)
        

    }
    
    private func startTimer() {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        isGameActive = true
    }
    
    // MARK: - Ghost Setup and Interaction
    
    func setupGhostsInRoom() {
        guard let sceneView = sceneView else { return }
        
        for (index, var ghost) in ghosts.enumerated() {
            var transform = matrix_identity_float4x4
            transform.columns.3.x = ghost.position.x
            transform.columns.3.y = ghost.position.y
            transform.columns.3.z = ghost.position.z
            
            // Create an ARAnchor with a name that includes the image name
            let anchor = ARAnchor(name: ghost.imageNamed, transform: transform)
            ghost.anchor = anchor
            ghosts[index] = ghost
            sceneView.session.add(anchor: anchor)
        }
    }
    
    // MARK: - Timer Management
    
    private func setupTimer() {
        timerLabel = SKLabelNode(text: "5:00")
        timerLabel.fontSize = 30
        timerLabel.fontName = "DevanagariSangamMN-Bold"
        timerLabel.fontColor = .white
        timerLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height - 200)
        addChild(timerLabel)
    }
    
    private func updateTimer() {
        guard let startTime = startTime else { return }
        
        let currentTime = Date()
        elapsedTime = currentTime.timeIntervalSince(startTime)
        
        // Convert elapsed time to minutes and seconds
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isGameActive = false
    }
    
    func stopGame() {
        stopTimer()
        saveScore() // Ensure the score is saved
        UserDefaults.standard.set(true, forKey: "gameHasBeenPlayed") // Set flag to indicate game has been played
        displayLeaderboardOverlay(canExit: true) // Show the leaderboard
    }

    
    // MARK: - Game State Management
    
    private func gameOver() {
        stopTimer()
        // Add debug print for time out scenario
        print("\n=== Game Over - Time's Up! ===")
        print("Player: \(playerName)")
        print("Final Time: 60 seconds (max time)")
        print("Ghosts Collected: \(10 - ghostCount)")
        print("Ghosts Remaining: \(ghostCount)")
        print("==========================\n")
        
        showGameOverMessage()

    }

    
     
    private func showGameOverMessage() {
        let gameOverLabel = SKLabelNode(text: "Game Over!")
        gameOverLabel.fontSize = 40
        gameOverLabel.fontName = "DevanagariSangamMN-Bold"
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        addChild(gameOverLabel)
        
        let scoreLabel = SKLabelNode(text: "Final Points: \(String(format: "%.1f", totalPoints))/10")
        scoreLabel.fontSize = 30
        scoreLabel.fontName = "Poppins-Regular"
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 - 50)
        addChild(scoreLabel)
        
        let timeLabel = SKLabelNode(text: "Time: \(timerLabel.text ?? "00:00")")
        timeLabel.fontSize = 30
        timeLabel.fontName = "Poppins-Regular"
        timeLabel.fontColor = .white
        timeLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 - 100)
        addChild(timeLabel)
    }
    
    func showAchievement() {
        let achievementLabel = SKLabelNode(text: "All Questions Completed!")
        achievementLabel.fontSize = 35
        achievementLabel.fontName = "DevanagariSangamMN-Bold"
        achievementLabel.fontColor = .green
        achievementLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        addChild(achievementLabel)
        
        let scoreLabel = SKLabelNode(text: String(format: "Final Score: %.1f/10", totalPoints))
        scoreLabel.fontSize = 30
        scoreLabel.fontName = "Poppins-Regular"
        scoreLabel.fontColor = .green
        scoreLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 - 50)
        addChild(scoreLabel)
        
        let timeLabel = SKLabelNode(text: String(format: "Time: %.1f seconds", elapsedTime))
        timeLabel.fontSize = 30
        timeLabel.fontName = "Poppins-Regular"
        timeLabel.fontColor = .green
        timeLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 - 100)
        addChild(timeLabel)
        
        // Leaderboard button
        let leaderboardButton = SKLabelNode(text: "Leaderboard")
        leaderboardButton.fontSize = 20
        leaderboardButton.fontColor = .yellow
        leaderboardButton.fontName = "DevanagariSangamMN-Bold"
        leaderboardButton.name = "leaderboardButton"
        leaderboardButton.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 - 150)
        addChild(leaderboardButton)
    }
    
    // MARK: - Score Management
    
    func saveScore() {
        // Save to CoreData
        saveScoresToCoreData()
        
        // Refresh leaderboard
        refreshLeaderboard()
        
        // Debug print
        print("\n=== Score Saved ===")
        print("Player: \(playerName) (\(playerEmail))")
        print("Score: \(totalPoints)")
        print("Time: \(elapsedTime) seconds")
        print("==================\n")
    }


    func refreshLeaderboard() {
        CoreDataStack.shared.fetchLeaderboardScores { [weak self] (scores: [PlayerScore]) in
            Scene.scores = scores
            self?.displayLeaderboardOverlay(canExit: true)
        }
    }


    func loadPlayerDataFromFile() -> Player? {
        let url = getDocumentsDirectory().appendingPathComponent("playerData.json")
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(Player.self, from: data)
        } catch {
            print("Error loading player data: \(error)")
            return nil
        }
    }

    
    private func loadScores() {
        // Load scores from CoreData
        CoreDataStack.shared.fetchLeaderboardScores { [weak self] scores in
            DispatchQueue.main.async {
                Scene.scores = scores
                
                // If this is being called during initial setup, proceed with game setup
                if let gameHasBeenPlayed = self?.checkGamePlayedStatus() {
                    if gameHasBeenPlayed {
                        self?.displayLeaderboardOverlay(canExit: true)
                    } else {
                        // Normal game setup
                        if let arView = self?.view as? ARSKView {
                            self?.sceneView = arView
                        }
                        
                        self?.showNameInput()
                    }
                }
            }
        }
    }
    
    private func saveScoresToCoreData() {
        guard !playerName.isEmpty && !playerEmail.isEmpty else { return }
        
        CoreDataStack.shared.savePlayerScore(
            name: playerName,
            email: playerEmail,
            score: totalPoints,
            timeInSeconds: elapsedTime
        )
    }
    
    private func checkGamePlayedStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: "gameHasBeenPlayed")
    }

    
    private func showLeaderboard() {
        print("\n=== Leaderboard ===")
        let leaderboardNode = SKNode()
        var yPosition: CGFloat = self.size.height / 2 - 100
        
        let titleLabel = SKLabelNode(text: "Top Scores")
        titleLabel.fontSize = 25
        titleLabel.fontName = "DevanagariSangamMN-Bold"
        titleLabel.fontColor = .yellow
        titleLabel.position = CGPoint(x: self.size.width / 2, y: yPosition)
        leaderboardNode.addChild(titleLabel)
        
        yPosition -= 30
        
        for (index, score) in Scene.scores.prefix(5).enumerated() {
            print("\(index + 1). \(score.name): \(String(format: "%.1f", score.timeInSeconds))s")
            let scoreLabel = SKLabelNode(text: "\(index + 1). \(score.name): \(String(format: "%.1f", score.timeInSeconds))s")
            scoreLabel.fontSize = 20
            scoreLabel.fontName = "DevanagariSangamMN-Bold"
            scoreLabel.fontColor = .white
            scoreLabel.position = CGPoint(x: self.size.width / 2, y: yPosition)
            leaderboardNode.addChild(scoreLabel)
            yPosition -= 25
        }
        print("=================\n")
        addChild(leaderboardNode)
    }
    
    // MARK: - Game Updates and Interaction
    
    override func update(_ currentTime: TimeInterval) {
        if let camera = sceneView?.session.currentFrame?.camera {
            cameraPosition = camera.transform
        }
    }

    func distance(from userPosition: simd_float4x4, to ghostAnchor: ARAnchor) -> Float {
        let ghostWorldPosition = ghostAnchor.transform.columns.3
        let userWorldPosition = userPosition.columns.3
        
        return simd_distance(
            SIMD3(ghostWorldPosition.x, ghostWorldPosition.y, ghostWorldPosition.z),
            SIMD3(userWorldPosition.x, userWorldPosition.y, userWorldPosition.z)
        )
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let hit = nodes(at: location)
        
        
        // Handle exit app button
        if let node = hit.first(where: { $0.name == "exitAppButton" }) {
            // Programmatically exit the app
            exit(0)
        }
        
         // Leaderboard button handling
        if let node = hit.first(where: { $0.name == "leaderboardButton" }) {
            displayLeaderboardOverlay(canExit: true)
            return
        }
        
        
        // Handle stop game button touch
        if let node = hit.first(where: { $0.name == "stopGameButton" }) {
            showStopGameConfirmation() // Show confirmation alert
            return
        }
        
        // Exit button handling
        if let node = hit.first(where: { $0.name == "exitButton" }) {
            // Restore original scene state
            didMove(to: view!)
            return
        }
        
        // Existing ghost touch handling...
        if let node = hit.first(where: { $0.name == "ghost" }),
           let userPosition = cameraPosition,
           let ghostData = ghosts.first(where: { $0.anchor == node.userData?["anchor"] as? ARAnchor }) {
            
            if currentGhost != nil { return }
            
            guard let anchor = ghostData.anchor else { return }
            let distanceToGhost = distance(from: userPosition, to: anchor)
            
            if distanceToGhost <= interactionThreshold {
                currentGhost = node
                let ghostName = ghostData.imageNamed // Direct assignment, no optional binding
                questionAttempts[ghostName] = 0 // Reset attempts for the ghost

                // Check if the ghost has been skipped
                if unansweredQuestions.contains(ghostName) {
                    // Show the question again if it was skipped
                    showQuizQuestion(for: ghostName)
                } else {
                    // Show the quiz question for the ghost
                    showQuizQuestion(for: anchor.name ?? "ghost1")
                }
            } else {
                showTooFarMessage()
            }

                    }
                }
    
    private func showStopGameConfirmation() {
        guard let viewController = self.view?.window?.rootViewController else { return }

        let alert = UIAlertController(
            title: "Stop Game",
            message: "This action will stop the game and store the score you got. You cannot play the game again. Are you sure you want to end this game?",
            preferredStyle: .alert
        )

        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            self?.stopGame() // Call the existing stopGame method
        }
        
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)

        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        viewController.present(alert, animated: true)
    }

    private func displayLeaderboardOverlay(canExit: Bool = false) {
        // Ensure scores are loaded before displaying
        loadScores()

        // Clear existing scene
        removeAllChildren()
        
        // Fade out ghosts and their questions
        fadeOutGhostsAndQuestions()
        
        // Leaderboard background
        let backgroundNode = SKSpriteNode(color: .black.withAlphaComponent(0.8), size: self.size)
        backgroundNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        addChild(backgroundNode)
        
        // Title
        let titleLabel = SKLabelNode(text: "Leaderboard")
        titleLabel.fontSize = 40
        titleLabel.fontColor = .yellow
        titleLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height - 100)
        addChild(titleLabel)
        
        // Modify the scores sorting to prioritize score, then time
        Scene.scores.sort { (score1, score2) in
            // First, compare by points (total points / max possible points)
            let score1Points = score1.score ?? 0  // Add a score property to PlayerScore
            let score2Points = score2.score ?? 0
            
            if score1Points != score2Points {
                return score1Points > score2Points  // Higher score first
            }
            
            // If scores are equal, sort by time (shortest time first)
            return score1.timeInSeconds < score2.timeInSeconds
        }
        
        // Display top scores
        var yPosition: CGFloat = self.size.height - 200
        
        // Find current player's rank
        let currentPlayerRank = Scene.scores.firstIndex { $0.name == playerName && $0.timeInSeconds == elapsedTime } ?? -1
        
        // Ensure scores are displayed even if empty
        if Scene.scores.isEmpty {
            let noScoresLabel = SKLabelNode(text: "No scores yet")
            noScoresLabel.fontSize = 25
            noScoresLabel.fontColor = .white
            noScoresLabel.position = CGPoint(x: self.size.width / 2, y: yPosition)
            addChild(noScoresLabel)
        } else {
            for (index, score) in Scene.scores.prefix(10).enumerated() {
                let scoreText = "\(index + 1). \(score.name): " +
                                "Scored \(String(format: "%.1f", score.score ?? 0))/10 " +
                                "in \(String(format: "%.1f", score.timeInSeconds))s"
                
                let scoreLabel = SKLabelNode(text: scoreText)
                
                // Highlight current player's rank in red and increase font size
                if index == currentPlayerRank {
                    scoreLabel.fontColor = .red
                    scoreLabel.fontSize = 20
                    scoreLabel.fontName = "DevanagariSangamMN-Bold"
                } else {
                    scoreLabel.fontColor = .white
                    scoreLabel.fontSize = 18
                    scoreLabel.fontName = "Poppins-Regular"

                }
                
                scoreLabel.position = CGPoint(x: self.size.width / 2, y: yPosition)
                addChild(scoreLabel)
                yPosition -= 40
            }
        }
        
        // Only add exit button if specified
        if canExit {
            let exitButton = SKLabelNode(text: "Exit App")
            exitButton.name = "exitAppButton"
            exitButton.fontSize = 30
            exitButton.fontColor = .red
            exitButton.position = CGPoint(x: self.size.width / 2, y: 100)
            addChild(exitButton)
        }
    }
    
    

    func showQuizQuestion(for ghostName: String) {
        guard let viewController = self.view?.window?.rootViewController,
              let questionData = ghostQuestions.first(where: { $0.ghostName == ghostName }) else { return }

        let question = questionData.question
        currentQuestionIndex = ghostQuestions.firstIndex(where: { $0.ghostName == ghostName }) ?? 0
        
        let alertController = UIAlertController(
            title: question.question,
            message: "Attempts remaining: \(2 - currentAttempts)",
            preferredStyle: .alert
        )
        
        // Add answer options with custom styling
        for (index, option) in question.options.enumerated() {
            let action = UIAlertAction(title: option, style: .default) { [weak self] _ in
                self?.handleAnswer(selectedAnswer: index, correctAnswer: question.correctAnswer, ghostName: ghostName)
            }
            alertController.addAction(action)
        }
        
        // Add a Skip option
        let skipAction = UIAlertAction(title: "skip", style: .cancel) { [weak self] _ in
            // Increment the attempts for this ghost
            self?.questionAttempts[ghostName, default: 0] += 1
            
            self?.unansweredQuestions.append(ghostName) // Save the skipped question
            self?.currentGhost = nil // Reset current ghost to allow interaction with others
        }
        alertController.addAction(skipAction)

        viewController.present(alertController, animated: true)
    }

    func showTooFarMessage() {
        let messageNode = SKLabelNode(text: "Please move closer to collect!")
        messageNode.fontSize = 20
        messageNode.fontName = "DevanagariSangamMN-Bold"
        messageNode.fontColor = .red
        messageNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        addChild(messageNode)
        
        let fadeOut = SKAction.fadeOut(withDuration: 2.0)
        messageNode.run(fadeOut) {
            messageNode.removeFromParent()
        }
    }

    
    func handleAnswer(selectedAnswer: Int, correctAnswer: Int, ghostName: String) {
        guard let viewController = self.view?.window?.rootViewController else { return }
        
        let isCorrect = selectedAnswer == correctAnswer
        
        if isCorrect {
            // Award points based on attempts
            let points = currentAttempts == 0 ? 1.0 : 0.5
            totalPoints += points
            
            // Reset attempts for this ghost
            questionAttempts[ghostName] = 0
            
            showFeedback(correct: true, selectedAnswer: selectedAnswer, correctAnswer: correctAnswer, pointsAwarded: points)
        } else {
            // Increment attempts for this ghost
            questionAttempts[ghostName, default: 0] += 1
            
            if questionAttempts[ghostName]! >= 2 {
                // No points awarded after two failed attempts
                showFinalFeedback(selectedAnswer: selectedAnswer, correctAnswer: correctAnswer)
            } else {
                showFeedback(correct: false, selectedAnswer: selectedAnswer, correctAnswer: correctAnswer, pointsAwarded: 0)
            }
        }
    }
    
    func showFeedback(correct: Bool, selectedAnswer: Int, correctAnswer: Int, pointsAwarded: Double) {
        guard let viewController = self.view?.window?.rootViewController else { return }
        
        let title = correct ? "Correct!" : "Wrong!"
        var message = ""
        
        if correct {
            message = "Points awarded: \(String(format: "%.1f", pointsAwarded))\nTotal points: \(String(format: "%.1f", totalPoints))"
        } else {
            message = "Try again! Attempts remaining: \(2 - currentAttempts)"
        }
        
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            if correct {
                if let currentGhost = self?.currentGhost {
                    self?.fadeOutGhost(currentGhost)
                }
            } else {
                if let ghostName = self?.ghostQuestions[self?.currentQuestionIndex ?? 0].ghostName {
                    self?.showQuizQuestion(for: ghostName)
                }
            }
        }
        
        alertController.addAction(okAction)
        viewController.present(alertController, animated: true)
    }
    
//    func showFinalFeedback(selectedAnswer: Int, correctAnswer: Int) {
//        guard let viewController = self.view?.window?.rootViewController else { return }
//        
//        let currentQuestion = ghostQuestions[currentQuestionIndex].question
//        let correctAnswerText = currentQuestion.options[correctAnswer]
//        let selectedAnswerText = currentQuestion.options[selectedAnswer]
//        
//        let alertController = UIAlertController(
//            title: "Incorrect - No points awarded",
//            message: "\nYour answer: \(selectedAnswerText) ❌\n\nCorrect answer: \(correctAnswerText) ✅",
//            preferredStyle: .alert
//        )
//        
//        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
//            if let currentGhost = self?.currentGhost {
//                self?.fadeOutGhost(currentGhost)
//            }
//            self?.currentAttempts = 0
//            self?.currentGhost = nil
//        }
//        
//        alertController.addAction(okAction)
//        viewController.present(alertController, animated: true)
//    }
    
    func showFinalFeedback(selectedAnswer: Int, correctAnswer: Int) {
        guard let viewController = self.view?.window?.rootViewController else { return }
        
        let currentQuestion = ghostQuestions[currentQuestionIndex].question
        let correctAnswerText = currentQuestion.options[correctAnswer]
        let selectedAnswerText = currentQuestion.options[selectedAnswer]
        
        let alertController = UIAlertController(
            title: "Incorrect - No points awarded",
            message: "\nYour answer: \(selectedAnswerText) ❌\n\nCorrect answer: \(correctAnswerText) ✅",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            if let currentGhost = self?.currentGhost {
                self?.fadeOutGhost(currentGhost)
            }
            // Reset attempts for the current ghost
            if let ghostName = self?.ghostQuestions[self?.currentQuestionIndex ?? 0].ghostName {
                self?.questionAttempts[ghostName] = 0
            }
            self?.currentGhost = nil
        }
        
        alertController.addAction(okAction)
        viewController.present(alertController, animated: true)
    }


    func applyGhostAnimations(to ghost: SKNode) {
        
        let easeIn = SKAction.moveBy(x: 0, y: floatDistance, duration: floatDuration/2)
        easeIn.timingMode = .easeInEaseOut  // Add smooth easing
        
        let easeOut = SKAction.moveBy(x: 0, y: -floatDistance, duration: floatDuration/2)
        easeOut.timingMode = .easeInEaseOut  // Add smooth easing
        
        let floatSequence = SKAction.sequence([easeIn, easeOut])
        let floatingAnimation = SKAction.repeatForever(floatSequence)
        
        // 1. Floating animation (up and down)
        // Simple floating animation (up and down only)
        let floatUp = SKAction.moveBy(x: 0, y: floatDistance, duration: floatDuration)
        let floatDown = SKAction.moveBy(x: 0, y: -floatDistance, duration: floatDuration)
        
        // 4. Fade in when ghost appears
        ghost.alpha = 0
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        
        // Combine animations
        let sequence = SKAction.sequence([fadeIn, floatingAnimation])
        ghost.run(sequence)
        
    }
    
    func fadeOutGhost(_ ghostNode: SKNode) {
        
        // Stop existing animations
        ghostNode.removeAllActions()
        
        // Play the sound
        run(killSound)
        
        // Create a special disappearing animation
        let flipAction = SKAction.scaleX(to: 0, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        
        // Combine animations
        let disappearGroup = SKAction.group([flipAction, fade])
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([disappearGroup, remove])
        
        ghostNode.run(sequence) {
            self.currentGhost = nil
            self.ghostCount -= 1
            print("Ghost collected! Remaining ghosts: \(self.ghostCount)")
            
            // Print current time elapsed
            if let startTime = self.startTime {
                let currentTime = Date()
                let timeElapsed = currentTime.timeIntervalSince(startTime)
                print("Time elapsed: \(String(format: "%.2f", timeElapsed)) seconds")
            }
        }
    }
    
    private func fadeOutGhostsAndQuestions() {
        // Fade out all ghosts
        for ghost in ghosts {
            if let ghostNode = sceneView?.node(for: ghost.anchor!) {
                let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                ghostNode.run(fadeOut)
            }
        }
        
        // Optionally, remove questions or any UI related to ghosts
        // This could be done in your showLeaderboardOverlay method
    }

    
}

