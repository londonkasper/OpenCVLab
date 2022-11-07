//
//  ViewController.swift
//  ImageLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.

//  Modified by London Kasper, Jeremy Waibel, Carys LeKander 2022
//
import UIKit
import AVFoundation

class ViewController: UIViewController   {

    @IBOutlet weak var smileLabel: UILabel!
    @IBOutlet weak var rightEyeLabel: UILabel!
    @IBOutlet weak var leftEyeLabel: UILabel!
    @IBOutlet weak var angleLabel: UILabel!
    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    lazy var videoManager:VideoAnalgesic! = {
        let tmpManager = VideoAnalgesic(mainView: self.view)
        tmpManager.setCameraPosition(position: .back)
        return tmpManager
    }()
    
    lazy var detector:CIDetector! = {
        // create dictionary for face detection
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: self.videoManager.getCIContext(),
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorTracking:true, CIDetectorEyeBlink: true, CIDetectorSmile: true])
        //tried to set up detectors but for some reason the smile and eye blink detectors don't seem to be working at all. Both always return false no matter what.
        return detector
    }()
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // no background needed
        self.view.backgroundColor = nil
        self.setupFilters()
        
        self.videoManager.setCameraPosition(position: .front)
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
    
    }
    
    //MARK: Setup filtering
    func setupFilters(){
        filters = []
        //set up distortion filters for eyes
        let filterEyesL = CIFilter(name:"CIBumpDistortion")!
        filterEyesL.setValue(-0.5, forKey: "inputScale")
        filterEyesL.setValue(75, forKey: "inputRadius")
        filters.append(filterEyesL)
        
        let filterEyesR = CIFilter(name:"CIBumpDistortion")!
        filterEyesR.setValue(-0.9, forKey: "inputScale")
        filterEyesR.setValue(75, forKey: "inputRadius")
        filters.append(filterEyesR)
        //set up distortion filter for mouth
        let filterMouth = CIFilter(name:"CIBumpDistortion")!
        filterMouth.setValue(-0.8, forKey: "inputScale")
        filterMouth.setValue(75, forKey: "inputRadius")
        filters.append(filterMouth)
        
    }
    
    //MARK: Apply filters and apply feature detectors
    func applyFiltersToFaces(inputImage:CIImage,features:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        
        //set up variables to assign later
        var eyeCenterL = CGPoint()
        let eyeRadL = 40
        var eyeCenterR = CGPoint()
        let eyeRadR = 40
        
        var mouthCenter = CGPoint()
        let mouthRad = 60
        
        var faceAng:Float = 0.0
        
        for f in features { // for each face
            //find the position of the left eye
            eyeCenterL.x = f.leftEyePosition.x
            eyeCenterL.y = f.leftEyePosition.y
            
            //find the position of the right eye
            eyeCenterR.x = f.rightEyePosition.x
            eyeCenterR.y = f.rightEyePosition.y
            
            //find the mouth position
            mouthCenter.x = f.mouthPosition.x
            mouthCenter.y = f.mouthPosition.y
            
            //find the angle of the face
            faceAng = f.faceAngle
            
            print(faceAng) // for testing purposes-- seems to be extremely inconsistent
            DispatchQueue.main.async { //allow us to update UI elements
                self.angleLabel.text = "Face Angle: \(faceAng)"
                if(!f.rightEyeClosed){
                    self.rightEyeLabel.text = "Right Eye Open"
                }
                else{
                    self.rightEyeLabel.text = "Right Eye Closed"//never detects it being closed

                }
                if(!f.leftEyeClosed){
                    self.leftEyeLabel.text = "Left Eye Open"
                }
                else{
                    self.leftEyeLabel.text = "Left Eye Closed"//never detects it being closed
                }
                if(f.hasSmile){
                    self.smileLabel.text = "Smile Detected" //never detects a smile for some reason
                }
                else{
                    self.smileLabel.text = "No Smile Detected"
                }
            }

            if(f.rightEyeClosed && f.leftEyeClosed){
                print("blinked!") //never gets here because both values are always false
            }
            if(f.hasSmile){
                print("smiling") //never gets this far either
            }
            
            //set the values for the eye filters
            filters[0].setValue(CIVector(cgPoint: eyeCenterL), forKey: "inputCenter")
            filters[0].setValue(eyeRadL, forKey: "inputRadius")
            filters[1].setValue(CIVector(cgPoint: eyeCenterR), forKey: "inputCenter")
            filters[1].setValue(eyeRadR, forKey: "inputRadius")
            
            // now the mouth info
            filters[2].setValue(CIVector(cgPoint: mouthCenter), forKey: "inputCenter")
            filters[2].setValue(mouthRad, forKey: "inputRadius")
            
            for filt in filters{
                filt.setValue(retImage, forKey: kCIInputImageKey)
                retImage = filt.outputImage!
            }
        }
        return retImage
    }
    
    
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation] //this might be the problem
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
    }
    
    
    //MARK: Process image output
    func processImage(inputImage:CIImage) -> CIImage{
        
        // detect faces
        let faces = getFaces(img: inputImage)
        
        // if no faces, just return original image
        if faces.count == 0 { return inputImage }

        for f in faces{
            
            print(f.rightEyeClosed) // :( never true for some reason
            if(f.hasSmile){
                print("smile detected") //never gets here
            }
            if(f.leftEyeClosed && f.rightEyeClosed){
                print("eyes shut") //never gets here
            }
        }
        
        //otherwise apply the filters to the faces
        return applyFiltersToFaces(inputImage: inputImage, features: faces)
    }
    

   
}
