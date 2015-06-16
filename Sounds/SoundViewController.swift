//
//  SoundViewController.swift
//  Sensors
//
//  Created by Linda Cobb on 9/22/14.
//  Copyright (c) 2014 TimesToCome Mobile. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import AudioToolbox
import AudioUnit
import AVFoundation
import Accelerate


// incoming data - pressure
// calculate: frequency


class SoundViewController: UIViewController, AVCaptureAudioDataOutputSampleBufferDelegate
{
    
    // output to user
    @IBOutlet var dataLabel: UILabel!
    @IBOutlet var frequencyLabel: UILabel!
    @IBOutlet var graphView: GraphView!
    @IBOutlet var barGraphView: BarGraphView!
    
    // capture sound
    var captureSession: AVCaptureSession!
    var captureDevice: AVCaptureDevice!
    var captureDeviceInput: AVCaptureDeviceInput!
    var audioDataOutput: AVCaptureAudioDataOutput!
    var captureAudioDataOutput: AVCaptureAudioDataOutput!
    var data = [Float](count: 64, repeatedValue: 0.0)

    // trip wire so we can call stop session on main thread
    var stopUpdates = false
    
    
    // fft
    let windowSize = 64
    let windowSizeOverTwo = 32
    let hz = 1024   // sample rate 44,100 hz
    
    // get frequencies from data
    var frequency:Float = 0.0
    var max:Float = 0.0
    var imagp = [Float](count: 64, repeatedValue: 0.0)
    var zerosR = [Float](count: 64, repeatedValue: 0.0)
    var zerosI = [Float](count: 64, repeatedValue: 0.0)

    var log2n:vDSP_Length!
    var setup : COpaquePointer!
    

    // update fft arrays and call after after x loop counts
    let maxArrayPosition = 64 - 1
    let loopCount = 32       // number of data points between fft calls
    var graphLoopCount = 0
    var dataCount = 0


    
    required init( coder aDecoder: NSCoder ){ super.init(coder: aDecoder) }
    
    convenience override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!){ self.init(nibName: nil, bundle: nil) }

    
    
    
    override func viewDidLoad() {
        graphView.setupGraphView()
        barGraphView.setupGraphView()
        
        // set up memory for FFT
        log2n = vDSP_Length(log2(Double(windowSize)))
        setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
    }
   
    
    
   
    
    
    
    func setupCaptureSession(){
        
        // setup session
        captureSession = AVCaptureSession()
        var error: NSError?
        
        // inputs
        captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        captureDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(captureDevice, error: &error) as! AVCaptureDeviceInput
        
        if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
        }
        
        // outputs
        captureAudioDataOutput = AVCaptureAudioDataOutput()
        captureSession.addOutput(captureAudioDataOutput)
        
        let queue = dispatch_queue_create("com.timestocomemobile.queue", DISPATCH_QUEUE_SERIAL)
        captureAudioDataOutput.setSampleBufferDelegate(self, queue: queue)

        captureSession.startRunning()
        
    }
    
    
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        
        var totalBytes = 0 as UInt64
        
        let blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer)
        let lengthOfBlock = CMBlockBufferGetDataLength(blockBufferRef)
        
        let data = NSMutableData(length: Int(lengthOfBlock))
        CMBlockBufferCopyDataBytes(blockBufferRef, 0, lengthOfBlock, data!.mutableBytes)
        
        var samples = UnsafeMutablePointer<UInt8>(data!.mutableBytes)
        var value:UInt8 = samples.memory
        
        
        NSOperationQueue.mainQueue().addOperationWithBlock({

            // compute fft, update graph, give user data
            if self.stopUpdates == false {
                
                self.graphView.addX(value)
                self.dataLabel.text = NSString (format:"Data: %d", value) as String

                self.updateFFT(Float(value))
            }
        });
        
    }
    
    
    
     
    
    
    
    
    
    func updateFFT( x: Float){
    
        // first fill up array
        if  dataCount < windowSize {
            data[dataCount] = x
            dataCount++
    
        // then pop oldest off top push newest onto end
        }else{
            
            data.removeAtIndex(0)
            data.insert(x, atIndex: maxArrayPosition)
        }
    
        // call fft?
        if  graphLoopCount > loopCount {
        
            graphLoopCount = 0;
            FFT()
            
        }else{ graphLoopCount++; }
    }
    
    
    
   
    
    
    
    
    
    
    func FFT() {
       
        // parse data input into complex vector
    //    var cplxData = DSPSplitComplex( realp: &zerosR, imagp: &zerosI )
    //    var xAsComplex = UnsafePointer<DSPComplex>( data.withUnsafeBufferPointer { $0.baseAddress } )
    //    vDSP_ctoz( xAsComplex, 2, &cplxData, 1, vDSP_Length(windowSizeOverTwo) )
        

        var cplxData = DSPSplitComplex(realp: &data, imagp: &zerosI)
        
        //perform fft
        vDSP_fft_zrip( setup, &cplxData, 1, log2n, FFTDirection(kFFTDirection_Forward) )


        //calculate power
        var powerVector = [Float](count: 64, repeatedValue: 0.0)
        vDSP_zvmags(&cplxData, 1, &powerVector, 1, vDSP_Length(windowSizeOverTwo))
        
        
        
       // find peak power and bin
        var power = 0.0 as Float
        var bin = 0 as vDSP_Length

        vDSP_maxvi(&powerVector, 1, &power, &bin, vDSP_Length(windowSizeOverTwo))
        
        // convert power to frequency
        frequency = Float(hz) * Float(bin) / Float(windowSize);
        
        // push the data to the user
        frequencyLabel.text = NSString(format:"Frequency: %.2lf", self.frequency) as String
        
        // scale and send to bar graph
        // bar graph view has height of 200 pixels
      //  var scale:Float = 200.0/power         // viewHeight/maxValue
       // var scaledPowerVector = [Float](count: 128, repeatedValue: 0.0)
       // vDSP_vsmul(&powerVector, 1, &scale, &scaledPowerVector, 1, 128)
        
        barGraphView.addX(frequency)
       // println("***************************************************************************")
       // for i in 0..<128 { println("scaled value \(scaledPowerVector[i])" ) }
        
        var minF = 0
        var maxF:Float = Float(hz) * 64.0
        println("min \(minF) max \(maxF)")
        
    }
    

    
    
    
    
    
    
 
    
    @IBAction func stop(){
        
        stopUpdates = true
        if captureSession != nil {
            captureSession.stopRunning()
            captureSession = nil
        }
    }
    
    
    
    @IBAction func start(){
        stopUpdates = false
        setupCaptureSession()
    }
    
    
    
   
    
    
    override func viewDidDisappear(animated: Bool){
        super.viewDidDisappear(animated)
        stop()
        vDSP_destroy_fftsetupD(setup)
    }
    
}