import Cocoa

// Load JSON blacklist → [bundleID: delaySeconds]
let url = FileManager.default.homeDirectoryForCurrentUser
               .appendingPathComponent("blacklist.json")
let data = try! Data(contentsOf: url)
let raw = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
let list = raw["blacklist"] as! [[String: Any]]
var delays = [String: TimeInterval]()
for e in list {
  let type = e["type"] as! String
  let delay = (e["delay"] as? TimeInterval) ?? 30
  
  if type == "bundleID" {
    let id = e["identifier"] as! String
    delays[id] = delay
  } else if type == "glob" {
    let pattern = e["pattern"] as! String
    delays[pattern] = delay
  }
}

// Track pending freeze work items
var pendingTimers = [pid_t: DispatchWorkItem]()

let nc = NSWorkspace.shared.notificationCenter
nc.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
               object: nil, queue: .main) { note in
  guard let info = note.userInfo,
        let app = info[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
  
  let pid = app.processIdentifier

  // Cancel any pending freeze for this PID
  pendingTimers[pid]?.cancel()
  pendingTimers.removeValue(forKey: pid)

  // Unfreeze immediately
  kill(pid, SIGCONT)
}

nc.addObserver(forName: NSWorkspace.didDeactivateApplicationNotification,
               object: nil, queue: .main) { note in
  guard let info = note.userInfo,
        let app = info[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
        let bid = app.bundleIdentifier,
        let delay = delays[bid] else { return }

  let pid = app.processIdentifier

  // Schedule freeze after `delay`
  let work = DispatchWorkItem {
    kill(pid, SIGSTOP)
    pendingTimers.removeValue(forKey: pid)
  }
  pendingTimers[pid] = work
  DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: work)
}

// Keep the runloop alive
RunLoop.main.run()
