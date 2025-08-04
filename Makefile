# Makefile for mac_freeze

# Compiler and flags
SWIFTC = swiftc
SWIFT_FLAGS = -framework Cocoa

# Target names
TARGET = mac_freeze
APP_NAME = MacFreeze.app
APP_BUNDLE = $(APP_NAME)/Contents/MacOS/$(TARGET)

# Source files
SOURCES = main.swift PreferencesWindow.swift

# Default target
all: app

# Build the app bundle
app: $(APP_BUNDLE)

$(APP_BUNDLE): $(SOURCES) Info.plist
	@echo "Creating app bundle..."
	@mkdir -p $(APP_NAME)/Contents/MacOS
	@mkdir -p $(APP_NAME)/Contents/Resources
	@mkdir -p $(APP_NAME)/Contents/Resources/icons
	$(SWIFTC) $(SWIFT_FLAGS) -o $(APP_BUNDLE) $(SOURCES)
	@cp Info.plist $(APP_NAME)/Contents/
	@if [ -f MacFreeze.icns ]; then \
		cp MacFreeze.icns $(APP_NAME)/Contents/Resources/; \
		echo "Icon added to app bundle"; \
	fi
	@if [ -d icons ]; then \
		cp -r icons $(APP_NAME)/Contents/Resources/; \
		echo "Status bar icons added to app bundle"; \
	fi
	@echo "App bundle created: $(APP_NAME)"

# Run the app bundle
run-app: app
	open $(APP_NAME)

# Clean build artifacts
clean:
	rm -rf $(APP_NAME)

# Install app bundle to Applications
install-app: app
	cp -R $(APP_NAME) /Applications/

# Uninstall app bundle
uninstall-app:
	rm -rf /Applications/$(APP_NAME)

# Show help
help:
	@echo "Available targets:"
	@echo "  app         - Build the app bundle"
	@echo "  run-app     - Build and run the app bundle"
	@echo "  clean       - Remove build artifacts"
	@echo "  install-app - Build and install app bundle to Applications"
	@echo "  uninstall-app - Remove app bundle from Applications"
	@echo "  help        - Show this help message"

.PHONY: all app run-app clean install-app uninstall-app help 