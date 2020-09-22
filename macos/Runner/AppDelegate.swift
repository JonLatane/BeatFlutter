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
}
