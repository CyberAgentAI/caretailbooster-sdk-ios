#!/bin/bash

# build.sh - Build script for Example project

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="Example"
SCHEME="Example"
PROJECT_PATH="Example.xcodeproj"
BUILD_DIR="build"

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_message $YELLOW "Checking prerequisites..."
    
    if ! command_exists xcodebuild; then
        print_message $RED "Error: xcodebuild not found. Please install Xcode."
        exit 1
    fi
    
    if ! command_exists xcrun; then
        print_message $RED "Error: xcrun not found. Please install Xcode Command Line Tools."
        exit 1
    fi
    
    print_message $GREEN "✓ All prerequisites met"
}

# Get booted simulator
get_booted_simulator() {
    # Get all booted simulators
    local booted_count=$(xcrun simctl list devices | grep "(Booted)" | wc -l | tr -d ' ')
    
    if [ "$booted_count" -eq 0 ]; then
        echo ""
    elif [ "$booted_count" -eq 1 ]; then
        # Only one booted simulator, use it
        local booted=$(xcrun simctl list devices | grep "(Booted)" | head -n 1 | sed 's/^[[:space:]]*//' | sed 's/ (.*$//')
        echo "$booted"
    else
        # Multiple booted simulators, prefer iPhone over iPad
        local booted_iphone=$(xcrun simctl list devices | grep "(Booted)" | grep "iPhone" | head -n 1 | sed 's/^[[:space:]]*//' | sed 's/ (.*$//')
        if [ -n "$booted_iphone" ]; then
            echo "$booted_iphone"
        else
            # No iPhone booted, use the first one
            local booted=$(xcrun simctl list devices | grep "(Booted)" | head -n 1 | sed 's/^[[:space:]]*//' | sed 's/ (.*$//')
            echo "$booted"
        fi
    fi
}

# Get default simulator
get_default_simulator() {
    # First, check if there's a booted simulator
    local booted=$(get_booted_simulator)
    if [ -n "$booted" ]; then
        echo "$booted"
    else
        # Try to use the first available iPhone simulator
        local first_iphone=$(xcrun simctl list devices available | grep "iPhone" | head -n 1 | sed 's/^[[:space:]]*//' | sed 's/ (.*$//')
        if [ -n "$first_iphone" ]; then
            echo "$first_iphone"
        else
            echo "iPhone 16 Pro"
        fi
    fi
}

# Build for simulator
build_simulator() {
    local configuration=${1:-Debug}
    local simulator=${2:-$(get_default_simulator)}
    
    # Check if multiple simulators are booted
    local booted_count=$(xcrun simctl list devices | grep "(Booted)" | wc -l | tr -d ' ')
    if [ "$booted_count" -gt 1 ] && [ -z "$2" ]; then
        print_message $YELLOW "Multiple simulators are booted. Using: $simulator"
    fi
    
    print_message $YELLOW "Building for iOS Simulator ($configuration) - Target: $simulator..."
    
    # Record start time
    local start_time=$(date +%s)
    
    xcodebuild \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration "$configuration" \
        -sdk iphonesimulator \
        -destination "platform=iOS Simulator,name=$simulator" \
        -derivedDataPath "$BUILD_DIR" \
        build
    
    local build_result=$?
    
    # Calculate elapsed time
    local end_time=$(date +%s)
    local elapsed_time=$((end_time - start_time))
    
    if [ $build_result -eq 0 ]; then
        print_message $GREEN "✓ Build successful! (${elapsed_time}s)"
        return 0
    else
        print_message $RED "✗ Build failed! (${elapsed_time}s)"
        return 1
    fi
}

# Run on simulator
run_simulator() {
    local bundle_id="com.caretailbooster-sdk.example"
    
    print_message $YELLOW "Installing and running on simulator..."
    
    # Find the app path
    local app_path=$(find "$BUILD_DIR" -name "*.app" -type d | head -n 1)
    
    if [ -z "$app_path" ]; then
        print_message $RED "Error: App not found. Please build first."
        return 1
    fi
    
    # Install on booted simulator
    xcrun simctl install booted "$app_path"
    
    if [ $? -eq 0 ]; then
        print_message $GREEN "✓ App installed"
        
        # Launch the app
        xcrun simctl launch booted "$bundle_id"
        
        if [ $? -eq 0 ]; then
            print_message $GREEN "✓ App launched"
        else
            print_message $RED "✗ Failed to launch app"
            return 1
        fi
    else
        print_message $RED "✗ Failed to install app"
        return 1
    fi
}

# Clean build directory
clean() {
    print_message $YELLOW "Cleaning build directory..."
    
    # Record start time
    local start_time=$(date +%s)
    
    rm -rf "$BUILD_DIR"
    xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" clean
    
    # Calculate elapsed time
    local end_time=$(date +%s)
    local elapsed_time=$((end_time - start_time))
    
    print_message $GREEN "✓ Clean complete (${elapsed_time}s)"
}

# List available simulators
list_simulators() {
    print_message $GREEN "Available iOS Simulators:"
    xcrun simctl list devices | grep -E "iPhone|iPad" | grep -v unavailable | sed 's/^/  /'
}

# List booted simulators
list_booted() {
    print_message $GREEN "Booted iOS Simulators:"
    local booted=$(xcrun simctl list devices | grep "(Booted)" | sed 's/^[[:space:]]*//')
    if [ -z "$booted" ]; then
        print_message $YELLOW "  No simulators are currently booted"
    else
        echo "$booted" | sed 's/^/  /'
    fi
}

# Main script logic
main() {
    case "$1" in
        "build")
            check_prerequisites
            build_simulator "${2:-Debug}" "$3"
            ;;
        "run")
            check_prerequisites
            if build_simulator "Debug" "$2"; then
                run_simulator
            fi
            ;;
        "release")
            check_prerequisites
            build_simulator "Release" "$2"
            ;;
        "clean")
            clean
            ;;
        "list")
            list_simulators
            ;;
        "list-booted")
            list_booted
            ;;
        *)
            print_message $GREEN "Example Project Build Script"
            echo ""
            echo "Usage: $0 [command] [options]"
            echo ""
            echo "Commands:"
            echo "  build [configuration] [simulator]  - Build the project"
            echo "  run [simulator]                    - Build and run on simulator"
            echo "  release [simulator]                - Build release version"
            echo "  clean                              - Clean build directory"
            echo "  list                               - List available simulators"
            echo "  list-booted                        - List currently booted simulators"
            echo ""
            echo "Simulator selection priority:"
            echo "  1. Currently booted simulator (if any)"
            echo "  2. First available iPhone simulator"
            echo "  3. Fallback to iPhone 16 Pro"
            echo ""
            echo "Examples:"
            echo "  $0 build                          # Build Debug for booted/available simulator"
            echo "  $0 build Release \"iPhone 14 Pro\"  # Build Release for specific simulator"
            echo "  $0 run                            # Build and run on booted/available simulator"
            echo "  $0 run \"iPad Pro (12.9-inch)\"    # Build and run on specific device"
            ;;
    esac
}

# Run main function
main "$@"
