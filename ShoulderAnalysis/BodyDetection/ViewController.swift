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
    
    var isRecording = true
    
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [-1.0, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    
    override func viewDidLoad() {
        self.view.addSubview(humanJointsView)
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
                extractMainJointTransforms(from: skeleton, camera: arCamera, bodyPos: bodyPosition)
            }
        }
    }
    
    func extractMainJointTransforms(from skeleton: ARSkeleton3D, camera: ARCamera, bodyPos: simd_float3) {
        // Not all joint names have been defined in the ARSkeleton.JointName struct, therefore use rawvalue
        let rightUpLeg = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "right_upLeg_joint"))!
        let rightArm = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "right_arm_joint"))!
        let rightShoulder = skeleton.modelTransform(for: .rightShoulder)! //right_shoulder_1_joint
        
        let startOffset = simd_make_float3(rightUpLeg.columns.3)
        let midOffset = simd_make_float3(rightShoulder.columns.3)
        let endOffset = simd_make_float3(rightArm.columns.3)
        
        let angle = calculateJointAngle(startOffset, midOffset, endOffset)
        
        DispatchQueue.main.async {
            self.shoudlerAngleLabel.text = "\(angle)°"
        }
        
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
        
        
    }
    
    
    func processJoints(joints: [simd_float4x4], pMatrix: simd_float4x4) {
        
        
    }
    
    func calculateJointAngle(_ startOffset: SIMD3<Float>, _ midOffset: SIMD3<Float>, _ endOffset: SIMD3<Float>) -> Float {
        let v1 = simd_normalize(startOffset - midOffset)
        let v2 = simd_normalize(endOffset - midOffset)
        let dot = simd_dot(v1, v2)
        return GLKMathRadiansToDegrees(acos(dot))
    }
}




