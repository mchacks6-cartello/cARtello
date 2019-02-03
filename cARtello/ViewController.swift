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
import DataIngest
import RealTimeSim
import CarModel

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, RealTimeSimDelegate, CarModelDelegate {
    
    
    enum Constants {
        static let tileDimen: CGFloat = 1
        static let initialRadius: Double = 0.005
    }
    
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet var sceneView: ARSCNView!
    let config = ARWorldTrackingConfiguration()
    let dataIngest: DataIngest! = DataIngest.init(jsonName: "ExperimentalData")
    var realTimeSim: RealTimeSim!
//    let carModel = CarModel(decisionAlgorithm: PowerLevelAvoidDisconnectAlgorithm(minimumRSSI: -50))
    let carModel = CarModel(decisionAlgorithm: PowerLevelAlgorithm())
    
    var anchorVector: simd_float3!

    var node: SCNNode!
    var tile: SCNNode!
    var car: SCNNode!
    var currentCarPosLat: Double!
    var currentCarPosLong: Double!
    var currentCarPosVector: SCNVector3!

    
    lazy var center = dataIngest.dataPoints.first!
    
    var currentRadius = Constants.initialRadius
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realTimeSim = RealTimeSim.init(dataIngest: dataIngest, frequency: 0.5)
        carModel.delegate = self
        realTimeSim.delegate = self
    }
    
    /// - Tag: StartARSession
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Start the view's AR session with a configuration that uses the rear camera,
        // device position and orientation tracking, and plane detection.
        config.planeDetection = [.horizontal]
        config.worldAlignment = .gravityAndHeading
        sceneView.session.run(config)
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self
        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Show debug UI to view performance metrics (e.g. frames per second).
        sceneView.showsStatistics = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's AR session.
        sceneView.session.pause()
    }
    

    func createCarNode(anchor: simd_float3) -> SCNNode {
        let carNode = SCNNode(geometry: SCNBox(width: 0.05, height: 0.05, length: 0.05, chamferRadius: 0.005))
        carNode.position = SCNVector3(anchor.x, 0, anchor.z)
        carNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red;
        return carNode
    }
    
    func createFloorNode(anchor: simd_float3, mapTile: UIImage) -> SCNNode {
        let floorNode = SCNNode(geometry: SCNPlane(width: Constants.tileDimen, height: Constants.tileDimen))
        floorNode.position = SCNVector3(anchor.x, 0, anchor.z)
        floorNode.orientation = SCNQuaternion(0, 0, 0, 0)
        floorNode.geometry?.firstMaterial?.diffuse.contents = mapTile
        floorNode.geometry?.firstMaterial?.isDoubleSided = true
        floorNode.eulerAngles = SCNVector3(Double.pi/2,0,-Double.pi)
        return floorNode
    }
    
    func setCarPos(_ dataPoint: DataPoint) {
        if self.currentCarPosLat != nil {
            self.currentCarPosVector = self.car.position
            let newVec = scaleCoordinates(latitude: dataPoint.latitude, longitude: dataPoint.longitude)
            SCNTransaction.animationDuration = 1.0
            var vecAnchor = SCNVector3()
            vecAnchor.x = self.car.position.x - newVec.x
            vecAnchor.z = self.car.position.z - newVec.z
            self.car.position = vecAnchor
            self.currentCarPosLat = dataPoint.latitude
            self.currentCarPosLong = dataPoint.longitude
        } else {
            let carNode = self.createCarNode(anchor: self.anchorVector)
            self.node.addChildNode(carNode)
            self.car = carNode
            
            self.currentCarPosLat = dataPoint.latitude
            self.currentCarPosLong = dataPoint.longitude
        }
    }
    
    func scaleCoordinates(latitude: Double, longitude: Double)  -> SCNVector3 {
        
        let diffLat:CGFloat = CGFloat(self.currentCarPosLat - latitude)
        let diffLong:CGFloat = CGFloat(self.currentCarPosLong - longitude)

        let tileLat: CGFloat = CGFloat(dataIngest.metadata.maxLatitude - self.dataIngest.metadata.minLatitude)
        let tileLong: CGFloat = CGFloat(dataIngest.metadata.maxLongitude - self.dataIngest.metadata.minLongitude)
        
        print  (SCNVector3(diffLat / tileLat * Constants.tileDimen,0 , diffLong / tileLong * Constants.tileDimen))
        return SCNVector3(diffLat / tileLat * Constants.tileDimen,0 , diffLong / tileLong * Constants.tileDimen)
    
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard self.anchorVector == nil else { return }
        
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        self.anchorVector = planeAnchor.center
        self.node = node
        createMapTile() {(snapshot, err) in
            guard let image = snapshot?.image else {
                print(err.debugDescription)
                return
            }
            if let tile = self.tile {
                tile.geometry?.firstMaterial?.diffuse.contents = image
            } else {
                let node = self.createFloorNode(anchor: self.anchorVector, mapTile: image)
                self.node.addChildNode(node)
                self.tile = node
            }
        }
        realTimeSim.start()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
    }
    
    func createMapTile(completion: @escaping MKMapSnapshotter.CompletionHandler) {
        let mapSnapshotOptions = MKMapSnapshotter.Options()
        
        let (latitude, longitude) = (center.latitude, center.longitude)
        let location = CLLocationCoordinate2DMake(latitude, longitude)
        let metadata = dataIngest.metadata
        let region = MKCoordinateRegion.init(center: location, span: .init(latitudeDelta: metadata.maxLatitude - metadata.minLatitude, longitudeDelta: metadata.maxLongitude - metadata.minLongitude))
        mapSnapshotOptions.region = region
//        mapSnapshotOptions.scale = UIScreen.main.scale
//        mapSnapshotOptions.size = CGSize(width: 600, height: 600)
        mapSnapshotOptions.showsBuildings = true
        mapSnapshotOptions.showsPointsOfInterest = true
        
        let snapShotter = MKMapSnapshotter(options: mapSnapshotOptions)
        snapShotter.start(completionHandler: completion);
    }
    
    // MARK: - RealTimeSimDelegate
    func realTimeSim(_ realTimeSim: RealTimeSim, didPingDataPoint dataPoint: DataPoint) {
//        if currentMaxLat == nil {
//            setCurrentBoogles(with: dataPoint)
//            setTileImage(dataPoint)
//        } else if dataPoint.latitude > currentMaxLat || dataPoint.latitude < currentMinLat || dataPoint.longitude > currentMaxLong || dataPoint.longitude < currentMinLong {
//            currentRadius += Constants.initialRadius
//            setCurrentBoogles(with: dataPoint)
//            setTileImage(dataPoint)
//        }
        
        setCarPos(dataPoint)
        self.carModel.process(networks: dataPoint.networks)
    }
    
    
    func setTileImage(_ dataPoint: DataPoint) {
        createMapTile() {(snapshot, err) in
            guard let image = snapshot?.image else {
                print(err.debugDescription)
                return
            }
            if let tile = self.tile {
                tile.geometry?.firstMaterial?.diffuse.contents = image
            } else {
                let node = self.createFloorNode(anchor: self.anchorVector, mapTile: image)
                self.node.addChildNode(node)
                self.tile = node
            }
        }
    }
    
    func realTimeSimDidFinishSimulation(_ realTimeSim: RealTimeSim) {
        print("Done")
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
//        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
//        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
//        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.resetTracking()
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Private methods
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
//        let message: String
        
//        switch trackingState {
//        case .normal where frame.anchors.isEmpty:
//            // No planes detected; provide instructions for this app's AR interactions.
//            message = "Move the device around to detect horizontal and vertical surfaces."
//
//        case .notAvailable:
//            message = "Tracking unavailable."
//
//        case .limited(.excessiveMotion):
//            message = "Tracking limited - Move the device more slowly."
//
//        case .limited(.insufficientFeatures):
//            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
//
//        case .limited(.initializing):
//            message = "Initializing AR session."
//
//        default:
//            // No feedback needed when tracking is normal and planes are visible.
//            // (Nor when in unreachable limited-tracking states.)
//            message = ""
//
//        }
////
//        sessionInfoLabel.text = message
//        sessionInfoView.isHidden = message.isEmpty
    }
    
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func carModel(_ carModel: CarModel, didUpdateConnectionState connectionState: ConnectionState) {
        let string = "Possible networks: \n" +

            carModel.availableNetworks.joined(separator: "\n") + "\n --- \nConnected to: " + carModel.currNetwork
        self.sessionInfoLabel.text = string
        
    }
}


