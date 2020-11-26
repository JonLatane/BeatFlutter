import Cocoa
import FlutterMacOS
//import Firebase

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  
  override init() {
    super.init()
//    FirebaseApp.configure()
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
  
  override func application(_ application: NSApplication,
                   continue userActivity: NSUserActivity,
                   restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void) -> Bool
  {
    // Get URL components from the incoming user activity.
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let incomingURL = userActivity.webpageURL,
          let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
      return false
    }
    
    return true
    
//    // Check for specific URL components that you need.
//    guard let path = components.path,
//          let params = components.queryItems else {
//      return false
//    }
//    print("path = \(path)")
//    
//    if let albumName = params.first(where: { $0.name == "albumname" } )?.value,
//       let photoIndex = params.first(where: { $0.name == "index" })?.value {
//      print("album = \(albumName)")
//      print("photoIndex = \(photoIndex)")
//      return true
//      
//    } else {
//      print("Either album name or photo index missing")
//      return false
//    }
  }

}
