//
//  ViewController.swift
//  BasketBallAR
//
//  Created by Jason Lee on 8/27/18.
//  Copyright © 2018 Jason Lee. All rights reserved.
//

import UIKit
import ARKit
import Each

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var score: UILabel!
    @IBOutlet weak var planeDetected: UILabel!
    @IBOutlet weak var plus: UIButton!
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var power: Float = 1.0
    let timer = Each(0.05).seconds
    var basketAdded: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        self.sceneView.autoenablesDefaultLighting = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.basketAdded == true {
            timer.perform(closure: { () -> NextStep in
                self.power = self.power + 1
                return .continue
            })
        
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.basketAdded == true{
            self.timer.stop()
            self.shootBall()
            
        }
        self.power = 1
    }
    
    func shootBall() {
        guard let pointOfView = self.sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let position = location + orientation
        let ball = SCNNode(geometry: SCNSphere(radius: 0.3))
        ball.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "ball")
        ball.position = position
        self.sceneView.scene.rootNode.addChildNode(ball)
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
        ball.physicsBody = body
        ball.name = "basketball"
        body.restitution = 0.1
        ball.physicsBody?.applyForce(SCNVector3(orientation.x * power, orientation.y * power, orientation.z * power), asImpulse: true)
        self.sceneView.scene.rootNode.addChildNode(ball)
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
        if !hitTestResult.isEmpty {
            self.addBasket(hitTestResult: hitTestResult.first!)
        }
    }

    func addBasket(hitTestResult: ARHitTestResult) {
        if basketAdded == false {
        let basketScene = SCNScene(named: "Basketball.scnassets/Basketball.scn")
        let basketNode = basketScene?.rootNode.childNode(withName: "Basket", recursively: false)
        let positionOfPlane = hitTestResult.worldTransform.columns.3
        let xposition = positionOfPlane.x
        let yposition = positionOfPlane.y
        let zposition = positionOfPlane.z
        basketNode?.position = SCNVector3(xposition, yposition, zposition)
        basketNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: basketNode!, options: [SCNPhysicsShape.Option.keepAsCompound : true, SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        self.sceneView.scene.rootNode.addChildNode(basketNode!)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.basketAdded = true
        }
    }
    }
    
    func didScore() {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async {
           self.planeDetected.isHidden = false
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3){
            self.planeDetected.isHidden = true
        }
    }
    
    func removeEveryOtherBall() {
        self.sceneView.scene.rootNode.enumerateChildNodes{ (node, _) in
            if node.name == "basketball"{
                node.removeFromParentNode()
            }
        }
    }
    
    deinit {
        self.timer.stop()
    }
    
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

