import UIKit

class AKCustomView: UIView, UIGestureRecognizerDelegate {
    // MARK: Constants
    private struct LocalConstants {
        static let AKExpandHeightAnimation = "expandHeight"
        static let AKCollapseHeightAnimation = "collapseHeight"
    }
    
    // MARK: Flags
    var inhibitTapGesture: Bool = true
    
    // MARK: Operations (Closures)
    let defaultOperationsWhenGesture: (AKCustomView, AKCustomViewController?, UIGestureRecognizer?) -> Void = { (overlay, controller, gesture) -> Void in
        controller?.view.endEditing(true)
        overlay.collapse(
            controller: controller,
            animate: true,
            completionTask: nil
        )
    }
    var additionalOperationsWhenTaped: (AKCustomView, AKCustomViewController?, UIGestureRecognizer?) -> Void = { (overlay, controller, gesture) -> Void in }
    
    // MARK: Properties
    private let expandHeight = CABasicAnimation(keyPath: LocalConstants.AKExpandHeightAnimation)
    private let collapseHeight = CABasicAnimation(keyPath: LocalConstants.AKCollapseHeightAnimation)
    private var customView: UIView = UIView()
    var tapGesture: UITapGestureRecognizer?
    var controller: AKCustomViewController?
    
    // MARK: UIView Overriding
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if let nib = Bundle.main.loadNibNamed("\(type(of: self))", owner: self, options: nil)?.first as? UIView {
            self.customView = nib
            self.customView.isUserInteractionEnabled = true
            self.addSubview(self.customView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if let nib = Bundle.main.loadNibNamed("\(type(of: self))", owner: self, options: nil)?.first as? UIView {
            self.customView = nib
            self.customView.isUserInteractionEnabled = true
            self.addSubview(self.customView)
        }
    }
    
    // MARK: Miscellaneous
    func setup() {
        // Manage gestures.
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(AKCustomView.tap(_:)))
        self.tapGesture?.delegate = self
        self.getView().addGestureRecognizer(self.tapGesture!)
        
        // Drawing.
        self.getView().translatesAutoresizingMaskIntoConstraints = true
        self.getView().clipsToBounds = true
    }
    
    // MARK: UIGestureRecognizerDelegate Implementation
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer.isKind(of: UITapGestureRecognizer.self) {
            return !self.inhibitTapGesture
        }
        else {
            return false
        }
    }
    
    // MARK: Gesture Handling
    @objc internal func tap(_ gesture: UIGestureRecognizer?) {
        self.defaultOperationsWhenGesture(self, self.controller, gesture)
        self.additionalOperationsWhenTaped(self, self.controller, gesture)
    }
    
    // MARK: Accessors
    internal func getView() -> UIView { return self.customView }
    
    // MARK: Animations
    internal func addAnimations(expandCollapseHeight: CGFloat) {
        self.expandHeight.fromValue = 0.0
        self.expandHeight.toValue = expandCollapseHeight
        self.expandHeight.duration = 0.5
        self.expandHeight.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        self.expandHeight.autoreverses = false
        self.getView().layer.add(self.expandHeight, forKey: LocalConstants.AKExpandHeightAnimation)
        
        self.collapseHeight.fromValue = expandCollapseHeight
        self.collapseHeight.toValue = 0.0
        self.collapseHeight.duration = 0.5
        self.collapseHeight.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        self.collapseHeight.autoreverses = false
        self.getView().layer.add(self.collapseHeight, forKey: LocalConstants.AKCollapseHeightAnimation)
    }
    
    internal func expand(
        controller: AKCustomViewController?,
        expandHeight: CGFloat,
        animate: Bool,
        completionTask: ((_ controller: AKCustomViewController?) -> Void)?) {
        if animate {
            UIView.beginAnimations(LocalConstants.AKExpandHeightAnimation, context: nil)
            Func.AKChangeComponentHeight(component: self.getView(), newHeight: expandHeight)
            CATransaction.setCompletionBlock {
                if completionTask != nil {
                    completionTask!(controller)
                }
            }
            UIView.commitAnimations()
        }
        else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            Func.AKChangeComponentHeight(component: self.getView(), newHeight: expandHeight)
            if completionTask != nil {
                completionTask!(controller)
            }
            CATransaction.commit()
        }
    }
    
    internal func collapse(
        controller: AKCustomViewController?,
        animate: Bool,
        completionTask: ((_ controller: AKCustomViewController?) -> Void)?) {
        if animate {
            UIView.beginAnimations(LocalConstants.AKCollapseHeightAnimation, context: nil)
            Func.AKChangeComponentHeight(component: self.getView(), newHeight: 0.0)
            CATransaction.setCompletionBlock {
                if completionTask != nil {
                    completionTask!(controller)
                }
            }
            UIView.commitAnimations()
        }
        else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            Func.AKChangeComponentHeight(component: self.getView(), newHeight: 0.0)
            if completionTask != nil {
                completionTask!(controller)
            }
            CATransaction.commit()
        }
    }
}
