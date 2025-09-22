import Cocoa

extension NSApplication {
  static func show(ignoringOtherApps: Bool = true) {
    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: ignoringOtherApps)
  }
  
  static func hide() {
    NSApp.setActivationPolicy(.accessory)
  }
}

class MacFreezeApp: NSObject, NSApplicationDelegate {
  // Static reference for signal handlers
  static var shared: MacFreezeApp?
  
  // Global state
  var isEnabled = true
  var statusItem: NSStatusItem?
  var delays = [String: TimeInterval]()
  var pendingTimers = [pid_t: DispatchWorkItem]()
  
  override init() {
    super.init()
    MacFreezeApp.shared = self
    loadConfiguration()
    setupStatusBar()
    setupNotifications()
    setupSignalHandlers()
  }
  
  // Load JSON blacklist → [pattern: delaySeconds]
  func loadConfiguration() {
    print("Loading configuration...")
    let url = FileManager.default.homeDirectoryForCurrentUser
                                            .appendingPathComponent(".macfreeze_blacklist.json")
    print("Config file path: \(url)")
    
    // Check if this is first launch (config file doesn't exist)
    if !FileManager.default.fileExists(atPath: url.path) {
      print("First launch detected - copying default blacklist...")
      copyDefaultBlacklist(to: url)
    }
    
    do {
      let data = try Data(contentsOf: url)
      print("Config file found, size: \(data.count) bytes")
      let raw = try JSONSerialization.jsonObject(with: data) as! [String: Any]
      let list = raw["blacklist"] as! [[String: Any]]
      
      print("Found \(list.count) blacklist entries")
      
      for e in list {
        let pattern = e["pattern"] as! String
        let delay = (e["delay"] as? TimeInterval) ?? 30
        
        delays[pattern] = delay
        print("Added glob pattern: \(pattern) with delay: \(delay)")
      }
      print("Configuration loaded successfully")
    } catch {
      print("Failed to load configuration: \(error)")
    }
  }
  
  // Copy default blacklist file to user's home directory
  private func copyDefaultBlacklist(to destinationURL: URL) {
    // Look for the default blacklist file in the app bundle
    guard let defaultBlacklistPath = Bundle.main.path(forResource: ".macfreeze_blacklist", ofType: "json") else {
      print("ERROR: Default blacklist file not found in app bundle!")
      return
    }
    
    let sourceURL = URL(fileURLWithPath: defaultBlacklistPath)
    
    do {
      try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
      print("Default blacklist copied to: \(destinationURL.path)")
    } catch {
      print("ERROR: Failed to copy default blacklist: \(error)")
    }
  }
  
  // Function to unfreeze all processes
  func unfreezeAllProcesses() {
    for (pid, timer) in pendingTimers {
      timer.cancel()
      kill(pid, SIGCONT)
    }
    pendingTimers.removeAll()
  }
  
  // Function to create status bar menu
  func createStatusBarMenu() -> NSMenu {
    let menu = NSMenu()
    
    // Enable/Disable item
    let toggleItem = NSMenuItem(title: isEnabled ? "Disable Freezing" : "Enable Freezing", 
                               action: #selector(toggleFreezing), 
                               keyEquivalent: "")
    toggleItem.target = self
    menu.addItem(toggleItem)
    
    menu.addItem(NSMenuItem.separator())
    
    // Unfreeze All item
    let unfreezeItem = NSMenuItem(title: "Unfreeze All Processes", 
                                 action: #selector(unfreezeAll), 
                                 keyEquivalent: "")
    unfreezeItem.target = self
    menu.addItem(unfreezeItem)
    
    menu.addItem(NSMenuItem.separator())

    // Settings item
    let settingsItem = NSMenuItem(title: "Settings", 
                                 action: #selector(openSettings), 
                                 keyEquivalent: "s")
    settingsItem.target = self
    menu.addItem(settingsItem)
    
    menu.addItem(NSMenuItem.separator())
    
    // Quit item
    let quitItem = NSMenuItem(title: "Quit", 
                             action: #selector(NSApplication.terminate(_:)), 
                             keyEquivalent: "q")
    menu.addItem(quitItem)
    
    return menu
  }
  
  // Toggle freezing functionality
  @objc func toggleFreezing() {
    isEnabled = !isEnabled
    
    if !isEnabled {
      // Unfreeze all processes when disabling
      unfreezeAllProcesses()
    }
    
    // Update status bar
    updateStatusBar()
  }
  
  // Unfreeze all processes
  @objc func unfreezeAll() {
    unfreezeAllProcesses()
  }
  
  // Open preferences window
  @objc func openSettings() {
    print("Opening preferences...")
    
    if PreferencesWindow.shared == nil {
      PreferencesWindow.shared = PreferencesWindow()
    }
    
    PreferencesWindow.shared?.showWindow(nil)
  }
  
  // Update status bar appearance
  func updateStatusBar() {
    if let statusItem = statusItem {
      // Use custom icons from icons/ directory (status bar sized)
      let enabledPath = Bundle.main.path(forResource: "freezer_enabled_statusbar", ofType: "png", inDirectory: "icons") ?? 
                       FileManager.default.currentDirectoryPath + "/icons/freezer_enabled_statusbar.png"
      let disabledPath = Bundle.main.path(forResource: "freezer_disabled_statusbar", ofType: "png", inDirectory: "icons") ?? 
                        FileManager.default.currentDirectoryPath + "/icons/freezer_disabled_statusbar.png"
      
      if let enabledImage = NSImage(contentsOfFile: enabledPath),
         let disabledImage = NSImage(contentsOfFile: disabledPath) {
        statusItem.button?.image = isEnabled ? enabledImage : disabledImage
        statusItem.button?.title = ""
      }
      statusItem.menu = createStatusBarMenu()
    }
  }
  
  // Setup status bar
  func setupStatusBar() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    // Use custom icon from icons/ directory (status bar sized)
    let enabledPath = Bundle.main.path(forResource: "freezer_enabled_statusbar", ofType: "png", inDirectory: "icons") ?? 
                     FileManager.default.currentDirectoryPath + "/icons/freezer_enabled_statusbar.png"
    if let enabledImage = NSImage(contentsOfFile: enabledPath) {
      statusItem?.button?.image = enabledImage
      statusItem?.button?.title = ""
    }
    statusItem?.menu = createStatusBarMenu()
  }
  
  // Setup signal handlers for graceful shutdown
  func setupSignalHandlers() {
    signal(SIGINT) { _ in
      print("Received SIGINT, unfreezing all processes...")
      MacFreezeApp.shared?.cleanup()
      exit(0)
    }
    
    signal(SIGTERM) { _ in
      print("Received SIGTERM, unfreezing all processes...")
      MacFreezeApp.shared?.cleanup()
      exit(0)
    }
    

  }
  
  // Cleanup function to unfreeze all processes
  func cleanup() {
    print("Cleaning up - unfreezing all processes...")
    unfreezeAllProcesses()
  }
  
  // Check if app name matches glob pattern
  private func matchesGlobPattern(_ appName: String, pattern: String) -> Bool {
    // Simple glob pattern matching
    let regexPattern = pattern.replacingOccurrences(of: ".", with: "\\.")
                           .replacingOccurrences(of: "*", with: ".*")
    
    do {
      let regex = try NSRegularExpression(pattern: regexPattern, options: .caseInsensitive)
      let range = NSRange(location: 0, length: appName.utf16.count)
      return regex.firstMatch(in: appName, options: [], range: range) != nil
    } catch {
      print("Invalid regex pattern: \(pattern)")
      return false
    }
  }
  
  // NSApplicationDelegate method for graceful termination
  func applicationWillTerminate(_ notification: Notification) {
    print("Application will terminate, unfreezing all processes...")
    cleanup()
  }
  
  // Prevent app from terminating when no windows are visible
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }
  
  // Setup notifications
  func setupNotifications() {
    let nc = NSWorkspace.shared.notificationCenter
    
    nc.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
                   object: nil, queue: .main) { [weak self] note in
      guard let self = self,
            let info = note.userInfo,
            let app = info[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
      
      let pid = app.processIdentifier

      // Cancel any pending freeze for this PID
      self.pendingTimers[pid]?.cancel()
      self.pendingTimers.removeValue(forKey: pid)

      // Unfreeze immediately
      kill(pid, SIGCONT)
    }
    
    nc.addObserver(forName: NSWorkspace.didDeactivateApplicationNotification,
                   object: nil, queue: .main) { [weak self] note in
      guard let self = self,
            let info = note.userInfo,
            let app = info[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }

      // Only freeze if enabled
      guard self.isEnabled else { return }

      let pid = app.processIdentifier
      let appName = app.localizedName ?? ""

      // Check if any glob pattern matches the app name
      var matchingDelay: TimeInterval?
      for (pattern, delay) in self.delays {
        if self.matchesGlobPattern(appName, pattern: pattern) {
          matchingDelay = delay
          break
        }
      }

      guard let delay = matchingDelay else { return }

      // Schedule freeze after `delay`
      let work = DispatchWorkItem {
        kill(pid, SIGSTOP)
        self.pendingTimers.removeValue(forKey: pid)
      }
      self.pendingTimers[pid] = work
      DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: work)
    }
  }
}

// Initialize the application
NSApplication.shared.setActivationPolicy(.accessory)

// Create and run the application
let app = MacFreezeApp()
NSApplication.shared.delegate = app
NSApplication.shared.run()
