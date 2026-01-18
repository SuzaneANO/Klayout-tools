# KLayout Tools

A collection of useful KLayout macros and plugins for IC layout viewing and analysis, particularly useful for PDK exploration and ASIC/FPGA design workflows.

## Demo

### Layer Browser in Action

[**Watch Demo Video**](https://github.com/SuzaneANO/Klayout-tools/releases/download/v1.0.0/layer_browser_demo.mp4) - Browsing through SKY130 PDK layers on a PLL Controller design

## Features

- **Layer Browser** - Navigate through PDK layers one by one with isolation mode
- **Layer Statistics** - Analyze shape counts, area coverage per layer
- **Design Ruler** - Measure distances with snapping to grid
- **Cell Hierarchy Viewer** - Explore cell hierarchy and instances
- **GDS Compare** - Visual diff between two GDS files
- **Quick Export** - Export selected regions to various formats

## Installation

### Windows

#### Option A: Automatic Install (Recommended)
1. Download or clone this repository:
   ```
   git clone https://github.com/SuzaneANO/Klayout-tools.git
   ```
2. Double-click `install.bat`
3. **Completely close KLayout** (check system tray)
4. Restart KLayout

#### Option B: PowerShell Install
```powershell
git clone https://github.com/SuzaneANO/Klayout-tools.git
cd Klayout-tools
.\install.ps1
```

#### Option C: Manual Install
1. Open File Explorer
2. Type `%APPDATA%\KLayout\macros` in the address bar and press Enter
3. Create a new folder called `klayout-tools`
4. Copy ALL files from the `macros` folder (both `.rb` and `.lym` files) into it
5. **Completely close KLayout** and restart it

#### Troubleshooting Windows Installation
If the new features don't appear after installation:
1. Check if you have macros in `C:\Users\<YourName>\KLayout\macros\` - this is a different location!
2. Delete or rename any old `.lym` files that might contain outdated code
3. Make sure KLayout is completely closed (not in system tray) before restarting

### Linux

```bash
git clone https://github.com/SuzaneANO/Klayout-tools.git
cd Klayout-tools
./install.sh
```

Or manually copy to: `~/.klayout/macros/klayout-tools/`

### macOS

```bash
git clone https://github.com/SuzaneANO/Klayout-tools.git
cd Klayout-tools
./install.sh
```

Or manually copy to: `~/Library/Application Support/KLayout/macros/klayout-tools/`

### Run Without Installing

```bash
klayout design.gds -rm macros/layer_browser.rb
```

### Verifying Installation

After installation, verify the tools are working:
1. Open KLayout
2. Open any GDS file
3. Go to **Macros** menu - you should see the tools listed
4. Or press `Ctrl+Shift+L` to open Layer Browser
5. The Layer Browser should show a **"Kept Layers"** section with K and C buttons

## Tools Overview

### Layer Browser (`macros/layer_browser.rb`)

Browse through all PDK layers one by one. Perfect for understanding layer stackup and inspecting individual mask layers.

**Features:**
- Navigate layers with Next (N) / Previous (P) keys
- Isolate mode - show only current layer
- Display layer info: name, layer/datatype, shape count
- Search/filter layers by name
- Export layer list to CSV

**Keyboard Shortcuts:**
| Key | Action |
|-----|--------|
| `N` | Next layer |
| `P` | Previous layer |
| `K` | Keep/pin current layer (stays visible while browsing) |
| `C` | Clear all kept/pinned layers |
| `A` | Show all layers |
| `I` | Toggle isolate mode |
| `L` | Load PDK layer map (.lyp file) |
| `Home` | Jump to first layer |
| `End` | Jump to last layer |

**PDK Layer Map Support:**
- Load `.lyp` files to see proper PDK layer names (e.g., "li1.drawing" instead of "67/20")
- Click "Load Map" or press `L` to browse for a layer map file
- Click "Auto-Detect" to automatically find `.lyp` files in common locations
- Layer names from the PDK are shown in green for easy identification
- Works with SKY130, GF180MCU, and other PDKs that provide `.lyp` files

### Layer Statistics (`macros/layer_stats.rb`)

Generate detailed statistics about layers in your design.

**Features:**
- Shape count per layer
- Total area per layer
- Bounding box dimensions
- Export to CSV/JSON

### Design Ruler (`macros/design_ruler.rb`)

Enhanced measurement tool with grid snapping and angle constraints.

**Features:**
- Snap to manufacturing grid
- Angle-constrained measurements (45°, 90°)
- Persistent measurements
- Export measurement report

### Cell Hierarchy Viewer (`macros/cell_hierarchy.rb`)

Explore the cell hierarchy of your design.

**Features:**
- Tree view of cell hierarchy
- Instance count per cell
- Navigate to cell instances
- Highlight selected cells

### GDS Compare (`macros/gds_compare.rb`)

Visual comparison between two GDS files.

**Features:**
- XOR comparison
- Layer-by-layer diff
- Highlight differences
- Generate diff report

## Usage Examples

### Basic Usage

1. Open a GDS file in KLayout
2. Run the desired macro from **Macros** menu or use keyboard shortcut
3. Use the tool dialog to interact with your design

### Command Line

```bash
# Open GDS with layer browser
klayout design.gds -rm macros/layer_browser.rb

# Run layer statistics
klayout design.gds -r scripts/layer_stats.py -rd output=stats.csv

# Compare two GDS files
klayout -r scripts/gds_compare.py -rd gds1=design_v1.gds -rd gds2=design_v2.gds
```

### Python API

```python
import klayout.db as db
import klayout.lay as lay

# Load and analyze a GDS
layout = db.Layout()
layout.read("design.gds")

# Get layer statistics
for layer_info in layout.layer_infos():
    layer_idx = layout.find_layer(layer_info)
    # ... analyze layer
```

## Supported PDKs

These tools work with any PDK, but have been tested with:

- SKY130 (SkyWater 130nm)
- GF180MCU (GlobalFoundries 180nm)
- ASAP7 (7nm predictive)
- FreePDK45

## Requirements

- KLayout 0.28.0 or later
- Ruby support enabled (for .rb macros)
- Python support enabled (for .py scripts)

## Contributing

Contributions are welcome! Please feel free to submit pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-tool`)
3. Commit your changes (`git commit -m 'Add amazing tool'`)
4. Push to the branch (`git push origin feature/amazing-tool`)
5. Open a Pull Request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- [KLayout](https://www.klayout.de/) - The amazing open-source layout viewer
- [OpenLane](https://github.com/The-OpenROAD-Project/OpenLane) - Open-source RTL-to-GDSII flow
- [SkyWater PDK](https://github.com/google/skywater-pdk) - Open-source 130nm PDK
