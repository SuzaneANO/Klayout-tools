# encoding: UTF-8
# KLayout Quick Export
# 
# Export selected regions or entire design to various formats.
# Supports GDS, OASIS, DXF, and image formats.
# 
# Author: Adam Sbane
# License: MIT

unless $klayout_quick_export_loaded

module KLayoutTools
module QuickExport

  class QuickExportDialog < RBA::QDialog

    def initialize(view, parent = nil)
      super(parent)
      
      @view = view
      
      self.windowTitle = "Quick Export"
      self.setMinimumWidth(450)
      self.setMinimumHeight(400)
      
      setup_ui
    end

    def setup_ui
      main_layout = RBA::QVBoxLayout.new(self)
      
      # Export type
      type_group = RBA::QGroupBox.new("Export Type", self)
      type_layout = RBA::QVBoxLayout.new(type_group)
      
      @type_combo = RBA::QComboBox.new(self)
      @type_combo.addItem("GDS II (.gds)")
      @type_combo.addItem("OASIS (.oas)")
      @type_combo.addItem("DXF (.dxf)")
      @type_combo.addItem("PNG Image (.png)")
      @type_combo.addItem("SVG Vector (.svg)")
      @type_combo.currentIndexChanged { |idx| update_options(idx) }
      type_layout.addWidget(@type_combo)
      
      main_layout.addWidget(type_group)
      
      # Region selection
      region_group = RBA::QGroupBox.new("Region", self)
      region_layout = RBA::QVBoxLayout.new(region_group)
      
      @full_design_radio = RBA::QRadioButton.new("Full design", self)
      @full_design_radio.setChecked(true)
      region_layout.addWidget(@full_design_radio)
      
      @visible_area_radio = RBA::QRadioButton.new("Visible area only", self)
      region_layout.addWidget(@visible_area_radio)
      
      @custom_area_radio = RBA::QRadioButton.new("Custom area (um):", self)
      region_layout.addWidget(@custom_area_radio)
      
      custom_layout = RBA::QGridLayout.new
      custom_layout.addWidget(RBA::QLabel.new("X:", self), 0, 0)
      @x_spin = RBA::QDoubleSpinBox.new(self)
      @x_spin.setRange(-1e6, 1e6)
      @x_spin.setDecimals(3)
      custom_layout.addWidget(@x_spin, 0, 1)
      
      custom_layout.addWidget(RBA::QLabel.new("Y:", self), 0, 2)
      @y_spin = RBA::QDoubleSpinBox.new(self)
      @y_spin.setRange(-1e6, 1e6)
      @y_spin.setDecimals(3)
      custom_layout.addWidget(@y_spin, 0, 3)
      
      custom_layout.addWidget(RBA::QLabel.new("Width:", self), 1, 0)
      @w_spin = RBA::QDoubleSpinBox.new(self)
      @w_spin.setRange(0.001, 1e6)
      @w_spin.setValue(100)
      @w_spin.setDecimals(3)
      custom_layout.addWidget(@w_spin, 1, 1)
      
      custom_layout.addWidget(RBA::QLabel.new("Height:", self), 1, 2)
      @h_spin = RBA::QDoubleSpinBox.new(self)
      @h_spin.setRange(0.001, 1e6)
      @h_spin.setValue(100)
      @h_spin.setDecimals(3)
      custom_layout.addWidget(@h_spin, 1, 3)
      
      region_layout.addLayout(custom_layout)
      
      main_layout.addWidget(region_group)
      
      # Layout options
      @layout_options_group = RBA::QGroupBox.new("Layout Options", self)
      layout_options_layout = RBA::QVBoxLayout.new(@layout_options_group)
      
      @flatten_checkbox = RBA::QCheckBox.new("Flatten hierarchy", self)
      layout_options_layout.addWidget(@flatten_checkbox)
      
      @visible_layers_checkbox = RBA::QCheckBox.new("Export visible layers only", self)
      @visible_layers_checkbox.setChecked(true)
      layout_options_layout.addWidget(@visible_layers_checkbox)
      
      main_layout.addWidget(@layout_options_group)
      
      # Image options
      @image_options_group = RBA::QGroupBox.new("Image Options", self)
      image_options_layout = RBA::QGridLayout.new(@image_options_group)
      
      image_options_layout.addWidget(RBA::QLabel.new("Width (px):", self), 0, 0)
      @img_width_spin = RBA::QSpinBox.new(self)
      @img_width_spin.setRange(100, 10000)
      @img_width_spin.setValue(1920)
      image_options_layout.addWidget(@img_width_spin, 0, 1)
      
      image_options_layout.addWidget(RBA::QLabel.new("Height (px):", self), 0, 2)
      @img_height_spin = RBA::QSpinBox.new(self)
      @img_height_spin.setRange(100, 10000)
      @img_height_spin.setValue(1080)
      image_options_layout.addWidget(@img_height_spin, 0, 3)
      
      @img_transparent_checkbox = RBA::QCheckBox.new("Transparent background", self)
      image_options_layout.addWidget(@img_transparent_checkbox, 1, 0, 1, 2)
      
      @img_antialias_checkbox = RBA::QCheckBox.new("Anti-aliasing", self)
      @img_antialias_checkbox.setChecked(true)
      image_options_layout.addWidget(@img_antialias_checkbox, 1, 2, 1, 2)
      
      main_layout.addWidget(@image_options_group)
      @image_options_group.setVisible(false)
      
      # Output file
      output_group = RBA::QGroupBox.new("Output", self)
      output_layout = RBA::QHBoxLayout.new(output_group)
      
      @output_edit = RBA::QLineEdit.new(self)
      output_layout.addWidget(@output_edit)
      
      @browse_btn = RBA::QPushButton.new("Browse...", self)
      @browse_btn.clicked { browse_output }
      output_layout.addWidget(@browse_btn)
      
      main_layout.addWidget(output_group)
      
      # Buttons
      btn_layout = RBA::QHBoxLayout.new
      
      @export_btn = RBA::QPushButton.new("Export", self)
      @export_btn.clicked { do_export }
      btn_layout.addWidget(@export_btn)
      
      btn_layout.addStretch(1)
      
      @close_btn = RBA::QPushButton.new("Close", self)
      @close_btn.clicked { self.accept }
      btn_layout.addWidget(@close_btn)
      
      main_layout.addLayout(btn_layout)
      
      # Status
      @status_label = RBA::QLabel.new("", self)
      @status_label.setStyleSheet("color: gray;")
      main_layout.addWidget(@status_label)
    end

    def update_options(idx)
      is_image = idx >= 3
      @layout_options_group.setVisible(!is_image)
      @image_options_group.setVisible(is_image)
    end

    def browse_output
      idx = @type_combo.currentIndex
      
      filters = case idx
        when 0 then "GDS files (*.gds);;All files (*)"
        when 1 then "OASIS files (*.oas);;All files (*)"
        when 2 then "DXF files (*.dxf);;All files (*)"
        when 3 then "PNG files (*.png);;All files (*)"
        when 4 then "SVG files (*.svg);;All files (*)"
        else "All files (*)"
      end
      
      file = RBA::FileDialog.get_save_file_name("Export To", ".", filters)
      @output_edit.text = file if file && !file.empty?
    end

    def do_export
      output_file = @output_edit.text
      
      if output_file.empty?
        RBA::MessageBox.warning("No Output", "Please specify an output file.", RBA::MessageBox::Ok)
        return
      end
      
      return unless @view && @view.cellview(0)
      
      cv = @view.cellview(0)
      layout = cv.layout
      cell = cv.cell
      dbu = layout.dbu
      
      idx = @type_combo.currentIndex
      
      begin
        @status_label.text = "Exporting..."
        
        # Determine export region
        if @full_design_radio.isChecked
          bbox = cell.bbox
        elsif @visible_area_radio.isChecked
          bbox = @view.box
        else
          x = @x_spin.value / dbu
          y = @y_spin.value / dbu
          w = @w_spin.value / dbu
          h = @h_spin.value / dbu
          bbox = RBA::Box.new(x.to_i, y.to_i, (x + w).to_i, (y + h).to_i)
        end
        
        case idx
        when 0, 1, 2  # Layout formats
          export_layout(output_file, bbox, idx)
        when 3  # PNG
          export_image(output_file, bbox, "PNG")
        when 4  # SVG
          export_image(output_file, bbox, "SVG")
        end
        
        @status_label.text = "Export complete: #{output_file}"
        RBA::MessageBox.info("Export Complete", "File exported to:\n#{output_file}", RBA::MessageBox::Ok)
        
      rescue => e
        @status_label.text = "Error: #{e.message}"
        RBA::MessageBox.critical("Export Error", e.message, RBA::MessageBox::Ok)
      end
    end

    def export_layout(output_file, bbox, format_idx)
      cv = @view.cellview(0)
      layout = cv.layout
      cell = cv.cell
      
      # Create a copy for export
      export_layout = RBA::Layout.new
      export_layout.dbu = layout.dbu
      
      # Copy layers
      layer_map = {}
      
      if @visible_layers_checkbox.isChecked
        iter = @view.begin_layers
        while !iter.at_end?
          lp = iter.current
          if lp.valid? && lp.visible?
            src_li = layout.find_layer(lp.source_layer, lp.source_datatype)
            if src_li
              dst_li = export_layout.layer(lp.source_layer, lp.source_datatype)
              layer_map[src_li] = dst_li
            end
          end
          iter.next
        end
      else
        layout.layer_indices.each do |li|
          info = layout.get_info(li)
          dst_li = export_layout.layer(info)
          layer_map[li] = dst_li
        end
      end
      
      # Copy cell
      export_cell = export_layout.create_cell(cell.name)
      
      layer_map.each do |src_li, dst_li|
        region = RBA::Region.new(cell.begin_shapes_rec(src_li))
        region &= RBA::Region.new(bbox) unless bbox.nil?
        export_cell.shapes(dst_li).insert(region)
      end
      
      if @flatten_checkbox.isChecked
        export_cell.flatten(true)
      end
      
      # Write
      export_layout.write(output_file)
    end

    def export_image(output_file, bbox, format)
      width = @img_width_spin.value
      height = @img_height_spin.value
      
      # Save current view state
      saved_box = @view.box
      
      # Set view to export region
      @view.zoom_box(bbox) if bbox
      
      # Create image
      if format == "PNG"
        @view.save_image(output_file, width, height)
      else
        @view.save_image_with_options(output_file, width, height, 0, 0, 1.0, RBA::BitmapFormat::SVG)
      end
      
      # Restore view
      @view.zoom_box(saved_box)
    end

  end

  # Add menu action
  app = RBA::Application.instance
  mw = app.main_window
  menu = mw.menu
  
  unless menu.is_valid("tools_menu.quick_export_action")
    action = RBA::Action.new
    action.title = "Quick Export"
    action.shortcut = "Ctrl+Shift+E"
    action.on_triggered do
      view = mw.current_view
      if view
        dialog = QuickExportDialog.new(view, mw)
        dialog.exec
      else
        RBA::MessageBox.warning("No View", "Please open a layout first.", RBA::MessageBox::Ok)
      end
    end
    menu.insert_item("tools_menu.end", "quick_export_action", action)
  end

end # QuickExport
end # KLayoutTools

$klayout_quick_export_loaded = true
end # unless loaded

# Show dialog when run as macro
app = RBA::Application.instance
mw = app.main_window
view = mw.current_view

if view
  dialog = KLayoutTools::QuickExport::QuickExportDialog.new(view, mw)
  dialog.exec
else
  RBA::MessageBox.warning("No View", "Please open a layout first.", RBA::MessageBox::Ok)
end
