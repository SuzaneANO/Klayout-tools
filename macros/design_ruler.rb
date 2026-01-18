# encoding: UTF-8
# KLayout Design Ruler
# 
# Enhanced measurement tool with grid snapping, angle constraints,
# and persistent measurements.
# 
# Author: Adam Sbane
# License: MIT
#
# Usage:
#   - Click to set first point
#   - Click again to set second point and create measurement
#   - Press Escape to cancel current measurement
#   - Press Delete to remove last measurement

unless $klayout_design_ruler_loaded

module KLayoutTools
module DesignRuler

  class RulerDialog < RBA::QDialog

    def initialize(view, parent = nil)
      super(parent)
      
      @view = view
      @measurements = []
      
      self.windowTitle = "Design Ruler - Measurements"
      self.setMinimumWidth(400)
      self.setMinimumHeight(300)
      
      setup_ui
      update_list
    end

    def setup_ui
      main_layout = RBA::QVBoxLayout.new(self)
      
      # Options
      options_group = RBA::QGroupBox.new("Options", self)
      options_layout = RBA::QVBoxLayout.new(options_group)
      
      @snap_checkbox = RBA::QCheckBox.new("Snap to grid", self)
      @snap_checkbox.setChecked(true)
      options_layout.addWidget(@snap_checkbox)
      
      @angle_checkbox = RBA::QCheckBox.new("Constrain to 45° angles", self)
      @angle_checkbox.setChecked(false)
      options_layout.addWidget(@angle_checkbox)
      
      grid_layout = RBA::QHBoxLayout.new
      grid_layout.addWidget(RBA::QLabel.new("Grid (um):", self))
      @grid_spin = RBA::QDoubleSpinBox.new(self)
      @grid_spin.setMinimum(0.001)
      @grid_spin.setMaximum(100.0)
      @grid_spin.setValue(0.01)
      @grid_spin.setDecimals(3)
      grid_layout.addWidget(@grid_spin)
      grid_layout.addStretch(1)
      options_layout.addLayout(grid_layout)
      
      main_layout.addWidget(options_group)
      
      # Measurements list
      list_group = RBA::QGroupBox.new("Measurements", self)
      list_layout = RBA::QVBoxLayout.new(list_group)
      
      @list = RBA::QListWidget.new(self)
      @list.itemDoubleClicked { |item| goto_measurement(item) }
      list_layout.addWidget(@list)
      
      main_layout.addWidget(list_group)
      
      # Buttons
      btn_layout = RBA::QHBoxLayout.new
      
      @clear_btn = RBA::QPushButton.new("Clear All", self)
      @clear_btn.clicked { clear_measurements }
      btn_layout.addWidget(@clear_btn)
      
      @export_btn = RBA::QPushButton.new("Export", self)
      @export_btn.clicked { export_measurements }
      btn_layout.addWidget(@export_btn)
      
      btn_layout.addStretch(1)
      
      @close_btn = RBA::QPushButton.new("Close", self)
      @close_btn.clicked { self.accept }
      btn_layout.addWidget(@close_btn)
      
      main_layout.addLayout(btn_layout)
    end

    def add_measurement(p1, p2, distance, angle)
      @measurements << {
        :p1 => p1,
        :p2 => p2,
        :distance => distance,
        :angle => angle
      }
      update_list
    end

    def update_list
      @list.clear
      @measurements.each_with_index do |m, i|
        text = "#{i + 1}: #{sprintf('%.3f', m[:distance])} um @ #{sprintf('%.1f', m[:angle])}°"
        @list.addItem(text)
      end
    end

    def goto_measurement(item)
      row = @list.row(item)
      return if row < 0 || row >= @measurements.length
      
      m = @measurements[row]
      
      # Zoom to measurement
      min_x = [m[:p1].x, m[:p2].x].min
      max_x = [m[:p1].x, m[:p2].x].max
      min_y = [m[:p1].y, m[:p2].y].min
      max_y = [m[:p1].y, m[:p2].y].max
      
      margin = [max_x - min_x, max_y - min_y].max * 0.5
      margin = 1.0 if margin < 0.1
      
      bbox = RBA::DBox.new(min_x - margin, min_y - margin, max_x + margin, max_y + margin)
      @view.zoom_box(bbox)
    end

    def clear_measurements
      @measurements = []
      # Clear rulers from view
      @view.clear_annotations
      update_list
    end

    def export_measurements
      return if @measurements.empty?
      
      file_path = RBA::FileDialog.get_save_file_name(
        "Export Measurements",
        ".",
        "CSV files (*.csv);;Text files (*.txt);;All files (*)"
      )
      
      return if file_path.nil? || file_path.empty?
      
      begin
        File.open(file_path, 'w') do |f|
          f.puts "Index,X1_um,Y1_um,X2_um,Y2_um,Distance_um,Angle_deg"
          @measurements.each_with_index do |m, i|
            f.puts "#{i + 1},#{m[:p1].x},#{m[:p1].y},#{m[:p2].x},#{m[:p2].y},#{m[:distance]},#{m[:angle]}"
          end
        end
        RBA::MessageBox.info("Export Complete", "Measurements exported to #{file_path}", RBA::MessageBox::Ok)
      rescue => e
        RBA::MessageBox.critical("Export Error", e.message, RBA::MessageBox::Ok)
      end
    end

    def snap_enabled?
      @snap_checkbox.isChecked
    end

    def angle_constrain_enabled?
      @angle_checkbox.isChecked
    end

    def grid_size
      @grid_spin.value
    end

  end

  class RulerPlugin < RBA::Plugin

    def initialize(view)
      super()
      @view = view
      @dialog = nil
      @start_point = nil
      @ruler = nil
    end

    def activated
      @dialog = RulerDialog.new(@view, RBA::Application.instance.main_window)
      @dialog.show
      RBA::MainWindow.instance.message("Click to set first measurement point", 10000)
    end

    def deactivated
      if @ruler
        @ruler._destroy
        @ruler = nil
      end
      @start_point = nil
    end

    def snap_to_grid(p)
      return p unless @dialog && @dialog.snap_enabled?
      
      grid = @dialog.grid_size
      x = (p.x / grid).round * grid
      y = (p.y / grid).round * grid
      RBA::DPoint.new(x, y)
    end

    def constrain_angle(p1, p2)
      return p2 unless @dialog && @dialog.angle_constrain_enabled?
      
      dx = p2.x - p1.x
      dy = p2.y - p1.y
      
      angle = Math.atan2(dy, dx) * 180.0 / Math::PI
      
      # Snap to nearest 45 degrees
      snapped_angle = (angle / 45.0).round * 45.0
      
      distance = Math.sqrt(dx * dx + dy * dy)
      rad = snapped_angle * Math::PI / 180.0
      
      new_x = p1.x + distance * Math.cos(rad)
      new_y = p1.y + distance * Math.sin(rad)
      
      RBA::DPoint.new(new_x, new_y)
    end

    def mouse_click_event(p, buttons, prio)
      return false unless prio
      
      p = snap_to_grid(p)
      
      if @start_point.nil?
        # First click - set start point
        @start_point = p
        RBA::MainWindow.instance.message("Click to set second point (Escape to cancel)", 10000)
        return true
      else
        # Second click - complete measurement
        end_point = constrain_angle(@start_point, p)
        
        # Calculate distance and angle
        dx = end_point.x - @start_point.x
        dy = end_point.y - @start_point.y
        distance = Math.sqrt(dx * dx + dy * dy)
        angle = Math.atan2(dy, dx) * 180.0 / Math::PI
        
        # Create ruler annotation
        ant = RBA::Annotation.new
        ant.p1 = @start_point
        ant.p2 = end_point
        ant.style = RBA::Annotation::StyleRuler
        ant.fmt = "$(sprintf('%.3f um', D))"
        @view.insert_annotation(ant)
        
        # Add to dialog
        if @dialog
          @dialog.add_measurement(@start_point, end_point, distance, angle)
        end
        
        RBA::MainWindow.instance.message("Measurement: #{sprintf('%.3f', distance)} um @ #{sprintf('%.1f', angle)}°", 10000)
        
        @start_point = nil
        return true
      end
    end

    def mouse_moved_event(p, buttons, prio)
      return false unless prio && @start_point
      
      p = snap_to_grid(p)
      p = constrain_angle(@start_point, p)
      
      # Update preview ruler
      if @ruler
        @ruler._destroy
      end
      
      @ruler = RBA::Marker.new(@view)
      @ruler.set(RBA::DEdge.new(@start_point, p))
      @ruler.line_style = 0
      @ruler.line_width = 1
      
      # Show distance in status
      dx = p.x - @start_point.x
      dy = p.y - @start_point.y
      distance = Math.sqrt(dx * dx + dy * dy)
      RBA::MainWindow.instance.message("Distance: #{sprintf('%.3f', distance)} um", 0)
      
      false
    end

    def key_event(key, buttons)
      if key == RBA::Qt::Key_Escape
        @start_point = nil
        if @ruler
          @ruler._destroy
          @ruler = nil
        end
        RBA::MainWindow.instance.message("Measurement cancelled", 5000)
        return true
      end
      false
    end

  end

  class RulerPluginFactory < RBA::PluginFactory

    def initialize
      super
      self.has_tool_entry = true
      self.register(-800, "design_ruler", "Design Ruler")
    end

    def create_plugin(manager, root, view)
      RulerPlugin.new(view)
    end

  end

  # Create factory
  RulerPluginFactory.new

  # Add menu action
  app = RBA::Application.instance
  mw = app.main_window
  menu = mw.menu
  
  unless menu.is_valid("tools_menu.design_ruler_action")
    action = RBA::Action.new
    action.title = "Design Ruler"
    action.shortcut = "Ctrl+Shift+R"
    action.on_triggered do
      # Activate the ruler tool
      view = mw.current_view
      if view
        RBA::MessageBox.info("Design Ruler", 
          "Select 'Design Ruler' from the toolbar to start measuring.\n\n" +
          "Usage:\n" +
          "- Click to set first point\n" +
          "- Click again to complete measurement\n" +
          "- Press Escape to cancel", 
          RBA::MessageBox::Ok)
      else
        RBA::MessageBox.warning("No View", "Please open a layout first.", RBA::MessageBox::Ok)
      end
    end
    menu.insert_item("tools_menu.end", "design_ruler_action", action)
  end

end # DesignRuler
end # KLayoutTools

$klayout_design_ruler_loaded = true
end # unless loaded
