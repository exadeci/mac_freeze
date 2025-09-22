# MacFreeze

A macOS utility that automatically freezes (suspends) applications after they become inactive for a configurable period. 

This helps reduce cpu usage by pausing applications you're not actively using with no delay when un-freezing them.

Quite useful for applications that tend to be CPU hungry even when in the background, like Firefox or Rekordbox.

## Features

- **Automatic Process Freezing**: Suspends applications after they become inactive
- **Configurable Delays**: Set different freeze delays for different applications
- **Pattern Matching**: Use glob patterns to match application names
- **Status Bar Integration**: Easy access to controls via the menu bar
- **Graceful Shutdown**: Automatically unfreezes all processes when quitting
- **Settings GUI**: Visual interface for managing application patterns and delays

## How It Works

MacFreeze monitors application activation/deactivation events and automatically freezes applications that match your configured patterns after the specified delay. When you switch back to a frozen application, it's immediately unfrozen.

## Building

### Prerequisites

- macOS 10.14 or later
- Xcode Command Line Tools (for Swift compilation)

### Build Commands

```bash
# Build the app bundle
make app

# Build and run the app
make run-app

# Build and install to Applications
make install-app

# Clean build artifacts
make clean
```

## Installation

1. Build the app: `make app`
2. Install to Applications: `make install-app`
3. Launch MacFreeze from Applications

## Configuration

MacFreeze uses a JSON configuration file located at `~/.macfreeze_blacklist.json`:

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
    },
    {
      "pattern": "*.app",
      "delay": 120
    }
  ]
}
```

### Configuration Options

- **pattern**: Glob pattern to match application names (e.g., "Chrome", "*.app", "Safari*")
- **delay**: Time in seconds to wait before freezing the application

### Pattern Examples

- `"Chrome"` - Matches applications named exactly "Chrome"
- `"*.app"` - Matches any application ending with ".app"
- `"Safari*"` - Matches applications starting with "Safari"
- `"*"` - Matches all applications

## Usage

### Status Bar Menu

- **Enable/Disable Freezing**: Toggle the freezing functionality on/off
- **Unfreeze All Processes**: Immediately unfreeze all currently frozen processes
- **Settings**: Open the preferences window to manage patterns and delays
- **Quit**: Exit MacFreeze (automatically unfreezes all processes)

### Settings Window

The settings window allows you to:
- Add new application patterns
- Set freeze delays for each pattern
- Remove existing patterns
- Save changes to the configuration file

## Technical Details

- Uses `SIGSTOP`/`SIGCONT` signals to freeze/unfreeze processes
- Monitors workspace notifications for application activation/deactivation
- Stores configuration in JSON format in the user's home directory
- Runs as a status bar accessory application

## Safety Features

- Automatically unfreezes all processes when:
  - MacFreeze is disabled
  - MacFreeze is quit
  - System receives termination signals (SIGINT, SIGTERM)
- Graceful handling of signal interrupts
- Prevents accidental termination when windows are closed

## Troubleshooting

### App Not Freezing
- Check that the application name matches your pattern exactly
- Verify the delay setting is appropriate
- Ensure MacFreeze is enabled in the status bar menu

### Configuration Issues
- Ensure the JSON file is valid syntax
- Check file permissions on `~/.macfreeze_blacklist.json`
- Restart MacFreeze after configuration changes

### Build Issues
- Ensure Xcode Command Line Tools are installed: `xcode-select --install`
- Check that all source files are present
- Verify the Makefile is in the project root

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests. 