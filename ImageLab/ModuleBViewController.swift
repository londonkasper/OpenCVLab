//
//  ModuleBViewController.swift
//  ImageLab
//
//  Created by Jeremy Waibel on 11/6/22.
//  Copyright © 2022 Eric Larson. All rights reserved.
//

import UIKit
import Charts
import TinyConstraints

class ModuleBViewController: UIViewController, ChartViewDelegate {

    @IBOutlet weak var lineChartView: LineChartView!
    var currFrame = 0

    var videoManager:VideoAnalgesic! = nil
    let bridge = OpenCVBridge()
    var isFlashOn = false;

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = nil
        
        self.lineChartView.backgroundColor = .black
        
        self.videoManager = VideoAnalgesic(mainView: self.view)
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
        
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
        let retImage = inputImage
        self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
        
        let averageRed = self.bridge.processFinger(isFlashOn)
        if(!isFlashOn) {
            //detect finger
            if(averageRed != -1.0) {
                self.videoManager.turnOnFlashwithLevel(1.0)
                isFlashOn = true
                
                //Give the flash enough time to get better data
                sleep(2) //will sleep for 2 second
            }
        } else {
            //finger has been detected previously

            //See if finger moved off
            if(averageRed == -1.0) {
                //turn off flash
                self.videoManager.turnOffFlash()
                isFlashOn = false
                //Restart data collecting
                currFrame=0
                DispatchQueue.main.async {
                    self.lineChartView.clearValues()
                }
            } else {
                //Main queue since i want live updates
                DispatchQueue.main.async {
                    self.updateCounter(newData: averageRed)
                }
            }
        }
        //print(averageRed)
        return retImage
    }
    
        func updateCounter(newData:Double) {
            if(currFrame==0) {
                //setup new view
                self.lineChartView.delegate = self
                let set_a: LineChartDataSet = LineChartDataSet(entries:[ChartDataEntry(x: Double(0), y: newData)], label: "average red value per frame")
                set_a.drawCirclesEnabled = false
                set_a.setColor(UIColor.red)
                
                lineChartView.xAxis.labelPosition = .bottom
                self.lineChartView.data = LineChartData(dataSets: [set_a])
            } else {
                self.lineChartView.data?.appendEntry(ChartDataEntry(x: Double(currFrame), y: newData), toDataSet: 0)
                self.lineChartView.notifyDataSetChanged()
                self.lineChartView.moveViewToX(Double(currFrame))
                self.lineChartView.setVisibleXRange(minXRange: Double(1), maxXRange: Double(150))
            }
            currFrame = currFrame + 1
        }
}



