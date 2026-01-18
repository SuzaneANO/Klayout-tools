#!/bin/bash
# KLayout Tools Installation Script
#
# This script installs the KLayout tools to your macros folder.

set -e

echo "KLayout Tools Installer"
echo "======================="
echo ""

# Detect OS and set macros path
case "$(uname -s)" in
    Linux*)
        KLAYOUT_DIR="$HOME/.klayout"
        ;;
    Darwin*)
        KLAYOUT_DIR="$HOME/Library/Application Support/KLayout"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        KLAYOUT_DIR="$APPDATA/KLayout"
        ;;
    *)
        echo "Unknown operating system. Please install manually."
        exit 1
        ;;
esac

MACROS_DIR="$KLAYOUT_DIR/macros"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "KLayout directory: $KLAYOUT_DIR"
echo "Macros directory: $MACROS_DIR"
echo "Source directory: $SCRIPT_DIR"
echo ""

# Create macros directory if it doesn't exist
if [ ! -d "$MACROS_DIR" ]; then
    echo "Creating macros directory..."
    mkdir -p "$MACROS_DIR"
fi

# Create klayout-tools subdirectory
INSTALL_DIR="$MACROS_DIR/klayout-tools"
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing existing installation..."
    rm -rf "$INSTALL_DIR"
fi

echo "Creating installation directory..."
mkdir -p "$INSTALL_DIR"

# Copy macros
echo "Installing macros..."
cp "$SCRIPT_DIR/macros/"*.rb "$INSTALL_DIR/"

# Count installed files
INSTALLED=$(ls -1 "$INSTALL_DIR/"*.rb 2>/dev/null | wc -l)

echo ""
echo "Installation complete!"
echo "Installed $INSTALLED macros to: $INSTALL_DIR"
echo ""
echo "Available tools:"
echo "  - Layer Browser      (Ctrl+Shift+L)"
echo "  - Layer Statistics   (Ctrl+Shift+S)"
echo "  - Cell Hierarchy     (Ctrl+Shift+H)"
echo "  - Design Ruler       (Ctrl+Shift+R)"
echo "  - GDS Compare        (Ctrl+Shift+C)"
echo "  - Quick Export       (Ctrl+Shift+E)"
echo ""
echo "To use:"
echo "  1. Restart KLayout"
echo "  2. Go to Macros menu and run any tool"
echo "  3. Or use the keyboard shortcuts listed above"
echo ""
echo "For autorun (load tools on startup):"
echo "  1. Open KLayout"
echo "  2. Go to Macros -> Macro Development"
echo "  3. Navigate to the installed macros"
echo "  4. Right-click and select 'Make Autorun'"
