//
//  ViewController.swift
//  NYCKnobViewDemo
//
//  Created by Joshua Weinberg on 6/6/16.
//  Copyright © 2016 3rd Street Apps. All rights reserved.
//

import UIKit

class ViewController: UIViewController, NYCKnobViewDelegate {
    
    // MARK: IBOutlet methods

    @IBOutlet weak var resetBtn: UIButton!
    @IBOutlet weak var knobView1: NYCKnobView!
    @IBOutlet weak var knobView2: NYCKnobView!
    @IBOutlet weak var knobView3: NYCKnobView!
    @IBOutlet weak var knobView4: NYCKnobView!
    @IBOutlet weak var lbl1: UILabel!
    
    // MARK: IBAction method(s)

    @IBAction func handleResetBtn(sender: UIButton?){
        self.configureKnobValues()
        self.lbl1.text = "Reset all knobs"
    }

    // MARK: Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureKnobViews()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.configureKnobValues()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Init methods

    func configureKnobViews(){
        self.knobView1.delegate = self
        self.knobView1.minValue = 1
        self.knobView1.maxValue = 11
        self.knobView1.knobFormatType = NYCKnobFormatType.Integer

        // default settings
        self.knobView2.delegate = self
     
        self.knobView3.delegate = self
        self.knobView3.minValue = 0
        self.knobView3.maxValue = 1.0
        self.knobView3.knobFormatType = NYCKnobFormatType.Percentage

        self.knobView4.delegate = self
    }
    
    func configureKnobValues(){
        self.knobView1.value = 4
        self.knobView2.value = 0.4
        self.knobView3.value = 0.1
        self.knobView4.value = 0.1
    }

    // MARK: NYCKnobViewDelegate method(s)
    
    func knobValueChanged(sender: NYCKnobView){
        self.showKnobValues(sender)
    }
    
    func knobValueUpdateComplete(sender: NYCKnobView){
        self.showKnobValues(sender)
    }
    
    func showKnobValues(sender: NYCKnobView){
        
        var text = ""
        let dataStr = NSString(format: "%.2f", sender.value) as String
        
        if( sender == knobView1){
            text = "NYCKnobView #1 updated: \(dataStr) debugString: \(sender.debugString)"
        } else if(sender == knobView2){
            text = "NYCKnobView #2 updated :\(dataStr) debugString: \(sender.debugString)"
        } else if(sender == knobView3){
            text = "NYCKnobView #3 updated :\(dataStr) debugString: \(sender.debugString)"
        } else if(sender == knobView4){
            text = "NYCKnobView #4 updated: \(dataStr) debugString: \(sender.debugString)"
        }
        
        self.lbl1.text = text

    }
}

