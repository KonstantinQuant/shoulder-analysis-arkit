# Medical Shoulder Examination using Augmented Reality and Computer Vision

Joint Tracking with ARKit


ARSkeleton3D

What is a transform?
https://developer.apple.com/documentation/arkit/aranchor/2867981-transform
4x4 Matrix, (position, orientation, scale relative to world coordinate space)

https://www.youtube.com/watch?v=NsiJNvsuO3s

The 0,0,0,1 (the 4th column) for all the vectors is just added to make the rotation and transformation matrix square
https://math.stackexchange.com/questions/336/why-are-3d-transformation-matrices-4-times-4-instead-of-3-times-3
https://stackoverflow.com/questions/45437037/arkit-what-do-the-different-columns-in-transform-matrix-represent

The last column (the 3rd) holds the x,y,z translation vector
Can either get the:
1. Local transform relative to the parent joint
2. Global transform relative to the root / hip joint



http://www.fastgraph.com/makegames/3drotation/


Extract the components: 
https://math.stackexchange.com/questions/237369/given-this-transformation-matrix-how-do-i-decompose-it-into-translation-rotati

Can get jointTransforms from ARSkeleton2D, just x, y coordinates
┌               ┐
|  1  0  0  tx  |
|  0  1  0  ty  |
|  0  0  1  tz  |
|  0  0  0  1   |
└               ┘
￼
https://stackoverflow.com/questions/70309120/project-point-method-converting-rawfeaturepoint-to-screen-space





How to translate the coordinates back to the screen?

Need:
 guard let arCamera = session.currentFrame?.camera else { return }
//intrinsics: a matrix that converts between the 2D camera plane and 3D world coordinate space.
//projectionMatrix: a transform matrix appropriate for rendering 3D content to match the image captured by the camera.
print("ARCamera ProjectionMatrix = \(arCamera.projectionMatrix)")
print("ARCamera Intrinsics = \(arCamera.intrinsics)")
arCamera.transform










https://github.com/valengo/jointVisualizer

 //print("Rechter Arm", rightArmPosition)
        //print("Root", rootPosition)
        // let rightArmPosition = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "right_arm_joint"))!
         
         
         //let rightPosition = bodyPos + simd_make_float3(rightArmPosition.columns.3)
        //print(rightOffset, rootOffset)





// JointPosition is the vector that stores the coordinates
struct JointPosition {
    var type: String?
    var x: Float
    var y: Float
    var z: Float
}

extension JointPosition {
    func dotProduct(_ jointPosition: JointPosition) -> Float {
        return self.x*jointPosition.x + self.y*jointPosition.y + self.z*jointPosition.z
    }
    
    var length: Float {
        return sqrt((self.x*self.x)+(self.y*self.y)+(self.z*self.z))
    }
    
    func minus(_ jointPosition: JointPosition) -> JointPosition {
        return JointPosition(x: self.x-jointPosition.x, y: self.y-jointPosition.y, z: self.z-jointPosition.z)
    }
    
    // https://www.youtube.com/watch?v=GDShA2Rz0F8
    func angleBetween(_ jointPosition: JointPosition) -> Float {
        return (acos(self.dotProduct(jointPosition) / (self.length * jointPosition.length)))*180/Float.pi
    }
}

## Overview

- Note: This sample code project is associated with WWDC 2019 session [607: Bringing People into AR](https://developer.apple.com/videos/play/wwdc19/607/).

- Note: To run the app, use an iOS device with A12 chip or later.
