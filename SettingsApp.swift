import Cocoa

class SettingsApp: NSObject, NSApplicationDelegate {
  var settingsWindow: SettingsWindow?
  
  override init() {
    super.init()
  }
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    settingsWindow = SettingsWindow()
    settingsWindow?.showWindow(nil)
  }
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}

class SettingsWindow: NSWindow {
  init() {
    super.init(contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
               styleMask: [.titled, .closable, .miniaturizable],
               backing: .buffered,
               defer: false)
    
    self.title = "Mac Freeze Settings"
    self.center()
    self.delegate = self
    
    let settingsView = SettingsView()
    self.contentView = settingsView
  }
  
  func showWindow(_ sender: Any?) {
    self.makeKeyAndOrderFront(sender)
  }
}

extension SettingsWindow: NSWindowDelegate {
  func windowWillClose(_ notification: Notification) {
    // Notify the main app to reload configuration
    notifyMainAppToReload()
  }
  
  private func notifyMainAppToReload() {
    // Send a signal to the main app process
    let mainAppPID = getMainAppPID()
    if mainAppPID > 0 {
      kill(mainAppPID, SIGUSR1)
    }
  }
  
  private func getMainAppPID() -> pid_t {
    // Look for the main MacFreeze app process
    let task = Process()
    task.launchPath = "/bin/ps"
    task.arguments = ["-ax", "-o", "pid,command"]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    
    do {
      try task.run()
      task.waitUntilExit()
      
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: data, encoding: .utf8) ?? ""
      
      for line in output.components(separatedBy: .newlines) {
        if line.contains("mac_freeze") && !line.contains("SettingsApp") {
          let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: " ")
          if let pidString = components.first, let pid = Int32(pidString) {
            return pid
          }
        }
      }
    } catch {
      print("Error finding main app PID: \(error)")
    }
    
    return -1
  }
}

class SettingsView: NSView {
  private var appEntries: [AppEntryView] = []
  private var scrollView: NSScrollView!
  private var stackView: NSStackView!
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }
  
  private func setupUI() {
    // Buttons at top
    let buttonStack = NSStackView()
    buttonStack.orientation = .horizontal
    buttonStack.spacing = 10
    buttonStack.translatesAutoresizingMaskIntoConstraints = false
    
    let addButton = NSButton(title: "Add App", target: self, action: #selector(addApp))
    let saveButton = NSButton(title: "Save", target: self, action: #selector(saveSettings))
    let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
    
    buttonStack.addArrangedSubview(addButton)
    buttonStack.addArrangedSubview(saveButton)
    buttonStack.addArrangedSubview(cancelButton)
    
    addSubview(buttonStack)
    
    // Scroll view for apps
    scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.autohidesScrollers = true
    scrollView.borderType = .bezelBorder
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    
    // Stack view for app entries
    stackView = NSStackView()
    stackView.orientation = .vertical
    stackView.spacing = 5
    stackView.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    
    loadAppEntries()
    
    scrollView.documentView = stackView
    addSubview(scrollView)
    
    // Constraints
    NSLayoutConstraint.activate([
      buttonStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
      buttonStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
      buttonStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
      buttonStack.heightAnchor.constraint(equalToConstant: 30),
      
      scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
      scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
      scrollView.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 10),
      scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
    ])
  }
  
  private func loadAppEntries() {
    let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("blacklist.json")
    if let data = try? Data(contentsOf: url),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let blacklist = json["blacklist"] as? [[String: Any]] {
      
      for entry in blacklist {
        let type = entry["type"] as? String ?? ""
        let identifier = entry["identifier"] as? String ?? entry["pattern"] as? String ?? ""
        let delay = entry["delay"] as? TimeInterval ?? 30
        
        let appEntry = AppEntryView(type: type, identifier: identifier, delay: delay)
        appEntry.onRemove = { [weak self] in
          if let index = self?.appEntries.firstIndex(of: appEntry) {
            self?.appEntries.remove(at: index)
          }
        }
        appEntries.append(appEntry)
        stackView.addArrangedSubview(appEntry)
      }
    }
  }
  
  @objc private func addApp() {
    let appEntry = AppEntryView(type: "bundleID", identifier: "", delay: 30)
    appEntry.onRemove = { [weak self] in
      if let index = self?.appEntries.firstIndex(of: appEntry) {
        self?.appEntries.remove(at: index)
      }
    }
    appEntries.insert(appEntry, at: 0)
    stackView.insertArrangedSubview(appEntry, at: 0)
  }
  
  @objc private func saveSettings() {
    var blacklist: [[String: Any]] = []
    
    for entry in appEntries {
      if !entry.appIdentifier.isEmpty {
        var dict: [String: Any] = [
          "type": entry.type,
          "delay": entry.delay
        ]
        
        if entry.type == "bundleID" {
          dict["identifier"] = entry.appIdentifier
        } else {
          dict["pattern"] = entry.appIdentifier
        }
        
        blacklist.append(dict)
      }
    }
    
    let json: [String: Any] = ["blacklist": blacklist]
    
    if let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
      let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("blacklist.json")
      try? data.write(to: url)
      self.window?.close()
    }
  }
  
  @objc private func cancel() {
    self.window?.close()
  }
}

class AppEntryView: NSView {
  var type: String
  var appIdentifier: String
  var delay: TimeInterval
  var onRemove: (() -> Void)?
  
  private var typePopUp: NSPopUpButton!
  private var identifierField: NSTextField!
  private var delayField: NSTextField!
  
  init(type: String, identifier: String, delay: TimeInterval) {
    self.type = type
    self.appIdentifier = identifier
    self.delay = delay
    super.init(frame: NSRect.zero)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    self.type = "bundleID"
    self.appIdentifier = ""
    self.delay = 30
    super.init(coder: coder)
    setupUI()
  }
  
  private func setupUI() {
    let stackView = NSStackView()
    stackView.orientation = .horizontal
    stackView.spacing = 10
    stackView.translatesAutoresizingMaskIntoConstraints = false
    
    // Type selector
    typePopUp = NSPopUpButton()
    typePopUp.addItem(withTitle: "Bundle ID")
    typePopUp.addItem(withTitle: "Glob Pattern")
    typePopUp.selectItem(withTitle: type == "bundleID" ? "Bundle ID" : "Glob Pattern")
    typePopUp.target = self
    typePopUp.action = #selector(typeChanged)
    typePopUp.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    
    // Identifier field
    identifierField = NSTextField()
    identifierField.stringValue = appIdentifier
    identifierField.placeholderString = type == "bundleID" ? "com.example.app" : "app.*"
    identifierField.target = self
    identifierField.action = #selector(identifierChanged)
    identifierField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    
    // Delay field
    delayField = NSTextField()
    delayField.stringValue = String(format: "%.0f", delay)
    delayField.placeholderString = "30"
    delayField.target = self
    delayField.action = #selector(delayChanged)
    delayField.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    delayField.preferredMaxLayoutWidth = 60
    
    // Remove button
    let removeButton = NSButton(title: "×", target: self, action: #selector(remove))
    removeButton.bezelStyle = .circular
    removeButton.font = NSFont.systemFont(ofSize: 16, weight: .bold)
    removeButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    
    stackView.addArrangedSubview(typePopUp)
    stackView.addArrangedSubview(identifierField)
    stackView.addArrangedSubview(delayField)
    stackView.addArrangedSubview(removeButton)
    
    addSubview(stackView)
    
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
      heightAnchor.constraint(equalToConstant: 30)
    ])
  }
  
  @objc private func typeChanged() {
    type = typePopUp.selectedItem?.title == "Bundle ID" ? "bundleID" : "glob"
    identifierField.placeholderString = type == "bundleID" ? "com.example.app" : "app.*"
  }
  
  @objc private func identifierChanged() {
    appIdentifier = identifierField.stringValue
  }
  
  @objc private func delayChanged() {
    delay = TimeInterval(delayField.stringValue) ?? 30
  }
  
  @objc private func remove() {
    onRemove?()
    self.removeFromSuperview()
  }
}

// Run the settings app
let app = SettingsApp()
NSApplication.shared.delegate = app
NSApplication.shared.run() 