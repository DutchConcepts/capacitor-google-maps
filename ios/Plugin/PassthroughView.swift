//
//  PassthroughView.swift
//  CapacitorCommunityCapacitorGooglemapsNative
//
//  Created by Jameson Parker on 1/11/22.
//

import Capacitor

class PassThroughView: UIView {
    
    var innerElements:Array<CGRect> = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setInnerElements(elements:JSArray){
        
        self.innerElements = []
        elements.forEach { element in
            if let jsonResult = element as? Dictionary<String, AnyObject> {
                let x = jsonResult["x"] as? Double ?? 0;
                let y = jsonResult["y"] as? Double ?? 0;
                let width = jsonResult["width"] as? Double ?? 0;
                let height = jsonResult["height"] as? Double ?? 0;
                
                let point = CGPoint(x: x, y: y);
                let size = CGSize(width: width, height: height);
                
                self.innerElements.insert(CGRect(origin: point, size: size), at: 0)
            }
        }
    }
        
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for subview in subviews as [UIView] {
            if subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event){
                let type = NSStringFromClass(type(of:subview))
                
                for rect in self.innerElements {
                    if rect.contains(point){
                        return super.hitTest(point, with: event)
                    }
                }
                
                if(type == "GMSMapView"){
                    return subview.subviews.first
                }
            }
        }
        return super.hitTest(point, with: event)
      
    }

  
}
