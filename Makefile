# Makefile for mac_freeze

# Compiler and flags
SWIFTC = swiftc
SWIFT_FLAGS = -framework Cocoa

# Target names
TARGET = mac_freeze
APP_NAME = MacFreeze.app
APP_BUNDLE = $(APP_NAME)/Contents/MacOS/$(TARGET)

# Source files
SOURCES = main.swift

# Default target
all: build

# Build the executable
build: $(TARGET)

$(TARGET): $(SOURCES)
	$(SWIFTC) $(SWIFT_FLAGS) -o $(TARGET) $(SOURCES)

# Build the app bundle
app: $(APP_BUNDLE)

$(APP_BUNDLE): $(TARGET) Info.plist
	@echo "Creating app bundle..."
	@mkdir -p $(APP_NAME)/Contents/MacOS
	@mkdir -p $(APP_NAME)/Contents/Resources
	@cp $(TARGET) $(APP_BUNDLE)
	@cp Info.plist $(APP_NAME)/Contents/
	@echo "App bundle created: $(APP_NAME)"

# Run the application
run: build
	./$(TARGET)

# Run the app bundle
run-app: app
	open $(APP_NAME)

# Clean build artifacts
clean:
	rm -f $(TARGET)
	rm -rf $(APP_NAME)

# Install executable to user's home directory
install: build
	cp $(TARGET) ~/$(TARGET)

# Install app bundle to Applications
install-app: app
	cp -R $(APP_NAME) /Applications/

# Uninstall executable
uninstall:
	rm -f ~/$(TARGET)

# Uninstall app bundle
uninstall-app:
	rm -rf /Applications/$(APP_NAME)

# Show help
help:
	@echo "Available targets:"
	@echo "  build       - Compile the executable"
	@echo "  app         - Build the app bundle"
	@echo "  run         - Build and run the executable"
	@echo "  run-app     - Build and run the app bundle"
	@echo "  clean       - Remove build artifacts"
	@echo "  install     - Build and install executable to home directory"
	@echo "  install-app - Build and install app bundle to Applications"
	@echo "  uninstall   - Remove executable from home directory"
	@echo "  uninstall-app - Remove app bundle from Applications"
	@echo "  help        - Show this help message"

.PHONY: all build app run run-app clean install install-app uninstall uninstall-app help 