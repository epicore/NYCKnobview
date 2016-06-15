//
//  NYCKnobView.swift
//  NYCKnobViewDemo
//
//  Created by Joshua Weinberg on 6/13/16.
//  Copyright © 2016 3rd Street Apps. All rights reserved.
//

import UIKit

// MARK: Delegate Definition

@objc protocol NYCKnobViewDelegate: class {
    
    // knobValue changed occurs continously while gesture is in progress
    optional func knobValueChanged(sender: NYCKnobView)
    
    // knobValue updated occurs after gesture is complete
    func knobValueUpdateComplete(sender: NYCKnobView)
    
}

// Enum for type of data to be handled by the knob
enum NYCKnobFormatType: Int {
    case Decimal = 0
    case Integer
    case Percentage
}

// MARK: Class Definition

@IBDesignable class NYCKnobView: UIView{
    
    // MARK: Outlets
    
    @IBOutlet weak var knobBg: UIImageView!
    @IBOutlet weak var knobPointer: UIImageView!
    @IBOutlet weak var valueLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var minValueLbl: UILabel!
    @IBOutlet weak var maxValueLbl: UILabel!
    
    // MARK: Private Ivars
    
    private var _minValue: CGFloat = 0.0
    private var _maxValue: CGFloat = 1.0
    private var _value: CGFloat = 0.0
    private var _gestureRecognizer:NYCRotationGestureRecognizer?
    private var _valueRange:CGFloat { return CGFloat(_maxValue - _minValue)}
    private var _pointerAngle: CGFloat = -CGFloat(M_PI * 1.328)
    private var _startAngle: CGFloat = -CGFloat(M_PI * 1.328)
    private var _endAngle: CGFloat = CGFloat(M_PI * 0.328)
    
    // MARK: Public Ivars
    
    weak var delegate:NYCKnobViewDelegate?
    var imageTint:UIColor?
    {
        didSet{
            self.knobBg.tintColor = imageTint
            self.knobPointer.tintColor = imageTint
        }
    }
    var knobFormatType = NYCKnobFormatType.Decimal
    var view:UIView! // holder for view elements loaded from the nib
    var startAngle: CGFloat{
        get{
            return _startAngle
        }
        set{
            _startAngle = newValue
        }
    }
    var endAngle : CGFloat{
        get{
            return _endAngle
        }
        set{
            _endAngle = newValue
        }
    }
    var debugString:String{
        get{
            return "rotation : \(NSString(format: "%.3f", _gestureRecognizer!.rotation)), pointerAngle: \(NSString(format: "%.3f", _pointerAngle)) & value: \(NSString(format: "%.3f", _value))"
        }
    }
    var value: Float {
        get {
            if self.knobFormatType == .Integer{
                return round(Float(_value))
            } else {
                return Float(_value)
            }
        }
        set {
            if self.knobFormatType == .Integer{
                setValue(CGFloat(round(newValue)), animated: true)
            } else {
                setValue(CGFloat(newValue), animated: true)
            }
            self.valueLbl.text = self.convertFloatToString(_value)
        }
    }
    
    var pointerAngle: CGFloat {
        get {
            return _pointerAngle
        }
        set {
            self.setPointerAngle(newValue, animated: false)
        }
    }
    
    var minValue: CGFloat{
        get{
            return _minValue
        }
        set(newValue){
            // guard against insane values
            if newValue >= 0 && newValue < _maxValue {
                _minValue = newValue
                self.minValueLbl.text = self.convertFloatToString(_minValue)
            }
        }
    }
    
    var maxValue: CGFloat{
        get{
            return _maxValue
        }
        set(newValue){
            // guard against insane values
            if newValue > _minValue {
                _maxValue = newValue
                self.maxValueLbl.text = self.convertFloatToString(_maxValue)
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
    
    private func initKnob(){
        self.setupNib()
        self.configGestureRecognizer()
    }
    
    private func configGestureRecognizer(){
        _gestureRecognizer = NYCRotationGestureRecognizer(target: self, action: #selector(NYCKnobView.handleRotation(_:)))
        self.addGestureRecognizer(_gestureRecognizer!)
    }
    
    private func setupNib() {
        self.view = loadViewFromNib()
        self.view.frame = bounds
        self.view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        addSubview(self.view)
    }
    
    private func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: String(self.dynamicType), bundle: bundle)
        let retview = nib.instantiateWithOwner(self, options: nil).first as! UIView
        return retview
    }
    
    // MARK: Private Helper Methods
    
    private func convertFloatToString(val:CGFloat) -> String{
        
        var retString = NSString()
        
        switch(self.knobFormatType){
        case .Decimal:
            retString = NSString(format: "%.1f", val)
            // get rid of the decimal for max, min, and when its less than 2 decimal places difference
            if(val <= self.minValue || val >= self.maxValue || round(100*val)/100 == floor(val)){
                retString = NSString(format: "%.0f", val)
            }
        case .Integer:
            retString = NSString(format: "%.0f", val)
        case .Percentage:
            retString = NSString(format: "%.0f%%", val*100)
            if(val <= self.minValue || val >= self.maxValue){
                retString = NSString(format: "%.0f", val*100)
            }
        }
        
        return retString as String
    }
    
    // MARK: Public Helper Methods
    
    func resetKnob(){
        self.setValue(_value, animated:true)
    }
    
    func setPointerAngle(pointerAngle: CGFloat, animated: Bool) {
        self.movePointerToAngle(pointerAngle, animated: animated)
        _pointerAngle = pointerAngle
    }
    
    func setValue(value: CGFloat, animated: Bool) {
        if(value != _value) {
            
            // limit the backing value to the requested bounds
            _value = min(_maxValue, max(_minValue, value))
            
            // update the knob with the correct angle
            let angleRange = _endAngle - _startAngle
            let angle = (value - _minValue) / _valueRange * angleRange + _startAngle
            self.setPointerAngle(angle, animated: animated)
        }
    }
    
    func movePointerToAngle(pointerAngle: CGFloat, animated: Bool) {
        if animated {
            UIView.animateWithDuration(0.25
                , delay: 0
                , options: [.CurveEaseOut, .BeginFromCurrentState]
                , animations:{
                    self.knobPointer?.transform = CGAffineTransformMakeRotation(pointerAngle)
                }, completion: nil)
            
        } else {
            self.knobPointer?.transform = CGAffineTransformMakeRotation(pointerAngle)
        }
    }
    
    // MARK: Handler Method(s)
    
    func handleRotation(sender: AnyObject) {
        let gr = sender as! NYCRotationGestureRecognizer
        
        // 1. Mid-point angle
        let midPointAngle = (2.0 * CGFloat(M_PI) + _startAngle - _endAngle) / 2.0 + _endAngle
        
        // 2. Ensure the angle is within a suitable range
        var boundedAngle = gr.rotation
        if boundedAngle > midPointAngle {
            boundedAngle -= 2.0 * CGFloat(M_PI)
        } else if boundedAngle < (midPointAngle - 2.0 * CGFloat(M_PI)) {
            boundedAngle += 2 * CGFloat(M_PI)
        }
        
        // 3. Bound the angle to within the suitable range
        boundedAngle = min(_endAngle, max(_startAngle, boundedAngle))
        
        // 4. Convert the angle to a value
        let angleRange = _endAngle - _startAngle
        let valueForAngle = (boundedAngle - _startAngle) / angleRange * _valueRange + _minValue
        
        // 5. Set the control to this value
        self.setValue(valueForAngle, animated:false)
        self.valueLbl.text = self.convertFloatToString(valueForAngle)
        
        print("rotation : \(gr.rotation), boundedAngle : \(boundedAngle) & valueForAngle: \(valueForAngle)")
        
        if(gr.state == UIGestureRecognizerState.Ended){
            self.delegate?.knobValueUpdateComplete(self)
        } else {
            self.delegate?.knobValueChanged?(self)
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
    
    @IBInspectable var startingAngle: Float {
        get{
            return Float(self.startAngle)
        }
        set(newValue){
            if CGFloat(newValue) < self.endAngle {
                self.startAngle = CGFloat(newValue)
            }
        }
    }
    
    @IBInspectable var endingAngle: Float {
        get{
            return Float(self.endAngle)
        }
        set(newValue){
            if CGFloat(newValue) > self.startAngle {
                self.endAngle = CGFloat(newValue)
            }
        }
    }

    @IBInspectable var minimumValue: Float {
        get{
            return Float(self.minValue)
        }
        set(newValue){
            if CGFloat(newValue) < self.maxValue {
                self.minValue = CGFloat(newValue)
            }
        }
    }
    
    @IBInspectable var maximumValue: Float {
        get{
            return Float(self.maxValue)
        }
        set(newValue){
            if CGFloat(newValue) > self.minValue {
                self.maxValue = CGFloat(newValue)
            }
        }
    }
    
    @IBInspectable var knobFormat:Int {
        get {
            return self.knobFormatType.rawValue
        }
        set( newFormatType) {
            self.knobFormatType = NYCKnobFormatType(rawValue:newFormatType) ?? NYCKnobFormatType.Decimal
        }
    }
    
    @IBInspectable var knobBgImage: UIImage? {
        get {
            return self.knobBg?.image
        }
        set(img){
            self.knobBg?.image = img?.imageWithRenderingMode(.AlwaysTemplate)
        }
    }
    
    @IBInspectable var knobPointerImage: UIImage? {
        get {
            return self.knobPointer?.image
        }
        set(img){
            self.knobPointer?.image = img?.imageWithRenderingMode(.AlwaysTemplate)
        }
    }
    
    @IBInspectable var title: String? {
        get{
            return self.titleLbl.text
        }
        set(newText){
            self.titleLbl.text = newText
        }
    }
    
    @IBInspectable var textColor: UIColor? {
        get{
            return self.valueLbl.textColor
        }
        set(newColorOpt) {
            if let newColor = newColorOpt{
                self.valueLbl.textColor = newColor
                self.titleLbl.textColor = newColor
                self.minValueLbl.textColor = newColor
                self.maxValueLbl.textColor = newColor
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
                retColor = UIColor(CGColor: cgColor)
            }
            return retColor
        }
        set(newColor){
            self.view.layer.borderColor = newColor?.CGColor
        }
    }
}

// MARK: NYCRotationGestureRecognizer Definition

import UIKit.UIGestureRecognizerSubclass

private class NYCRotationGestureRecognizer: UIPanGestureRecognizer {
    var rotation: CGFloat = 0.0
    
    override init(target: AnyObject?, action: Selector) {
        super.init(target: target, action: action)
        minimumNumberOfTouches = 1
        maximumNumberOfTouches = 1
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        updateRotationWithTouches(touches)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        updateRotationWithTouches(touches)
    }
    
    func updateRotationWithTouches(touches: NSSet!) {
        let touch = touches.anyObject() as! UITouch
        let location = touch.locationInView(self.view)
        self.rotation = rotationForLocation(location)
    }
    
    func rotationForLocation(location: CGPoint) -> CGFloat {
        let offset = CGPoint(x: location.x - view!.bounds.midX, y: location.y - view!.bounds.midY)
        return atan2(offset.y, offset.x)
    }
}
