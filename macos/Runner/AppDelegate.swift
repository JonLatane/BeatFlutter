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
      let url = userActivity.webpageURL/*,
      let components = URLComponents(url: url, resolvingAgainstBaseURL: true)*/ else {
        return false
    }
    BeatScratchPlugin.sharedInstance.notifyScoreUrlOpened(url.absoluteString)
    return false
  }

}
