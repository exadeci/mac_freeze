# Makefile for mac_freeze

# Compiler and flags
SWIFTC = swiftc
SWIFT_FLAGS = -framework Cocoa

# Target executable name
TARGET = mac_freeze

# Source files
SOURCES = main.swift

# Default target
all: build

# Build the application
build: $(TARGET)

$(TARGET): $(SOURCES)
	$(SWIFTC) $(SWIFT_FLAGS) -o $(TARGET) $(SOURCES)

# Run the application
run: build
	./$(TARGET)

# Clean build artifacts
clean:
	rm -f $(TARGET)

# Install (copy to user's home directory)
install: build
	cp $(TARGET) ~/$(TARGET)

# Uninstall
uninstall:
	rm -f ~/$(TARGET)

# Show help
help:
	@echo "Available targets:"
	@echo "  build     - Compile the application"
	@echo "  run       - Build and run the application"
	@echo "  clean     - Remove build artifacts"
	@echo "  install   - Build and install to home directory"
	@echo "  uninstall - Remove from home directory"
	@echo "  help      - Show this help message"

.PHONY: all build run clean install uninstall help 