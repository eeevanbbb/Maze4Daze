//
//  GameScene.swift
//  Maze
//
//  Created by Evan Bernstein on 11/11/16.
//  Copyright © 2016 Evan Bernstein. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate, MazeObserver {
    
    let marble = SKSpriteNode(imageNamed: "Marble")
    
    let motionManager = CMMotionManager()
    
    override func didMove(to view: SKView) {
        /* if let maze = readMaze(fromFilename: "first", type: "maze") {
            addMaze(maze: maze)
        } */
        
        MazeHandler.sharedInstance.generateMaze(width: 20, height: 20, completion: {
            maze in
            if let maze = maze {
                self.addMaze(maze: maze)
                self.resetMarble()
            }
        })
        
        //addScreenBorderWalls()
        
        backgroundColor = SKColor.white
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        configureMotionManager()
        
        addResetGesture()
        addPauseGesture()
        
        MazeHandler.sharedInstance.addObserver(observer: self)
    }
    
    func addMarble(position: CGPoint, size: CGSize) {
        marble.position = position
        marble.size = size
        addChild(marble)
        
        configureMarble()
    }
    
    func addResetGesture() {
        let resetGesture = UITapGestureRecognizer(target: self, action: #selector(GameScene.resetMarble))
        
        resetGesture.numberOfTapsRequired = 2
        
        view?.addGestureRecognizer(resetGesture)
    }
    
    func addPauseGesture() {
        let pauseGesture = UITapGestureRecognizer(target: self, action: #selector(GameScene.pause))
        
        pauseGesture.numberOfTapsRequired = 3
        
        view?.addGestureRecognizer(pauseGesture)
    }
    
    func pause() {
        if let gameVC = view?.window?.rootViewController as? GameViewController {
            var storyboardName = "Main"
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                storyboardName = "iPadMain"
            default:
                break
            }
            let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
            if let pauseViewController = storyboard.instantiateViewController(withIdentifier: "PauseVC") as? PauseViewController {
                gameVC.present(pauseViewController, animated: true, completion: nil)
            }
        }
    }
    
    func resetMarble() {
        marble.removeFromParent()
        
        addMarble(position: CGPoint(x: wallThickness, y: size.height - wallThickness), size: CGSize(width: min(tileWidth, tileHeight) - wallThickness * 2 - 1, height: min(tileWidth, tileHeight) - wallThickness * 2 - 1))
    }
    
    var wallThickness: CGFloat = 5
    var tileWidth: CGFloat = 10
    var tileHeight: CGFloat = 10
    
    func addMaze(maze: Maze) {
        tileWidth = size.width / CGFloat(maze.width)
        tileHeight = size.height / CGFloat(maze.height)
        
        wallThickness = min(tileWidth, tileHeight) / 5.0
        
        for tile in maze.tiles {
            let tileX = tileWidth * CGFloat(tile.position.0)
            let tileY = tileHeight * CGFloat(tile.position.1)
            
            if tile.bottomWall {
                addWall(topLeft: CGPoint(x: tileX, y: size.height - (tileY + tileHeight - wallThickness)), bottomRight: CGPoint(x: tileX + tileWidth, y: size.height - (tileY + tileHeight)))
            }
            if tile.leftWall {
                addWall(topLeft: CGPoint(x: tileX, y: size.height - tileY), bottomRight: CGPoint(x: tileX + wallThickness, y: size.height - (tileY + tileHeight)))
            }
            if tile.topWall {
                addWall(topLeft: CGPoint(x: tileX, y: size.height - tileY), bottomRight: CGPoint(x: tileX + tileWidth, y: size.height - (tileY + wallThickness)))
            }
            if tile.rightWall {
                addWall(topLeft: CGPoint(x: tileX + tileWidth - wallThickness, y: size.height - tileY), bottomRight: CGPoint(x: tileX + tileWidth, y: size.height - (tileY + tileHeight)))
            }
        }
    }
    
    func addScreenBorderWalls(ofWidth thickness: CGFloat = 30) {
        addWall(topLeft: CGPoint(x: 0, y: thickness), bottomRight: CGPoint(x: size.width, y: 0)) // Bottom
        addWall(topLeft: CGPoint(x: 0, y: size.height), bottomRight: CGPoint(x: size.width, y: size.height - thickness)) // Top
       addWall(topLeft: CGPoint(x: 0, y: size.height - thickness), bottomRight: CGPoint(x: thickness, y: thickness)) // Left
       addWall(topLeft: CGPoint(x: size.width - thickness, y: size.height - thickness), bottomRight: CGPoint(x: size.width, y: thickness)) // Right
    }
    
    func addWall(topLeft: CGPoint, bottomRight: CGPoint) {
        let wall = SKSpriteNode(imageNamed: "Wall")
        wall.name = "Wall"
        wall.size = CGSize(width: bottomRight.x - topLeft.x, height: topLeft.y - bottomRight.y)
        wall.position = CGPoint(x: topLeft.x + ((bottomRight.x - topLeft.x) / 2.0), y: bottomRight.y + ((topLeft.y - bottomRight.y) / 2.0))
        
        wall.physicsBody = SKPhysicsBody(rectangleOf: wall.size)
        wall.physicsBody?.affectedByGravity = false
        wall.physicsBody?.isDynamic = false
        
        addChild(wall)
    }
    
    func removeMaze() {
        for child in children {
            if child.name == "Wall" {
                child.removeFromParent()
            }
        }
    }
    
    func configureMarble() {
        marble.physicsBody = SKPhysicsBody(circleOfRadius: marble.size.width / 2)
        marble.physicsBody?.isDynamic = true
        marble.physicsBody?.mass = 0.02
    }
    
    func configureMotionManager() {
        motionManager.startAccelerometerUpdates()
    }
    
    override func update(_ currentTime: TimeInterval) {
        processUserMotion(forUpdate: currentTime)
    }
    
    func processUserMotion(forUpdate currentTime: CFTimeInterval) {
        if let data = motionManager.accelerometerData {
            marble.physicsBody?.applyForce(CGVector(dx: -10 * CGFloat(data.acceleration.y), dy: 10 * CGFloat(data.acceleration.x)))
        }
    }
    
    // MARK: - MazeObserver
    
    func identifier() -> String {
        return "GameScene"
    }
    
    func currentMazeDidChange(newMaze: Maze?) {
        if let maze = newMaze {
            removeMaze()
            addMaze(maze: maze)
            resetMarble()
        }
    }
}
