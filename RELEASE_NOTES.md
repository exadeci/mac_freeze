# MacFreeze v1.0.0 - Initial Release

## 🎉 First Release

This is the initial release of MacFreeze, a macOS utility that automatically freezes (suspends) applications after they become inactive for a configurable period.

## ✨ Features

- **Automatic Process Freezing**: Suspends applications after they become inactive
- **Configurable Delays**: Set different freeze delays for different applications
- **Pattern Matching**: Use glob patterns to match application names
- **Status Bar Integration**: Easy access to controls via the menu bar
- **Graceful Shutdown**: Automatically unfreezes all processes when quitting
- **Settings GUI**: Visual interface for managing application patterns and delays

## 🔧 Technical Details

- Uses `SIGSTOP`/`SIGCONT` signals to freeze/unfreeze processes
- Monitors workspace notifications for application activation/deactivation
- Stores configuration in JSON format in the user's home directory
- Runs as a status bar accessory application

## 📦 Installation

1. Download the `MacFreeze.app` from the releases
2. Drag to Applications folder
3. Launch MacFreeze from Applications

## ⚙️ Configuration

Create a configuration file at `~/.macfreeze_blacklist.json`:

```json
{
  "blacklist": [
    {
      "pattern": "Chrome",
      "delay": 30
    },
    {
      "pattern": "Safari",
      "delay": 60
    }
  ]
}
```

## 🚀 Usage

- Use the status bar menu to enable/disable freezing
- Access settings to configure application patterns and delays
- Use "Unfreeze All Processes" to immediately unfreeze all applications

## 🔒 Safety Features

- Automatically unfreezes all processes when MacFreeze is disabled or quit
- Graceful handling of signal interrupts
- Prevents accidental termination when windows are closed

## 📋 Requirements

- macOS 10.14 or later
- Xcode Command Line Tools (for building from source)

## 🐛 Known Issues

None at this time.

## 🔮 Future Plans

- Enhanced pattern matching options
- System preferences integration
- Performance monitoring and statistics 