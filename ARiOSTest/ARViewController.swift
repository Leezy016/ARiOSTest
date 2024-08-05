//
//  ARViewController.swift
//  ARiOSTest
//
//  Created by Pete on 2024/8/5.
//


import SwiftUI
import RealityKit
import AVKit
import ARKit
import UIKit

struct ARViewContainer: UIViewRepresentable {
    
    var isPlaying = true
    let arView = ARView(frame: .zero)
    
    func makeUIView(context: Context) -> ARView {
        playAnimation(isPlaying: isPlaying)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func playAnimation(isPlaying:Bool) {
        let model = try! Entity.load(named: "toy_drummer_idle.usdz")
        let anchor = AnchorEntity()
        anchor.addChild(model)
        anchor.position = [0, 0, -0.5]
        arView.scene.anchors.append(anchor)
        
        if anchor.isActive && isPlaying{
            for entity in anchor.children {
                for animation in entity.availableAnimations {
                    entity.playAnimation(animation.repeat())
                }
            }
        }
    }
    
    
    func startImgTrackign() {
        guard let imgToTrack = ARReferenceImage.referenceImages(inGroupNamed:"Img", bundle:Bundle.main)else{
            print("Img not available, import one")
            return
        }
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = imgToTrack
        configuration.maximumNumberOfTrackedImages = 5
        
        //Start Session
        arView.session.run(configuration)
                
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let imgAnchor = anchor as? ARImageAnchor{
                let width = Float(imgAnchor.referenceImage.physicalSize.width)
                let height = Float(imgAnchor.referenceImage.physicalSize.height)
                let videoScreen = createVideoScreen(width: width, height: height)
                
                placeVideoScreen(videoScreen: videoScreen, imgAnchor: imgAnchor)
            }
        }
    }
    
    
// MARK: - Object placement
    func placeVideoScreen(videoScreen: ModelEntity, imgAnchor: ARImageAnchor) {
        let imgAnchorEntity = AnchorEntity(anchor: imgAnchor)
        
        let rotationAngle = simd_quatf(angle: GLKMathDegreesToRadians(-90), axis: SIMD3(x: 1, y: 0, z: 0))
        videoScreen.setOrientation(rotationAngle, relativeTo: imgAnchorEntity)
        
        let bookWidth = Float(imgAnchor.referenceImage.physicalSize.width)
        videoScreen.setPosition(SIMD3(x: bookWidth, y: 0, z: 0), relativeTo: imgAnchorEntity)
        
        imgAnchorEntity.addChild(videoScreen)
        
        // add anchor to scene
        arView.scene.addAnchor(imgAnchorEntity)
        
    }
    
// MARK: - VideoScreen
    
    func createVideoItem(with fileName:String) -> AVPlayerItem?{
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp4") else
            { return nil }
        let asset = AVURLAsset(url:url)
        let videoItem = AVPlayerItem(asset: asset)
        return videoItem
    }
    
    func createVideoMaterial(videoItem: AVPlayerItem) -> VideoMaterial{
        let player = AVPlayer()
        let videoMaterial = VideoMaterial(avPlayer: player)
        player.replaceCurrentItem(with: videoItem)
        player.play()
        return videoMaterial
    }
    
    func createVideoScreen(width: Float, height: Float) -> ModelEntity {
        let screenMesh = MeshResource.generatePlane(width: width, depth: height)
        let videoItem = createVideoItem(with: "ReiIsLateForSchool")
        let videoMaterial = createVideoMaterial(videoItem: videoItem!)
        let videoScreenModel = ModelEntity(mesh: screenMesh, materials: [videoMaterial])
        return videoScreenModel
    }
    
}
