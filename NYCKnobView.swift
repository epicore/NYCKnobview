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

fileprivate let _startAngle = CGFloat(M_PI * -1.328)
fileprivate let _endAngle = CGFloat(M_PI * 0.328)

// MARK: Class Definition

@IBDesignable class NYCKnobView: UIControl{
    
    // MARK: Outlets
    
    @IBOutlet weak var knobBg: UIImageView!
    @IBOutlet weak var knobPointer: UIImageView!
    @IBOutlet weak var valueLbl: UILabel!
    
    // MARK: Private Ivars
    
    fileprivate var _value = 0.0 as CGFloat
    fileprivate var _gestureRecognizer: NYCRotationGestureRecognizer?
    fileprivate var _valueRange: CGFloat {
        return self.maximumValue - self.minimumValue
    }
    
    // MARK: Public Ivars
    
    var continuous = true
    var imageTint: UIColor?
    {
        didSet{
            self.knobBg.image = self.knobBg.image?.withRenderingMode(.alwaysTemplate)
            self.knobPointer.image = self.knobPointer.image?.withRenderingMode(.alwaysTemplate)
            self.knobBg.tintColor = imageTint
            self.knobPointer.tintColor = imageTint
        }
    }
    var knobFormatType: NYCKnobFormatType = NYCKnobFormatType.decimal
    var view: UIView! // holder for view elements loaded from the nib
    var debugString: String{
        get{
            return "rotation : \(NSString(format: "%.3f", _gestureRecognizer!.rotation)), pointerAngle: \(NSString(format: "%.3f", self.pointerAngle)) & value: \(NSString(format: "%.3f", _value))"
        }
    }
    var value: Float {
        get {
            if self.knobFormatType == .integer{
                return round(Float(_value))
            } else {
                return Float(_value)
            }
        }
        set {
            if self.knobFormatType == .integer{
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
    
    override var isEnabled: Bool{
        didSet{
            if(isEnabled){
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
    
    fileprivate func initKnob(){
        self.setupNib()
        self.configGestureRecognizer()
        // set knob angle to start value position
        self.setKnobAngleFor(CGFloat(self.value), animated:false)
    }
    
    fileprivate func configGestureRecognizer(){
        _gestureRecognizer = NYCRotationGestureRecognizer(target: self, action: #selector(NYCKnobView.handleRotation(_:)))
        self.addGestureRecognizer(_gestureRecognizer!)
    }
    
    fileprivate func setupNib() {
        self.view = loadViewFromNib()
        self.view.frame = bounds
        self.view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        addSubview(self.view)
    }
    
    fileprivate func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let retview = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return retview
    }
    
    // MARK: Private Helper Methods
    
    fileprivate func convertFloatToString(_ val:CGFloat) -> String{
        
        var retString = NSString()
        
        switch(self.knobFormatType){
        case .decimal:
            retString = NSString(format: "%.1f", val)
            
            // get rid of the decimal for max, min, and when its less than 2 decimal places difference
            if(val <= self.minimumValue || val >= self.maximumValue || round(100*val)/100 == floor(val)){
                retString = NSString(format: "%.0f", val)
            }
            
        case .integer:
            
            retString = NSString(format: "%.0f", val)
        
        case .percentage:
        
            retString = NSString(format: "%.0f%%", val*100)
            if(val <= self.minimumValue || val >= self.maximumValue){
                retString = NSString(format: "%.0f", val*100)
            }
        }
        
        return retString as String
    }
    
    // MARK: Public Helper Methods
    
    func resetKnob(){
        self.setValue(_value, animated:true)
    }
    
    func setPointerAngle(_ pointerAngle: CGFloat, animated: Bool) {
        self.movePointerToAngle(pointerAngle, animated: animated)
    }
    
    func setValue(_ value: CGFloat, animated: Bool) {
        // limit the backing value to the requested bounds
        _value = min(self.maximumValue, max(self.minimumValue, value))
        self.setKnobAngleFor(value, animated: animated)
    }
    
    // private helper
    func setKnobAngleFor(_ value: CGFloat, animated: Bool){
        // update the knob with the correct angle
        let angleRange = self.endAngle - self.startAngle
        let angle = (value - self.minimumValue) / _valueRange * angleRange + self.startAngle
        self.setPointerAngle(angle, animated: animated)
    }
    
    func movePointerToAngle(_ pointerAngle: CGFloat, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25
                , delay: 0
                , options: [.curveEaseOut, .beginFromCurrentState]
                , animations:{
                    self.knobPointer?.transform = CGAffineTransform(rotationAngle: pointerAngle)
                }, completion: nil)
            
        } else {
            self.knobPointer?.transform = CGAffineTransform(rotationAngle: pointerAngle)
        }
    }
    
    // MARK: Handler Method(s)
    
    func handleRotation(_ sender: AnyObject) {
        let gr = sender as! NYCRotationGestureRecognizer
        
        // 1. Mid-point angle
        let midPointAngle = (2.0 * CGFloat(M_PI) + self.startAngle - self.endAngle) / 2.0 + self.endAngle
        
        // 2. Ensure the angle is within a suitable range
        var boundedAngle = gr.rotation
        if boundedAngle > midPointAngle {
            boundedAngle -= 2.0 * CGFloat(M_PI)
        } else if boundedAngle < (midPointAngle - 2.0 * CGFloat(M_PI)) {
            boundedAngle += 2 * CGFloat(M_PI)
        }
        
        // 3. Bound the angle to within the suitable range
        boundedAngle = min(self.endAngle, max(self.startAngle, boundedAngle))
        
        // 4. Convert the angle to a value
        let angleRange = self.endAngle - self.startAngle
        let valueForAngle = (boundedAngle - self.startAngle) / angleRange * _valueRange + self.minimumValue
        
        // 5. Set the control to this value
        self.setValue(valueForAngle, animated:false)
        self.valueLbl.text = self.convertFloatToString(valueForAngle)
        
        // Notify of value change
        if continuous {
            sendActions(for: .valueChanged)
        } else {
            // Only send an update if the gesture has completed
            if (gr.state == UIGestureRecognizerState.ended) || (gr.state == UIGestureRecognizerState.cancelled) {
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
        set(newValue){
            self.setValue(CGFloat(newValue), animated:false)
        }
    }
    
    @IBInspectable var knobFormat: Int {
        get {
            return self.knobFormatType.rawValue
        }
        set( newFormatType) {
            self.knobFormatType = NYCKnobFormatType(rawValue:newFormatType) ?? NYCKnobFormatType.decimal
        }
    }
    
    @IBInspectable var knobBgImage: UIImage? {
        get {
            return self.knobBg?.image
        }
        set(img){
            self.knobBg?.image = img?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    @IBInspectable var knobPointerImage: UIImage? {
        get {
            return self.knobPointer?.image
        }
        set(img){
            self.knobPointer?.image = img?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    @IBInspectable var textColor: UIColor? {
        get{
            return self.valueLbl.textColor
        }
        set(newColorOpt) {
            if let newColor = newColorOpt{
                self.valueLbl.textColor = newColor
            }
        }
    }
    
    @IBInspectable var knobTint: UIColor? {
        get{
            return self.imageTint
        }
        set(newColorOpt) {
            if let newColor = newColorOpt{
                self.imageTint = newColor
            }
        }
    }
    
    @IBInspectable var knobBgColor: UIColor? {
        get{
            return self.view.backgroundColor
        }
        set(newColorOpt) {
            if let newColor = newColorOpt{
                self.view.backgroundColor = newColor
            }
        }
    }
    
    @IBInspectable var knobCornerRadius: CGFloat {
        get{
            return self.view.layer.cornerRadius
        }
        set(newRadius){
            self.view.layer.cornerRadius = newRadius
            self.view.layer.masksToBounds = newRadius > 0
        }
    }
    
    @IBInspectable var knobBorderWidth: CGFloat {
        get{
            return self.view.layer.borderWidth
        }
        set(newWidth){
            self.view.layer.borderWidth = newWidth
        }
    }
    
    @IBInspectable var knobBorderColor: UIColor? {
        get{
            var retColor:UIColor?
            if let cgColor = self.view.layer.borderColor{
                retColor = UIColor(cgColor: cgColor)
            }
            return retColor
        }
        set(newColor){
            self.view.layer.borderColor = newColor?.cgColor
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
