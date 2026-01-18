# KLayout Tools Documentation

## Overview

This collection provides six powerful tools for IC layout viewing and analysis in KLayout.

## Tools

### 1. Layer Browser

**File:** `macros/layer_browser.rb`  
**Shortcut:** `Ctrl+Shift+L`

Browse through PDK layers one by one. Perfect for understanding layer stackup and inspecting individual mask layers.

#### Features
- Navigate layers with keyboard shortcuts
- Isolate mode - show only current layer
- Search/filter layers by name
- Display shape count per layer
- Export layer list to CSV

#### Keyboard Shortcuts
| Key | Action |
|-----|--------|
| `N` | Next layer |
| `P` | Previous layer |
| `A` | Show all layers |
| `I` | Toggle isolate mode |
| `Home` | First layer |
| `End` | Last layer |

---

### 2. Layer Statistics

**File:** `macros/layer_stats.rb`  
**Shortcut:** `Ctrl+Shift+S`

Generate detailed statistics about all layers in your design.

#### Features
- Shape count per layer
- Total area calculation (in um²)
- Bounding box dimensions
- Sortable table view
- Export to CSV or JSON
- Double-click to navigate to layer

#### Output Columns
- Layer number
- Datatype
- Layer name
- Shape count
- Area (um²)
- Bounding box

---

### 3. Cell Hierarchy Viewer

**File:** `macros/cell_hierarchy.rb`  
**Shortcut:** `Ctrl+Shift+H`

Explore the cell hierarchy of your design with instance counts and navigation.

#### Features
- Tree view of cell hierarchy
- Instance count per cell
- Direct children count
- Search/filter cells
- Navigate to cell instances
- Calculate hierarchy depth
- Export hierarchy to text file

---

### 4. Design Ruler

**File:** `macros/design_ruler.rb`  
**Shortcut:** `Ctrl+Shift+R`

Enhanced measurement tool with grid snapping and angle constraints.

#### Features
- Snap to manufacturing grid
- Configurable grid size
- 45° angle constraints
- Persistent measurements list
- Export measurements to CSV

#### Usage
1. Select "Design Ruler" from toolbar
2. Click to set first point
3. Click again to complete measurement
4. Press Escape to cancel

---

### 5. GDS Compare

**File:** `macros/gds_compare.rb`  
**Shortcut:** `Ctrl+Shift+C`

Visual comparison between two GDS files using XOR operation.

#### Features
- XOR comparison on all layers
- Layer-by-layer difference report
- View XOR result in KLayout
- Flatten option for deep comparison
- Export comparison report

#### Usage
1. Select reference GDS file
2. Select comparison GDS file
3. Click "Compare"
4. View results or export report

---

### 6. Quick Export

**File:** `macros/quick_export.rb`  
**Shortcut:** `Ctrl+Shift+E`

Export selected regions or entire design to various formats.

#### Supported Formats
- GDS II (.gds)
- OASIS (.oas)
- DXF (.dxf)
- PNG Image (.png)
- SVG Vector (.svg)

#### Features
- Export full design or visible area
- Custom region export
- Flatten hierarchy option
- Export visible layers only
- Image size and quality options

---

## Common Usage Patterns

### Exploring a New PDK

1. Open a sample GDS from the PDK
2. Use **Layer Browser** to understand layer stackup
3. Use **Layer Statistics** to see which layers are used
4. Use **Cell Hierarchy** to understand standard cell organization

### Design Review

1. Open your design GDS
2. Use **Layer Browser** to inspect each layer
3. Use **Design Ruler** to verify critical dimensions
4. Use **Quick Export** to create images for documentation

### Design Comparison

1. Use **GDS Compare** to compare versions
2. Review XOR results for differences
3. Export comparison report for records

### Documentation

1. Use **Quick Export** to create high-resolution images
2. Use **Layer Statistics** to generate layer reports
3. Use **Cell Hierarchy** to document design structure
