# KLayout Tools - Installation Guide

## Quick Start

### Windows
```batch
git clone https://github.com/SuzaneANO/Klayout-tools.git
cd Klayout-tools
install.bat
```

### Linux/macOS
```bash
git clone https://github.com/SuzaneANO/Klayout-tools.git
cd Klayout-tools
./install.sh
```

---

## Detailed Installation Instructions

### Step 1: Download the Repository

**Option A: Using Git**
```bash
git clone https://github.com/SuzaneANO/Klayout-tools.git
```

**Option B: Download ZIP**
1. Go to https://github.com/SuzaneANO/Klayout-tools
2. Click the green "Code" button
3. Click "Download ZIP"
4. Extract the ZIP file

### Step 2: Run the Installer

#### Windows

**Method 1: Double-click**
- Navigate to the downloaded folder
- Double-click `install.bat`

**Method 2: Command Prompt**
```batch
cd path\to\Klayout-tools
install.bat
```

**Method 3: PowerShell**
```powershell
cd path\to\Klayout-tools
.\install.ps1
```

#### Linux
```bash
cd Klayout-tools
chmod +x install.sh
./install.sh
```

#### macOS
```bash
cd Klayout-tools
chmod +x install.sh
./install.sh
```

### Step 3: Restart KLayout

**IMPORTANT:** You must completely close and restart KLayout for the changes to take effect.

On Windows, make sure KLayout is not running in the system tray:
1. Right-click the KLayout icon in the system tray (bottom-right corner)
2. Click "Exit" or "Quit"
3. Start KLayout again

### Step 4: Verify Installation

1. Open KLayout
2. Open any GDS/OASIS file
3. Press `Ctrl+Shift+L` to open the Layer Browser
4. You should see the **"Kept Layers (K to add, C to clear)"** section

---

## Manual Installation

If the automatic installer doesn't work, you can install manually:

### Windows Manual Install

1. Open File Explorer
2. In the address bar, type: `%APPDATA%\KLayout\macros`
3. Press Enter
4. Create a folder named `klayout-tools` (if it doesn't exist)
5. Copy all files from the `macros` folder into `klayout-tools`:
   - `layer_browser.rb`
   - `layer_browser.lym`
   - `layer_stats.rb`
   - `cell_hierarchy.rb`
   - `design_ruler.rb`
   - `gds_compare.rb`
   - `quick_export.rb`

### Linux Manual Install

```bash
mkdir -p ~/.klayout/macros/klayout-tools
cp macros/* ~/.klayout/macros/klayout-tools/
```

### macOS Manual Install

```bash
mkdir -p ~/Library/Application\ Support/KLayout/macros/klayout-tools
cp macros/* ~/Library/Application\ Support/KLayout/macros/klayout-tools/
```

---

## Troubleshooting

### Problem: Tools don't appear in KLayout

**Solution 1:** Make sure KLayout is completely closed and restarted.

**Solution 2:** Check if files were copied to the correct location:
- Windows: `%APPDATA%\KLayout\macros\klayout-tools\`
- Linux: `~/.klayout/macros/klayout-tools/`
- macOS: `~/Library/Application Support/KLayout/macros/klayout-tools/`

### Problem: Old version of tools is running (Windows)

KLayout might be loading macros from a different location. Check:
- `C:\Users\<YourName>\KLayout\macros\` (note: different from AppData!)

If you find old `.lym` files there, rename or delete them.

### Problem: "Kept Layers" section not showing

This means an old version is cached. Try:
1. Close KLayout completely
2. Delete any `.lym` files in your KLayout macros folders that contain old Layer Browser code
3. Re-run the installer
4. Restart KLayout

### Problem: Permission denied (Linux/macOS)

```bash
chmod +x install.sh
./install.sh
```

---

## Uninstallation

### Windows
1. Open File Explorer
2. Navigate to `%APPDATA%\KLayout\macros\`
3. Delete the `klayout-tools` folder

### Linux
```bash
rm -rf ~/.klayout/macros/klayout-tools
```

### macOS
```bash
rm -rf ~/Library/Application\ Support/KLayout/macros/klayout-tools
```

---

## File Locations Reference

| OS | KLayout Config Directory |
|----|-------------------------|
| Windows | `%APPDATA%\KLayout\` |
| Linux | `~/.klayout/` |
| macOS | `~/Library/Application Support/KLayout/` |

Macros should be placed in the `macros` subdirectory.

---

## Support

If you encounter issues:
1. Check the [GitHub Issues](https://github.com/SuzaneANO/Klayout-tools/issues)
2. Create a new issue with:
   - Your operating system
   - KLayout version
   - Error messages (if any)
   - Steps to reproduce the problem
