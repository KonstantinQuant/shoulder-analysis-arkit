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
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [-1.0, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    
    var isRecording = true
    
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
            
            // Accessing the Skeleton Geometry
            if isRecording {
                let skeleton = bodyAnchor.skeleton
                extractMainJointTransforms(from: skeleton)
            }
        }
    }
    
    func extractMainJointTransforms(from skeleton: ARSkeleton3D) {
        // Example: How to get coordinates of some of the joints.
        // Note: this is not a complete list of all joints you could get!
        // let head = coordinates(from: skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "right_hand_joint")))
        // let rightHandJoint = coordinates(from: skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "right_hand_joint")), name: ARSkeleton.JointName(rawValue: "right_hand_joint"))
        
        
        // Not all joint names have been defined in the ARSkeleton.JointName struct, therefore use rawvalue
        let rightHipJoint = coordinates(from: skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "right_upLeg_joint")), name: ARSkeleton.JointName(rawValue: "right_upLeg_joint"))
        
        print(ARSkeletonDefinition.defaultBody3D.jointNames)
        
        print(rightHipJoint)
        
        let rightArmJoint = coordinates(from: skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "right_arm_joint")), name: ARSkeleton.JointName(rawValue: "right_arm_joint"))
        
        let rightShoulderJoint = coordinates(from: skeleton.modelTransform(for: .rightShoulder), name: .rightShoulder)
        
        //        let leftShoulder = coordinates(from: skeleton.modelTransform(for: .leftShoulder), name: .leftShoulder)
        //        let leftHand = coordinates(from: skeleton.modelTransform(for: .leftHand), name: .leftHand)
        //        let rightShoulder = coordinates(from: skeleton.modelTransform(for: .rightShoulder), name: .rightShoulder)
        //        let rightHand = coordinates(from: skeleton.modelTransform(for: .rightHand), name: .rightHand)
        let root = skeleton.modelTransform(for: .root)!
        let rootPosition = simd_make_float3(root.columns.3)
        //        let leftHipJoint = ARSkeleton.JointName.init(rawValue: "left_upLeg_joint")
        //        let leftHip = coordinates(from: skeleton.modelTransform(for: leftHipJoint), name: leftHipJoint)
        //        let rightHipJoint = ARSkeleton.JointName.init(rawValue: "right_upLeg_joint")
        //        let rightHip = coordinates(from: skeleton.modelTransform(for: rightHipJoint), name: rightHipJoint)
        //        let leftLeg = ARSkeleton.JointName.init(rawValue: "left_leg_joint")
        //        let leftKnee = coordinates(from: skeleton.modelTransform(for: leftLeg), name: leftLeg)
        //        let rightLeg = ARSkeleton.JointName.init(rawValue: "right_leg_joint")
        //        let rightKnee = coordinates(from: skeleton.modelTransform(for: rightLeg), name: rightLeg)
        //        let leftFoot = coordinates(from: skeleton.modelTransform(for: .leftFoot), name: .leftFoot)
        //        let rightFoot = coordinates(from: skeleton.modelTransform(for: .rightFoot), name: .rightFoot)
        
        // TODO: Save the data somehow and/or process it
        // https://www.youtube.com/watch?v=GDShA2Rz0F8
        
        if let rSJ = rightShoulderJoint {
            if let rHJ = rightHipJoint {
                if let rAJ = rightArmJoint {
                    let rVectorSA = rSJ.minus(rAJ)
                    let rVectorSU = rSJ.minus(rHJ)
                    let res = (acos(abs(rVectorSA.dotProduct(rVectorSU)) / (rVectorSA.length + rVectorSU.length)))*180/3.14159265359
                    print(res)
                }
            }
        }
        
        
    }
    
    
    func coordinates(from transform: simd_float4x4?, name: ARSkeleton.JointName) -> JointPosition? {
        if let transform = transform {
            let position = simd_make_float3(transform.columns.3) // offset from the root joint
            return JointPosition(type: name.rawValue, x: position.x, y: position.y, z: position.z)
        }
        return nil
    }
}

// JointPosition is the vector that stores the coordinates
struct JointPosition {
    var type: String?
    var x: Float
    var y: Float
    var z: Float
    
    func dotProduct(_ jointPosition: JointPosition) -> Float {
        return self.x*jointPosition.x + self.y*jointPosition.y + self.z*jointPosition.z
    }
    
    var length: Float {
        return sqrt(x*x+y*y+z*z)
    }
    
    func minus(_ jointPosition: JointPosition) -> JointPosition {
        return JointPosition(x: self.x-jointPosition.x, y: self.y-jointPosition.y, z: self.z-jointPosition.z)
    }
}
