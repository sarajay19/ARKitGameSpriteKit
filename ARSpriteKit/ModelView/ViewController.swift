//
//  ViewController.swift
//  ARSpriteKit
//
//  Main view controller managing AR experience and game interactions.
//  Handles AR session setup, scene configuration, and user interactions.

import UIKit
import SpriteKit
import ARKit

class ViewController: UIViewController, ARSKViewDelegate, ARSessionDelegate {
    
    @IBOutlet weak var sceneView: ARSKView!
    
    /// Called after the controller's view is loaded into memory.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure SceneView
        setupSceneView()
        
        // Configure AR Session
        setupARSession()
    }
    
    /// Configures the ARSKView with necessary settings.
    private func setupSceneView() {
        // Ensure sceneView is properly configured
        guard let sceneView = self.sceneView else {
            print("Error: SceneView not connected")
            return
        }
        
        // Set delegates
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Debug options
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        
        // Scene configuration
        let scene = Scene(size: sceneView.bounds.size)
        scene.scaleMode = .resizeFill
        scene.isPaused = false
        
        // Additional configuration
        sceneView.isMultipleTouchEnabled = true
        sceneView.ignoresSiblingOrder = true
        
        // Present the scene
        sceneView.presentScene(scene)
    }
    
    /// Configures the AR session with necessary settings.
    private func setupARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Optional: Add more AR configuration
        configuration.environmentTexturing = .automatic
        configuration.frameSemantics = .personSegmentationWithDepth
        
        sceneView.session.run(configuration)
    }
    
    /// Notifies the view controller that its view is about to be added to a view hierarchy.
    /// - Parameter animated: If `true`, the view is being added using an animation.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Restart the AR session if needed
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    /// Notifies the view controller that its view is about to be removed from a view hierarchy.
    /// - Parameter animated: If `true`, the disappearance of the view is being animated.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the AR session
        sceneView.session.pause()
    }
    
    // MARK: - ARSKViewDelegate Methods
    
    /// Provides a SpriteKit node for the specified AR anchor.
    /// - Parameters:
    ///   - view: The ARSKView rendering the scene.
    ///   - anchor: The AR anchor for which to provide a node.
    /// - Returns: A SpriteKit node, or `nil` if no node should be added.
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        guard let imageName = anchor.name else { return nil }
        
        let ghostNode = SKSpriteNode(imageNamed: imageName)
        ghostNode.name = "ghost"
        ghostNode.xScale = 0.5
        ghostNode.yScale = 0.5
        ghostNode.userData = ["anchor": anchor]
        
        if let scene = view.scene as? Scene {
            scene.applyGhostAnimations(to: ghostNode)
        }
        
        return ghostNode
    }
    
    // MARK: - ARSessionDelegate Methods
    
    /// Tells the delegate that the AR session failed.
    /// - Parameters:
    ///   - session: The AR session that failed.
    ///   - error: An error object containing details of the failure.
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Handle AR session failure
        let alertController = UIAlertController(
            title: "AR Session Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
    
    /// Tells the delegate that the AR session was interrupted.
    /// - Parameter session: The AR session that was interrupted.
    func sessionWasInterrupted(_ session: ARSession) {
        // Handle session interruption
        let alertController = UIAlertController(
            title: "Session Interrupted",
            message: "AR session interrupted. Please return to a better tracking location.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
    
    /// Tells the delegate that the AR session interruption has ended.
    /// - Parameter session: The AR session whose interruption ended.
    func sessionInterruptionEnded(_ session: ARSession) {
        // Restart the AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        if let scene = sceneView.scene as? Scene {
            scene.setupGhostsInRoom()
        }
    }
}
