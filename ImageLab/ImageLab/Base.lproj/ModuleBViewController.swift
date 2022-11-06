//
//  ModuleBViewController.swift
//  ImageLab
//
//  Created by Jeremy Waibel on 11/6/22.
//  Copyright © 2022 Eric Larson. All rights reserved.
//

import UIKit
import Charts

class ModuleBViewController: UIViewController, ChartViewDelegate {

    var videoManager:VideoAnalgesic! = nil
    let bridge = OpenCVBridge()
    var isFlashOn = false;

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = nil

        self.videoManager = VideoAnalgesic(mainView: self.view)
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
        
        self.createGraph()
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImageSwift)
        if !videoManager.isRunning{
            videoManager.start()
        }
    }
    
    func processImageSwift(inputImage:CIImage) -> CIImage{
        
        /**
         TODO:
         averge red is not saved in vector/array, bpm needs to be visible
            using cocoa pods charts package (idk if you need to setup on your mac)
         */
        //Setup image to be processable
        var retImage = inputImage
        self.bridge.setTransforms(self.videoManager.transform)
        self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
        
        let averageRed = self.bridge.processFinger(isFlashOn)
        if(!isFlashOn) {
            //detect finger
            if(averageRed != -1.0) {
                self.videoManager.turnOnFlashwithLevel(1.0)
                isFlashOn = true
                
                //Give the flash enough time to get better data
                sleep(1)
            }
        } else {
            //finger has been detected

            //See if finger moved off
            if(averageRed == -1.0) {
                //turn off flash
                self.videoManager.turnOffFlash()
                isFlashOn = false
                //Restart data collecting

                //Give the flash enough time to get better data
                sleep(1)	
            }
        }
        print(averageRed)
        return retImage
    }

    func createGraph() {
//           self.chartView.delegate = self
//           let set_a: LineChartDataSet = LineChartDataSet(values:[ChartDataEntry(x: Double(0), y: Double(0))], label: "voice")
//           set_a.drawCirclesEnabled = false
//           set_a.setColor(UIColor.blue)
//
//           let set_b: LineChartDataSet = LineChartDataSet(values: [ChartDataEntry(x: Double(0), y: Double(0))], label: "flow")
//           set_b.drawCirclesEnabled = false
//           set_b.setColor(UIColor.green)
//
//           self.chartView.data = LineChartData(dataSets: [set_a,set_b])
//           timer = Timer.scheduledTimer(timeInterval: 0.010, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
}
