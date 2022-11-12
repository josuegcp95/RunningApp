

import UIKit

extension UIView {
    func screenShot() -> UIImage? {
        let scale = UIScreen.main.scale
        let bounds = self.bounds
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, scale)
        
        if let _ = UIGraphicsGetCurrentContext() {
            self.drawHierarchy(in: bounds, afterScreenUpdates: true)
            let screenshot = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return screenshot
        }
        return nil
    }
}
