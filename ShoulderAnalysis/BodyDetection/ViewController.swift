//
//  ViewController.swift
//  ShoulderAnalysis
//
//  Created by Konstantin Kuchenmeister on 12/31/21.
//

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    @IBOutlet weak var shoudlerAngleLabel: UILabel!
    var humanJointsView = HumanJointsView()
    var frontalAngleAnalysisView = FrontalAngleAnalysisView()
    
    var isRecording = true
    
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [-1.0, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    
    override func viewDidLoad() {
        self.view.addSubview(humanJointsView)
        self.view.addSubview(frontalAngleAnalysisView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self
        
        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }
        
        // Run a body tracking configration.
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        
        arView.scene.addAnchor(characterAnchor)
        
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "character/robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
            }, receiveValue: { (character: Entity) in
                if let character = character as? BodyTrackedEntity {
                    // Scale the character to human size
                    character.scale = [1.0, 1.0, 1.0]
                    self.character = character
                    cancellable?.cancel()
                } else {
                    print("Error: Unable to load model as BodyTrackedEntity")
                }
            })
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            
            // Update the position of the character anchor's position.
            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            characterAnchor.position = bodyPosition + characterOffset
            
            // Also copy over the rotation of the body anchor, because the skeleton's pose
            // in the world is relative to the body anchor's rotation.
            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
            
            if let character = character, character.parent == nil {
                // Attach the character to its anchor as soon as
                // 1. the body anchor was detected and
                // 2. the character was loaded.
                characterAnchor.addChild(character)
            }
            
            guard let arCamera = session.currentFrame?.camera else { return }
            
            
            // Accessing the Skeleton Geometry
            if isRecording {
                let skeleton = bodyAnchor.skeleton
                //extractMainJointTransforms(from: skeleton, camera: arCamera, bodyPos: bodyPosition)
                performFrontalAngleAnalysis(from: skeleton, camera: arCamera, bodyPos: bodyPosition)
            }
        }
    }
    
    func extractMainJointTransforms(from skeleton: ARSkeleton3D, camera: ARCamera, bodyPos: simd_float3) {
        // print(ARSkeletonDefinition.defaultBody3D.jointNames)
        
        var globalProjections: [CGPoint] = []
        
        // Query all model transforms relative to the root
        let modelTransforms = skeleton.jointModelTransforms
        
        modelTransforms.forEach { transform in
            let position = bodyPos + simd_make_float3(transform.columns.3)
            globalProjections.append(camera.projectPoint(position, orientation: .portrait, viewportSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)))
        }
        
        _ = camera.projectionMatrix
        
        humanJointsView.frame = UIScreen.main.bounds
        humanJointsView.points = globalProjections
        
        DispatchQueue.main.async {
            self.shoudlerAngleLabel.text = "TODO°"
        }
    }
    

    func performFrontalAngleAnalysis(from skeleton: ARSkeleton3D, camera: ARCamera, bodyPos: simd_float3) {
        
        let rightArmPosition = bodyPos + simd_make_float3(skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "right_arm_joint"))!.columns.3)
        let rightForearmPosition = bodyPos + simd_make_float3(skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "right_forearm_joint"))!.columns.3)
        let rightUpLegPosition = bodyPos + simd_make_float3(skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "right_upLeg_joint"))!.columns.3)
        
        let rightArmP = camera.projectPoint(rightArmPosition, orientation: .portrait, viewportSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        
        let rightForearmP = camera.projectPoint(rightForearmPosition, orientation: .portrait, viewportSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        
        let rightUpLegP = camera.projectPoint(rightUpLegPosition, orientation: .portrait, viewportSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        
        frontalAngleAnalysisView.frame = UIScreen.main.bounds
        frontalAngleAnalysisView.points = [rightForearmP, rightArmP, rightUpLegP]

        print(rightForearmP, rightArmP, rightUpLegP)
        
        self.view.bringSubviewToFront(frontalAngleAnalysisView)
        self.view.bringSubviewToFront(self.shoudlerAngleLabel)
        
        let point3 = CGPoint(x: rightArmP.x, y: rightUpLegP.y)
        
        let angle = calculateJointAngle(p1: rightForearmP, p2: rightArmP, p3: point3)
        DispatchQueue.main.async {
            self.shoudlerAngleLabel.text = "\(String(format: "%.3f", angle))°"
        }
    }
    
    
    func calculateJointAngle(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> Double {
        
        let ba = CGPoint(x: p1.x - p2.x, y: p1.y - p2.y)
        let bc = CGPoint(x: p3.x - p2.x, y: p3.y - p2.y)
           

        let dotprod = ba.x * bc.x + ba.y * bc.y
            

        let banorm = sqrt(ba.x * ba.x + ba.y * ba.y)
        let bcnorm = sqrt(bc.x * bc.x + bc.y * bc.y)

        let cosine_angle = dotprod / (banorm * bcnorm)

        let angle = acos(cosine_angle)

       return (angle * 180 / Double.pi)
    }
    
}




