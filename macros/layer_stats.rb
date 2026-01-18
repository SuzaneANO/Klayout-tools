# encoding: UTF-8
# KLayout Layer Statistics
# 
# Generate detailed statistics about layers in your design.
# Shows shape count, area, and bounding box for each layer.
# 
# Author: Adam Sbane
# License: MIT

unless $klayout_layer_stats_loaded

module KLayoutTools
module LayerStats

  class LayerStatsDialog < RBA::QDialog

    def initialize(view, parent = nil)
      super(parent)
      
      @view = view
      @stats = []
      
      self.windowTitle = "Layer Statistics"
      self.setMinimumWidth(700)
      self.setMinimumHeight(500)
      
      setup_ui
      calculate_stats
    end

    def setup_ui
      main_layout = RBA::QVBoxLayout.new(self)
      
      # Info label
      @info_label = RBA::QLabel.new("Analyzing layers...", self)
      main_layout.addWidget(@info_label)
      
      # Statistics table
      @table = RBA::QTableWidget.new(self)
      @table.setColumnCount(6)
      @table.setHorizontalHeaderLabels(["Layer", "Datatype", "Name", "Shapes", "Area (um²)", "Bbox (um)"])
      @table.horizontalHeader.setStretchLastSection(true)
      @table.setSelectionBehavior(RBA::QAbstractItemView::SelectRows)
      @table.setSortingEnabled(true)
      @table.cellDoubleClicked { |row, col| goto_layer(row) }
      main_layout.addWidget(@table)
      
      # Summary group
      summary_group = RBA::QGroupBox.new("Summary", self)
      summary_layout = RBA::QGridLayout.new(summary_group)
      
      summary_layout.addWidget(RBA::QLabel.new("Total Layers:", self), 0, 0)
      @total_layers_label = RBA::QLabel.new("0", self)
      @total_layers_label.setStyleSheet("font-weight: bold;")
      summary_layout.addWidget(@total_layers_label, 0, 1)
      
      summary_layout.addWidget(RBA::QLabel.new("Total Shapes:", self), 0, 2)
      @total_shapes_label = RBA::QLabel.new("0", self)
      @total_shapes_label.setStyleSheet("font-weight: bold;")
      summary_layout.addWidget(@total_shapes_label, 0, 3)
      
      summary_layout.addWidget(RBA::QLabel.new("Total Area:", self), 1, 0)
      @total_area_label = RBA::QLabel.new("0 um²", self)
      @total_area_label.setStyleSheet("font-weight: bold;")
      summary_layout.addWidget(@total_area_label, 1, 1)
      
      summary_layout.addWidget(RBA::QLabel.new("Design Bbox:", self), 1, 2)
      @design_bbox_label = RBA::QLabel.new("", self)
      @design_bbox_label.setStyleSheet("font-weight: bold;")
      summary_layout.addWidget(@design_bbox_label, 1, 3)
      
      main_layout.addWidget(summary_group)
      
      # Buttons
      btn_layout = RBA::QHBoxLayout.new
      
      @export_csv_btn = RBA::QPushButton.new("Export CSV", self)
      @export_csv_btn.clicked { export_csv }
      btn_layout.addWidget(@export_csv_btn)
      
      @export_json_btn = RBA::QPushButton.new("Export JSON", self)
      @export_json_btn.clicked { export_json }
      btn_layout.addWidget(@export_json_btn)
      
      @refresh_btn = RBA::QPushButton.new("Refresh", self)
      @refresh_btn.clicked { calculate_stats }
      btn_layout.addWidget(@refresh_btn)
      
      btn_layout.addStretch(1)
      
      @close_btn = RBA::QPushButton.new("Close", self)
      @close_btn.clicked { self.accept }
      btn_layout.addWidget(@close_btn)
      
      main_layout.addLayout(btn_layout)
    end

    def calculate_stats
      @stats = []
      @table.setRowCount(0)
      
      return unless @view && @view.cellview(0)
      
      cv = @view.cellview(0)
      layout = cv.layout
      cell = cv.cell
      dbu = layout.dbu
      
      return unless cell
      
      total_shapes = 0
      total_area = 0.0
      
      # Get layer properties
      iter = @view.begin_layers
      row = 0
      
      while !iter.at_end?
        lp = iter.current
        if lp.valid?
          layer_num = lp.source_layer
          datatype = lp.source_datatype
          name = lp.name.empty? ? "#{lp.source}" : lp.name
          
          layer_index = layout.find_layer(layer_num, datatype)
          
          if layer_index && layout.is_valid_layer?(layer_index)
            # Count shapes and calculate area
            shape_count = 0
            area = 0.0
            
            cell.each_shape(layer_index) do |shape|
              shape_count += 1
              if shape.is_polygon? || shape.is_box? || shape.is_path?
                area += shape.polygon.area * dbu * dbu
              end
            end
            
            # Get bounding box
            bbox = cell.bbox_per_layer(layer_index)
            bbox_str = ""
            if bbox && !bbox.empty?
              w = bbox.width * dbu
              h = bbox.height * dbu
              bbox_str = "#{format_number(w)} x #{format_number(h)}"
            end
            
            stat = {
              :layer => layer_num,
              :datatype => datatype,
              :name => name,
              :shapes => shape_count,
              :area => area,
              :bbox => bbox_str,
              :layer_prop => lp
            }
            @stats << stat
            
            total_shapes += shape_count
            total_area += area
            
            # Add to table
            @table.insertRow(row)
            @table.setItem(row, 0, RBA::QTableWidgetItem.new(layer_num.to_s))
            @table.setItem(row, 1, RBA::QTableWidgetItem.new(datatype.to_s))
            @table.setItem(row, 2, RBA::QTableWidgetItem.new(name))
            @table.setItem(row, 3, RBA::QTableWidgetItem.new(format_number(shape_count)))
            @table.setItem(row, 4, RBA::QTableWidgetItem.new(format_number(area)))
            @table.setItem(row, 5, RBA::QTableWidgetItem.new(bbox_str))
            
            row += 1
          end
        end
        iter.next
      end
      
      # Update summary
      @total_layers_label.text = @stats.length.to_s
      @total_shapes_label.text = format_number(total_shapes)
      @total_area_label.text = "#{format_number(total_area)} um²"
      
      design_bbox = cell.bbox
      if design_bbox && !design_bbox.empty?
        w = design_bbox.width * dbu
        h = design_bbox.height * dbu
        @design_bbox_label.text = "#{format_number(w)} x #{format_number(h)} um"
      end
      
      @info_label.text = "Analysis complete. Double-click a row to navigate to that layer."
      @table.resizeColumnsToContents
    end

    def format_number(num)
      if num.is_a?(Float)
        sprintf("%.3f", num).reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
      else
        num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
      end
    end

    def goto_layer(row)
      return if row < 0 || row >= @stats.length
      
      stat = @stats[row]
      
      # Hide all layers
      iter = @view.begin_layers
      while !iter.at_end?
        lp = iter.current
        lp.visible = false
        iter.next
      end
      
      # Show selected layer
      stat[:layer_prop].visible = true
      
      # Zoom to layer
      cv = @view.cellview(0)
      if cv && cv.cell
        layout = cv.layout
        layer_index = layout.find_layer(stat[:layer], stat[:datatype])
        if layer_index && layout.is_valid_layer?(layer_index)
          bbox = cv.cell.bbox_per_layer(layer_index)
          if bbox && !bbox.empty?
            @view.zoom_box(bbox.enlarged(bbox.width * 0.1, bbox.height * 0.1))
          end
        end
      end
    end

    def export_csv
      return if @stats.empty?
      
      file_path = RBA::FileDialog.get_save_file_name(
        "Export Statistics to CSV",
        ".",
        "CSV files (*.csv);;All files (*)"
      )
      
      return if file_path.nil? || file_path.empty?
      
      begin
        File.open(file_path, 'w') do |f|
          f.puts "Layer,Datatype,Name,Shapes,Area_um2,Bbox"
          @stats.each do |stat|
            f.puts "#{stat[:layer]},#{stat[:datatype]},\"#{stat[:name]}\",#{stat[:shapes]},#{stat[:area]},\"#{stat[:bbox]}\""
          end
        end
        RBA::MessageBox.info("Export Complete", "Statistics exported to #{file_path}", RBA::MessageBox::Ok)
      rescue => e
        RBA::MessageBox.critical("Export Error", e.message, RBA::MessageBox::Ok)
      end
    end

    def export_json
      return if @stats.empty?
      
      file_path = RBA::FileDialog.get_save_file_name(
        "Export Statistics to JSON",
        ".",
        "JSON files (*.json);;All files (*)"
      )
      
      return if file_path.nil? || file_path.empty?
      
      begin
        File.open(file_path, 'w') do |f|
          f.puts "{"
          f.puts "  \"layers\": ["
          @stats.each_with_index do |stat, i|
            comma = i < @stats.length - 1 ? "," : ""
            f.puts "    {"
            f.puts "      \"layer\": #{stat[:layer]},"
            f.puts "      \"datatype\": #{stat[:datatype]},"
            f.puts "      \"name\": \"#{stat[:name]}\","
            f.puts "      \"shapes\": #{stat[:shapes]},"
            f.puts "      \"area_um2\": #{stat[:area]},"
            f.puts "      \"bbox\": \"#{stat[:bbox]}\""
            f.puts "    }#{comma}"
          end
          f.puts "  ]"
          f.puts "}"
        end
        RBA::MessageBox.info("Export Complete", "Statistics exported to #{file_path}", RBA::MessageBox::Ok)
      rescue => e
        RBA::MessageBox.critical("Export Error", e.message, RBA::MessageBox::Ok)
      end
    end

  end

  # Add menu action
  app = RBA::Application.instance
  mw = app.main_window
  menu = mw.menu
  
  unless menu.is_valid("tools_menu.layer_stats_action")
    action = RBA::Action.new
    action.title = "Layer Statistics"
    action.shortcut = "Ctrl+Shift+S"
    action.on_triggered do
      view = mw.current_view
      if view
        dialog = LayerStatsDialog.new(view, mw)
        dialog.exec
      else
        RBA::MessageBox.warning("No View", "Please open a layout first.", RBA::MessageBox::Ok)
      end
    end
    menu.insert_item("tools_menu.end", "layer_stats_action", action)
  end

end # LayerStats
end # KLayoutTools

$klayout_layer_stats_loaded = true
end # unless loaded

# Show dialog when run as macro
app = RBA::Application.instance
mw = app.main_window
view = mw.current_view

if view
  dialog = KLayoutTools::LayerStats::LayerStatsDialog.new(view, mw)
  dialog.exec
else
  RBA::MessageBox.warning("No View", "Please open a layout first.", RBA::MessageBox::Ok)
end
