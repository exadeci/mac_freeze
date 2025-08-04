import Cocoa

class PreferencesWindow: NSWindow {
  static var shared: PreferencesWindow?
  
  init() {
    super.init(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
               styleMask: [.titled, .closable, .miniaturizable],
               backing: .buffered,
               defer: false)
    
    self.title = "Mac Freeze Preferences"
    self.center()
    self.delegate = self
    self.isReleasedWhenClosed = false // Keep window alive
    
    let preferencesView = PreferencesView()
    self.contentView = preferencesView
  }
  
  func showWindow(_ sender: Any?) {
    self.makeKeyAndOrderFront(sender)
    NSApp.activate(ignoringOtherApps: true)
  }
}

extension PreferencesWindow: NSWindowDelegate {
  func windowWillClose(_ notification: Notification) {
    // Don't terminate the app, just hide the window
    NSApp.hide(nil)
  }
}

class PreferencesView: NSView {
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
        let pattern = entry["pattern"] as? String ?? ""
        let delay = entry["delay"] as? TimeInterval ?? 30
        
        let appEntry = AppEntryView(type: "glob", identifier: pattern, delay: delay)
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
    let appEntry = AppEntryView(type: "glob", identifier: "", delay: 30)
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
        let dict: [String: Any] = [
          "type": "glob",
          "pattern": entry.appIdentifier,
          "delay": entry.delay
        ]
        
        blacklist.append(dict)
      }
    }
    
    let json: [String: Any] = ["blacklist": blacklist]
    
    if let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
      let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("blacklist.json")
      try? data.write(to: url)
      
      // Reload configuration in main app
      MacFreezeApp.shared?.loadConfiguration()
      
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
    
    // Pattern field
    identifierField = NSTextField()
    identifierField.stringValue = appIdentifier
    identifierField.placeholderString = "app.*"
    identifierField.target = self
    identifierField.action = #selector(identifierChanged)
    identifierField.translatesAutoresizingMaskIntoConstraints = false
    
    // Style the text field
    identifierField.backgroundColor = NSColor.controlBackgroundColor
    identifierField.drawsBackground = true
    identifierField.bezelStyle = .roundedBezel
    identifierField.font = NSFont.systemFont(ofSize: 13)
    identifierField.textColor = NSColor.labelColor
    
    // Delay field
    delayField = NSTextField()
    delayField.stringValue = String(format: "%.0f", delay)
    delayField.placeholderString = "30"
    delayField.target = self
    delayField.action = #selector(delayChanged)
    delayField.translatesAutoresizingMaskIntoConstraints = false
    
    // Style the delay field and make it number-only
    delayField.backgroundColor = NSColor.controlBackgroundColor
    delayField.drawsBackground = true
    delayField.bezelStyle = .roundedBezel
    delayField.font = NSFont.systemFont(ofSize: 13)
    delayField.textColor = NSColor.labelColor
    delayField.cell?.formatter = NumberFormatter()
    
    // Remove button
    let removeButton = NSButton(title: "×", target: self, action: #selector(remove))
    removeButton.bezelStyle = .circular
    removeButton.font = NSFont.systemFont(ofSize: 16, weight: .bold)
    
    stackView.addArrangedSubview(identifierField)
    stackView.addArrangedSubview(delayField)
    stackView.addArrangedSubview(removeButton)
    
    addSubview(stackView)
    
    // Set explicit width constraints
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
      heightAnchor.constraint(equalToConstant: 30),
      
      // Fixed widths for delay field and remove button
      delayField.widthAnchor.constraint(equalToConstant: 80),
      removeButton.widthAnchor.constraint(equalToConstant: 30),
      
      // Identifier field constraints - ensure it's visible with minimum width
      identifierField.heightAnchor.constraint(equalToConstant: 24),
      identifierField.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)
    ])
    
    // Set content hugging and compression resistance priorities
    identifierField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    identifierField.setContentCompressionResistancePriority(.required, for: .horizontal)
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