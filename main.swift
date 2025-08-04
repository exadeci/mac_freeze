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
  
  // Load JSON blacklist → [bundleID: delaySeconds]
  func loadConfiguration() {
    print("Loading configuration...")
    let url = FileManager.default.homeDirectoryForCurrentUser
                   .appendingPathComponent("blacklist.json")
    print("Config file path: \(url)")
    
    do {
      let data = try Data(contentsOf: url)
      print("Config file found, size: \(data.count) bytes")
      let raw = try JSONSerialization.jsonObject(with: data) as! [String: Any]
      let list = raw["blacklist"] as! [[String: Any]]
      
      print("Found \(list.count) blacklist entries")
      
      for e in list {
        let type = e["type"] as! String
        let delay = (e["delay"] as? TimeInterval) ?? 30
        
        if type == "bundleID" {
          let id = e["identifier"] as! String
          delays[id] = delay
          print("Added bundleID: \(id) with delay: \(delay)")
        } else if type == "glob" {
          let pattern = e["pattern"] as! String
          delays[pattern] = delay
          print("Added glob pattern: \(pattern) with delay: \(delay)")
        }
      }
      print("Configuration loaded successfully")
    } catch {
      print("Failed to load configuration: \(error)")
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
    
    // Settings item
    let settingsItem = NSMenuItem(title: "Settings", 
                                 action: #selector(openSettings), 
                                 keyEquivalent: "s")
    settingsItem.target = self
    menu.addItem(settingsItem)
    
    menu.addItem(NSMenuItem.separator())
    
    // Unfreeze All item
    let unfreezeItem = NSMenuItem(title: "Unfreeze All Processes", 
                                 action: #selector(unfreezeAll), 
                                 keyEquivalent: "")
    unfreezeItem.target = self
    menu.addItem(unfreezeItem)
    
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
  
  // Open settings window
  @objc func openSettings() {
    print("Opening settings...")
    
    // Try to find SettingsApp in the app bundle first
    var settingsAppPath = Bundle.main.path(forResource: "SettingsApp", ofType: nil)
    print("SettingsApp path from bundle: \(settingsAppPath ?? "nil")")
    
    if settingsAppPath == nil {
      // Try the MacOS directory in the app bundle
      settingsAppPath = Bundle.main.bundlePath + "/Contents/MacOS/SettingsApp"
      print("SettingsApp path from MacOS directory: \(settingsAppPath ?? "nil")")
    }
    
    if settingsAppPath == nil {
      // Fallback to current directory
      settingsAppPath = FileManager.default.currentDirectoryPath + "/SettingsApp"
      print("SettingsApp path from current directory: \(settingsAppPath ?? "nil")")
    }
    
    if let path = settingsAppPath {
      let task = Process()
      task.launchPath = path
      
      // Add error handling
      let pipe = Pipe()
      task.standardError = pipe
      
      do {
        print("Launching SettingsApp at: \(path)")
        try task.run()
        print("SettingsApp launched successfully")
      } catch {
        print("Error launching SettingsApp: \(error)")
        
        // Try to read error output
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let errorOutput = String(data: data, encoding: .utf8) {
          print("SettingsApp error output: \(errorOutput)")
        }
      }
    } else {
      print("Could not find SettingsApp executable")
    }
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
    
    signal(SIGUSR1) { _ in
      print("Received SIGUSR1, reloading configuration...")
      MacFreezeApp.shared?.loadConfiguration()
    }
  }
  
  // Cleanup function to unfreeze all processes
  func cleanup() {
    print("Cleaning up - unfreezing all processes...")
    unfreezeAllProcesses()
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
            let app = info[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            let bid = app.bundleIdentifier,
            let delay = self.delays[bid] else { return }

      // Only freeze if enabled
      guard self.isEnabled else { return }

      let pid = app.processIdentifier

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
