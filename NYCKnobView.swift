//
//  NYCKnobView.swift
//  NYCKnobViewDemo
//
//  Created by Joshua Weinberg on 6/13/16.
//  Copyright © 2016 3rd Street Apps. All rights reserved.
//

import UIKit

// Enum for type of data to be handled by the knob
enum NYCKnobFormatType: Int {
    case decimal = 0
    case integer
    case percentage
}

fileprivate let _startAngle = CGFloat(Double.pi * -1.328)
fileprivate let _endAngle = CGFloat(Double.pi * 0.328)

@IBDesignable class NYCKnobView: UIControl {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var knobBg: UIImageView!
    @IBOutlet weak var knobPointer: UIImageView!
    @IBOutlet weak var valueLbl: UILabel!
    
    // MARK: Private vars
    
    fileprivate var _value = 0.0 as CGFloat
    fileprivate var gestureRecognizer: NYCRotationGestureRecognizer?
    fileprivate var valueRange: CGFloat {
        return self.maximumValue - self.minimumValue
    }
    
    // MARK: Public Ivars
    
    var continuous = true
    var imageTint: UIColor? {
        didSet {
            self.knobBg.image = self.knobBg.image?.withRenderingMode(.alwaysTemplate)
            self.knobPointer.image = self.knobPointer.image?.withRenderingMode(.alwaysTemplate)
            self.knobBg.tintColor = imageTint
            self.knobPointer.tintColor = imageTint
        }
    }
    var knobFormatType: NYCKnobFormatType = NYCKnobFormatType.decimal
    var view: UIView! // holder for view elements loaded from the nib
    var debugString: String {
        get {
            return "rotation : \(NSString(format: "%.3f", self.gestureRecognizer!.rotation)), pointerAngle: \(NSString(format: "%.3f", self.pointerAngle)) & value: \(NSString(format: "%.3f", _value))"
        }
    }
    var value: Float {
        get {
            if self.knobFormatType == .integer {
                return round(Float(_value))
            } else {
                return Float(_value)
            }
        }
        set {
            if self.knobFormatType == .integer {
                setValue(CGFloat(round(newValue)), animated: true)
            } else {
                setValue(CGFloat(newValue), animated: true)
            }
            self.valueLbl.text = self.convertFloatToString(_value)
        }
    }
    var pointerAngle: CGFloat = _startAngle {
        willSet {
            self.setPointerAngle(newValue, animated: false)
        }
    }
    
    @IBInspectable var startAngle = _startAngle
    @IBInspectable var endAngle = _endAngle
    @IBInspectable var minimumValue = 0.0 as CGFloat
    @IBInspectable var maximumValue = 1.0 as CGFloat
    
    // MARK: Override(s)
    
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                self.alpha = 1.0
            } else {
                self.alpha = 0.65
            }
        }
    }
    
    // MARK: Lifcycle Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initKnob()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initKnob()
    }
    
    // MARK: Configuration Methods
    
    fileprivate func initKnob() {
        self.setupNib()
        self.configGestureRecognizer()
        // set knob angle to start value position
        self.setKnobAngleFor(CGFloat(self.value), animated:false)
    }
    
    fileprivate func configGestureRecognizer() {
        self.gestureRecognizer = NYCRotationGestureRecognizer(target: self, action: #selector(NYCKnobView.handleRotation(_:)))
        self.addGestureRecognizer(self.gestureRecognizer!)
    }
    
    fileprivate func setupNib() {
        self.view = loadViewFromNib()
        self.view.frame = bounds
        self.view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        addSubview(self.view)
    }
    
    fileprivate func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nibName = String(describing: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        let retview = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return retview
    }
    
    // MARK: Private Helper Methods
    
    fileprivate func convertFloatToString(_ val:CGFloat) -> String {
        
        var retString = NSString()
        
        switch self.knobFormatType {
        case .decimal:
            retString = NSString(format: "%.1f", val)
            
            // get rid of the decimal for max, min, and when it starts with '0.0'
            if val <= self.minimumValue || val >= self.maximumValue || retString.hasPrefix("0.0") {
                retString = NSString(format: "%.0f", val)
            }
            
        case .integer:
            
            retString = NSString(format: "%.0f", val)
        
        case .percentage:
        
            retString = NSString(format: "%.0f%%", val*100)
            if val <= self.minimumValue || val >= self.maximumValue {
                retString = NSString(format: "%.0f", val*100)
            }
        }
        
        return retString as String
    }
    
    // MARK: Public Helper Methods
    
    func resetKnob() {
        self.setValue(_value, animated:true)
    }
    
    func setPointerAngle(_ pointerAngle: CGFloat, animated: Bool) {
        self.movePointerToAngle(pointerAngle, animated: animated)
    }
    
    func setValue(_ value: CGFloat, animated: Bool) {
        // limit the backing value to the specified bounds
        _value = min(self.maximumValue, max(self.minimumValue, value))
        self.setKnobAngleFor(value, animated: animated)
    }
    
    // private helper
    func setKnobAngleFor(_ value: CGFloat, animated: Bool) {
        // update the knob with the correct angle
        let angleRange = self.endAngle - self.startAngle
        let angle = (value - self.minimumValue) / self.valueRange * angleRange + self.startAngle
        self.setPointerAngle(angle, animated: animated)
    }
    
    func movePointerToAngle(_ pointerAngle: CGFloat, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25
                , delay: 0
                , options: [.curveEaseOut, .beginFromCurrentState]
                , animations: {
                    self.knobPointer?.transform = CGAffineTransform(rotationAngle: pointerAngle)
                }, completion: nil)
            
        } else {
            self.knobPointer?.transform = CGAffineTransform(rotationAngle: pointerAngle)
        }
    }
    
    // MARK: Handler Method(s)
    
    @objc
    func handleRotation(_ sender: AnyObject) {
        let gr = sender as! NYCRotationGestureRecognizer
        
        // 1. Mid-point angle
        let midPointAngle = (2.0 * CGFloat(Double.pi) + self.startAngle - self.endAngle) / 2.0 + self.endAngle
        
        // 2. Ensure the angle is within a suitable range
        var boundedAngle = gr.rotation
        if boundedAngle > midPointAngle {
            boundedAngle -= 2.0 * CGFloat(Double.pi)
        } else if boundedAngle < (midPointAngle - 2.0 * CGFloat(Double.pi)) {
            boundedAngle += 2 * CGFloat(Double.pi)
        }
        
        // 3. Bound the angle within a suitable range
        boundedAngle = min(self.endAngle, max(self.startAngle, boundedAngle))
        
        // 4. Convert the angle to a value
        let angleRange = self.endAngle - self.startAngle
        let valueForAngle = (boundedAngle - self.startAngle) / angleRange * self.valueRange + self.minimumValue
        
        // 5. Set the control to this value
        self.setValue(valueForAngle, animated:false)
        self.valueLbl.text = self.convertFloatToString(valueForAngle)
        
        // Notify of value change
        if continuous {
            sendActions(for: .valueChanged)
        } else {
            // Only send an update if the gesture has completed
            if gr.state == UIGestureRecognizerState.ended || gr.state == UIGestureRecognizerState.cancelled  {
                sendActions(for: .valueChanged)
            }
        }
    }
}

// MARK: IBDesignable Extention

extension NYCKnobView {
    
    // MARK: Inspectables
    
    @IBInspectable var initialValue: Float {
        get {
            return Float(self.value)
        }
        set {
            self.setValue(CGFloat(newValue), animated:false)
        }
    }
    
    @IBInspectable var knobFormat: Int {
        get {
            return self.knobFormatType.rawValue
        }
        set {
            self.knobFormatType = NYCKnobFormatType(rawValue:newValue) ?? NYCKnobFormatType.decimal
        }
    }
    
    @IBInspectable var knobBgImage: UIImage? {
        get {
            return self.knobBg?.image
        }
        set {
            self.knobBg?.image = newValue?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    @IBInspectable var knobPointerImage: UIImage? {
        get {
            return self.knobPointer?.image
        }
        set {
            self.knobPointer?.image = newValue?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    @IBInspectable var textColor: UIColor? {
        get {
            return self.valueLbl.textColor
        }
        set {
            if let newColor = newValue {
                self.valueLbl.textColor = newColor
            }
        }
    }
    
    @IBInspectable var knobTint: UIColor? {
        get {
            return self.imageTint
        }
        set {
            if let newColor = newValue {
                self.imageTint = newColor
            }
        }
    }
    
    @IBInspectable var knobBgColor: UIColor? {
        get{
            return self.view.backgroundColor
        }
        set {
            if let newColor = newValue {
                self.view.backgroundColor = newColor
            }
        }
    }
    
    @IBInspectable var knobCornerRadius: CGFloat {
        get {
            return self.view.layer.cornerRadius
        }
        set {
            self.view.layer.cornerRadius = newValue
            self.view.layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var knobBorderWidth: CGFloat {
        get {
            return self.view.layer.borderWidth
        }
        set {
            self.view.layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var knobBorderColor: UIColor? {
        get {
            var retColor:UIColor?
            if let cgColor = self.view.layer.borderColor {
                retColor = UIColor(cgColor: cgColor)
            }
            return retColor
        }
        set {
            self.view.layer.borderColor = newValue?.cgColor
        }
    }
}

// MARK: NYCRotationGestureRecognizer Definition

import UIKit.UIGestureRecognizerSubclass

private class NYCRotationGestureRecognizer: UIPanGestureRecognizer {
    var rotation: CGFloat = 0.0
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        minimumNumberOfTouches = 1
        maximumNumberOfTouches = 1
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        updateRotationWithTouches(touches as NSSet!)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        updateRotationWithTouches(touches as NSSet!)
    }
    
    func updateRotationWithTouches(_ touches: NSSet!) {
        let touch = touches.anyObject() as! UITouch
        let location = touch.location(in: self.view)
        self.rotation = rotationForLocation(location)
    }
    
    func rotationForLocation(_ location: CGPoint) -> CGFloat {
        let offset = CGPoint(x: location.x - view!.bounds.midX, y: location.y - view!.bounds.midY)
        return atan2(offset.y, offset.x)
    }
}
