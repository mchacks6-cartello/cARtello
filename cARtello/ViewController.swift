//
//  ViewController.swift
//  cARtello
//
//  Created by Russell Pecka on 2/2/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation
import MapKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    let config = ARWorldTrackingConfiguration()
    var mapTile: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       // sceneView.debugOptions =
            //[ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]
        config.planeDetection = .horizontal
        
        sceneView.session.run(config)
    
        sceneView.delegate = self
        
        createMapTile(coordinate: CLLocationCoordinate2DMake(45.45958658333333, -73.82274576666667)) {(snapshot, err) in
            guard let image = snapshot?.image else {
                return
            }
            self.mapTile = image
        }
    }
    
    func createFloorNode(anchor:ARPlaneAnchor) ->SCNNode{
        let floorNode = SCNNode(geometry: SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))) //1
        floorNode.position=SCNVector3(anchor.center.x,0,anchor.center.z)                                               //2
        floorNode.geometry?.firstMaterial?.diffuse.contents = self.mapTile                                          //3
        floorNode.geometry?.firstMaterial?.isDoubleSided = true                                                        //4
        floorNode.eulerAngles = SCNVector3(Double.pi/2,0,0)                                                    //5
        return floorNode                                                                                               //6
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return} //1
        
        let planeNode = self.createFloorNode(anchor: planeAnchor)
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        
        let planeNode = self.createFloorNode(anchor: planeAnchor)
        node.addChildNode(planeNode)
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
    }
    
    func createMapTile(coordinate: CLLocationCoordinate2D, completion: @escaping MKMapSnapshotter.CompletionHandler) {
        let radius: Double = 1000
        let mapSnapshotOptions = MKMapSnapshotter.Options()
        
        let location = coordinate
        let region = MKCoordinateRegion(center: location, latitudinalMeters: radius, longitudinalMeters: radius)
        mapSnapshotOptions.region = region
        mapSnapshotOptions.scale = UIScreen.main.scale
        mapSnapshotOptions.size = CGSize(width: 300, height: 300)
        mapSnapshotOptions.showsBuildings = true
        mapSnapshotOptions.showsPointsOfInterest = true
        
        let snapShotter = MKMapSnapshotter(options: mapSnapshotOptions)
        snapShotter.start(completionHandler: completion);
    }
    

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
//     func session(_ session: ARSession, didFailWithError error: Error) {
//         Present an error message to the user
//
//    }
//
//    func sessionWasInterrupted(_ session: ARSession) {
//         Inform the user that the session has been interrupted, for example, by presenting an overlay
//        
//    }
//
//    func sessionInterruptionEnded(_ session: ARSession) {
//         Reset tracking and/or remove existing anchors if consistent tracking is required
//        
//    }
}


