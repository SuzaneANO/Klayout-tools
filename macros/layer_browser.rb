# encoding: UTF-8
# KLayout Layer Browser
# 
# Browse through PDK layers one by one with isolation mode.
# 
# Author: Adam Sbane
# License: MIT
#
# Keyboard Shortcuts:
#   N     - Next layer
#   P     - Previous layer  
#   K     - Keep/pin current layer (stays visible while browsing)
#   C     - Clear all kept/pinned layers
#   A     - Show all layers
#   I     - Toggle isolate mode
#   Home  - Jump to first layer
#   End   - Jump to last layer

unless $klayout_layer_browser_loaded

module KLayoutTools
module LayerBrowser

  class LayerBrowserDialog < RBA::QDialog

    def initialize(view, parent = nil)
      super(parent)
      
      @view = view
      @current_layer_index = 0
      @layers = []
      @original_visibility = {}
      @isolate_mode = true
      @filtered_indices = []
      @kept_layers = []  # Array of layer indices that are "pinned"
      
      self.windowTitle = "PDK Layer Browser"
      self.setMinimumWidth(450)
      self.setMinimumHeight(550)
      
      setup_ui
      refresh_layers
      update_display
    end

    def setup_ui
      main_layout = RBA::QVBoxLayout.new(self)
      
      # Layer info group
      info_group = RBA::QGroupBox.new("Current Layer", self)
      info_layout = RBA::QVBoxLayout.new(info_group)
      
      @layer_name_label = RBA::QLabel.new("", self)
      @layer_name_label.setStyleSheet("font-size: 14pt; font-weight: bold; color: #2196F3;")
      info_layout.addWidget(@layer_name_label)
      
      @layer_info_label = RBA::QLabel.new("", self)
      info_layout.addWidget(@layer_info_label)
      
      @shape_count_label = RBA::QLabel.new("", self)
      info_layout.addWidget(@shape_count_label)
      
      main_layout.addWidget(info_group)
      
      # Progress bar
      progress_layout = RBA::QHBoxLayout.new
      @progress_label = RBA::QLabel.new("Layer 0 of 0", self)
      progress_layout.addWidget(@progress_label)
      @progress_bar = RBA::QProgressBar.new(self)
      @progress_bar.setMinimum(0)
      progress_layout.addWidget(@progress_bar)
      main_layout.addLayout(progress_layout)
      
      # Navigation group
      nav_group = RBA::QGroupBox.new("Navigation", self)
      nav_layout = RBA::QHBoxLayout.new(nav_group)
      
      @prev_btn = RBA::QPushButton.new("<< Prev (P)", self)
      @prev_btn.clicked { navigate_prev }
      nav_layout.addWidget(@prev_btn)
      
      @layer_spin = RBA::QSpinBox.new(self)
      @layer_spin.setMinimum(0)
      @layer_spin.valueChanged { |v| jump_to_layer(v) }
      nav_layout.addWidget(@layer_spin)
      
      @next_btn = RBA::QPushButton.new("Next (N) >>", self)
      @next_btn.clicked { navigate_next }
      nav_layout.addWidget(@next_btn)
      
      main_layout.addWidget(nav_group)
      
      # Search and layer list
      list_group = RBA::QGroupBox.new("All Layers", self)
      list_layout = RBA::QVBoxLayout.new(list_group)
      
      # Search box
      search_layout = RBA::QHBoxLayout.new
      search_label = RBA::QLabel.new("Search:", self)
      search_layout.addWidget(search_label)
      @search_edit = RBA::QLineEdit.new(self)
      @search_edit.setPlaceholderText("Filter layers by name...")
      @search_edit.textChanged { |t| filter_layers(t) }
      search_layout.addWidget(@search_edit)
      list_layout.addLayout(search_layout)
      
      @layer_list = RBA::QListWidget.new(self)
      @layer_list.currentRowChanged { |row| select_layer_from_list(row) if row >= 0 }
      list_layout.addWidget(@layer_list)
      
      main_layout.addWidget(list_group)
      
      # Options group
      options_group = RBA::QGroupBox.new("Options", self)
      options_layout = RBA::QVBoxLayout.new(options_group)
      
      @isolate_checkbox = RBA::QCheckBox.new("Isolate current layer (I)", self)
      @isolate_checkbox.setChecked(@isolate_mode)
      @isolate_checkbox.stateChanged { |state| toggle_isolate_mode(state == RBA::Qt::Checked) }
      options_layout.addWidget(@isolate_checkbox)
      
      @zoom_checkbox = RBA::QCheckBox.new("Auto-zoom to layer extent", self)
      @zoom_checkbox.setChecked(false)
      options_layout.addWidget(@zoom_checkbox)
      
      main_layout.addWidget(options_group)
      
      # Kept/Pinned layers group
      kept_group = RBA::QGroupBox.new("Kept Layers (K to add, C to clear)", self)
      kept_layout = RBA::QVBoxLayout.new(kept_group)
      
      @kept_list = RBA::QListWidget.new(self)
      @kept_list.setMaximumHeight(80)
      @kept_list.itemDoubleClicked { |item| remove_kept_layer_by_item(item) }
      kept_layout.addWidget(@kept_list)
      
      kept_btn_layout = RBA::QHBoxLayout.new
      @keep_btn = RBA::QPushButton.new("Keep Current (K)", self)
      @keep_btn.clicked { keep_current_layer }
      kept_btn_layout.addWidget(@keep_btn)
      
      @clear_kept_btn = RBA::QPushButton.new("Clear All (C)", self)
      @clear_kept_btn.clicked { clear_kept_layers }
      kept_btn_layout.addWidget(@clear_kept_btn)
      
      kept_layout.addLayout(kept_btn_layout)
      main_layout.addWidget(kept_group)
      
      # Action buttons
      btn_layout = RBA::QHBoxLayout.new
      
      @show_all_btn = RBA::QPushButton.new("Show All (A)", self)
      @show_all_btn.clicked { show_all_layers }
      btn_layout.addWidget(@show_all_btn)
      
      @export_btn = RBA::QPushButton.new("Export List", self)
      @export_btn.clicked { export_layer_list }
      btn_layout.addWidget(@export_btn)
      
      @refresh_btn = RBA::QPushButton.new("Refresh", self)
      @refresh_btn.clicked { refresh_layers; update_display }
      btn_layout.addWidget(@refresh_btn)
      
      @close_btn = RBA::QPushButton.new("Close", self)
      @close_btn.clicked { self.accept }
      btn_layout.addWidget(@close_btn)
      
      main_layout.addLayout(btn_layout)
      
      # Status bar
      @status_label = RBA::QLabel.new("", self)
      @status_label.setStyleSheet("color: gray; font-style: italic;")
      main_layout.addWidget(@status_label)
    end

    def refresh_layers
      @layers = []
      @layer_list.clear
      @filtered_indices = []
      
      return unless @view && @view.cellview(0)
      
      save_visibility_state
      
      iter = @view.begin_layers
      while !iter.at_end?
        lp = iter.current
        if lp.valid?
          layer_info = {
            :iter => iter.dup,
            :layer_prop => lp,
            :source => lp.source,
            :name => lp.name.empty? ? "#{lp.source}" : lp.name,
            :layer => lp.source_layer,
            :datatype => lp.source_datatype
          }
          @layers << layer_info
          @filtered_indices << (@layers.length - 1)
        end
        iter.next
      end
      
      populate_layer_list
      
      max_val = [(@layers.length - 1), 0].max
      @layer_spin.setMaximum(max_val)
      @progress_bar.setMaximum(max_val)
      @status_label.text = "Found #{@layers.length} layers"
    end

    def populate_layer_list(filter_text = "")
      @layer_list.blockSignals(true)
      @layer_list.clear
      @filtered_indices = []
      
      filter_lower = filter_text.downcase
      @layers.each_with_index do |layer, i|
        display_name = "#{i}: #{layer[:name]} (#{layer[:layer]}/#{layer[:datatype]})"
        if filter_text.empty? || display_name.downcase.include?(filter_lower)
          @layer_list.addItem(display_name)
          @filtered_indices << i
        end
      end
      
      @layer_list.blockSignals(false)
    end

    def filter_layers(text)
      populate_layer_list(text)
    end

    def save_visibility_state
      @original_visibility = {}
      iter = @view.begin_layers
      index = 0
      while !iter.at_end?
        lp = iter.current
        @original_visibility[index] = lp.visible?
        iter.next
        index += 1
      end
    end

    def restore_visibility_state
      iter = @view.begin_layers
      index = 0
      while !iter.at_end?
        lp = iter.current
        if @original_visibility.key?(index)
          lp.visible = @original_visibility[index]
        end
        iter.next
        index += 1
      end
    end

    def update_display
      return if @layers.empty?
      
      layer = @layers[@current_layer_index]
      
      @layer_name_label.text = layer[:name]
      @layer_info_label.text = "Layer: #{layer[:layer]} / Datatype: #{layer[:datatype]}"
      
      shape_count = count_shapes(layer[:layer], layer[:datatype])
      @shape_count_label.text = "Shapes: #{shape_count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
      
      @progress_label.text = "Layer #{@current_layer_index + 1} of #{@layers.length}"
      @progress_bar.setValue(@current_layer_index)
      
      @layer_spin.blockSignals(true)
      @layer_spin.setValue(@current_layer_index)
      @layer_spin.blockSignals(false)
      
      select_list_item(@current_layer_index)
      
      if @isolate_mode
        isolate_current_layer
      end
      
      if @zoom_checkbox.isChecked
        zoom_to_layer
      end
      
      @status_label.text = "Layer #{@current_layer_index + 1} of #{@layers.length}"
    end

    def select_list_item(layer_index)
      @layer_list.blockSignals(true)
      list_row = @filtered_indices.index(layer_index)
      @layer_list.setCurrentRow(list_row) if list_row
      @layer_list.blockSignals(false)
    end

    def count_shapes(layer_num, datatype)
      return 0 unless @view && @view.cellview(0)
      
      cv = @view.cellview(0)
      layout = cv.layout
      cell = cv.cell
      
      return 0 unless cell
      
      layer_index = layout.find_layer(layer_num, datatype)
      return 0 if layer_index.nil? || !layout.is_valid_layer?(layer_index)
      
      count = 0
      cell.each_shape(layer_index) { count += 1 }
      count
    end

    def isolate_current_layer
      return if @layers.empty?
      
      # Hide all layers first
      iter = @view.begin_layers
      while !iter.at_end?
        lp = iter.current
        lp.visible = false
        iter.next
      end
      
      # Show current layer
      layer = @layers[@current_layer_index]
      layer[:layer_prop].visible = true
      
      # Also show all kept/pinned layers
      @kept_layers.each do |kept_idx|
        if kept_idx >= 0 && kept_idx < @layers.length
          @layers[kept_idx][:layer_prop].visible = true
        end
      end
    end

    def keep_current_layer
      return if @layers.empty?
      
      # Don't add duplicates
      unless @kept_layers.include?(@current_layer_index)
        @kept_layers << @current_layer_index
        update_kept_list
        
        layer = @layers[@current_layer_index]
        @status_label.text = "Kept layer: #{layer[:name]} (#{@kept_layers.length} pinned)"
      else
        @status_label.text = "Layer already kept"
      end
      
      # Make sure the kept layer is visible
      if @isolate_mode
        isolate_current_layer
      end
    end

    def clear_kept_layers
      @kept_layers = []
      update_kept_list
      @status_label.text = "Cleared all kept layers"
      
      # Update display to reflect changes
      if @isolate_mode
        isolate_current_layer
      end
    end

    def remove_kept_layer_by_item(item)
      row = @kept_list.row(item)
      return if row < 0 || row >= @kept_layers.length
      
      removed_idx = @kept_layers[row]
      @kept_layers.delete_at(row)
      update_kept_list
      
      if removed_idx < @layers.length
        layer = @layers[removed_idx]
        @status_label.text = "Removed kept layer: #{layer[:name]}"
      end
      
      # Update display
      if @isolate_mode
        isolate_current_layer
      end
    end

    def update_kept_list
      @kept_list.clear
      @kept_layers.each do |idx|
        if idx >= 0 && idx < @layers.length
          layer = @layers[idx]
          @kept_list.addItem("#{idx}: #{layer[:name]}")
        end
      end
    end

    def show_all_layers
      iter = @view.begin_layers
      while !iter.at_end?
        lp = iter.current
        lp.visible = true
        iter.next
      end
      @status_label.text = "All layers visible"
    end

    def zoom_to_layer
      return if @layers.empty?
      
      layer = @layers[@current_layer_index]
      cv = @view.cellview(0)
      return unless cv && cv.cell
      
      layout = cv.layout
      cell = cv.cell
      layer_index = layout.find_layer(layer[:layer], layer[:datatype])
      
      return if layer_index.nil? || !layout.is_valid_layer?(layer_index)
      
      bbox = cell.bbox_per_layer(layer_index)
      if bbox && !bbox.empty?
        @view.zoom_box(bbox.enlarged(bbox.width * 0.1, bbox.height * 0.1))
      end
    end

    def navigate_next
      return if @layers.empty?
      @current_layer_index = (@current_layer_index + 1) % @layers.length
      update_display
    end

    def navigate_prev
      return if @layers.empty?
      @current_layer_index = (@current_layer_index - 1) % @layers.length
      update_display
    end

    def jump_to_layer(index)
      return if @layers.empty? || index < 0 || index >= @layers.length
      @current_layer_index = index
      update_display
    end

    def select_layer_from_list(row)
      return if row < 0 || row >= @filtered_indices.length
      @current_layer_index = @filtered_indices[row]
      update_display
    end

    def toggle_isolate_mode(enabled)
      @isolate_mode = enabled
      if enabled
        isolate_current_layer
      else
        show_all_layers
      end
    end

    def export_layer_list
      return if @layers.empty?
      
      file_path = RBA::FileDialog.get_save_file_name(
        "Export Layer List",
        ".",
        "CSV files (*.csv);;Text files (*.txt);;All files (*)"
      )
      
      return if file_path.nil? || file_path.empty?
      
      begin
        File.open(file_path, 'w') do |f|
          f.puts "Index,Name,Layer,Datatype,Shapes"
          @layers.each_with_index do |layer, i|
            shape_count = count_shapes(layer[:layer], layer[:datatype])
            f.puts "#{i},\"#{layer[:name]}\",#{layer[:layer]},#{layer[:datatype]},#{shape_count}"
          end
        end
        @status_label.text = "Exported to #{file_path}"
      rescue => e
        RBA::MessageBox.critical("Export Error", e.message, RBA::MessageBox::Ok)
      end
    end

    def keyPressEvent(event)
      case event.key
      when RBA::Qt::Key_N
        navigate_next
      when RBA::Qt::Key_P
        navigate_prev
      when RBA::Qt::Key_K
        keep_current_layer
      when RBA::Qt::Key_C
        clear_kept_layers
      when RBA::Qt::Key_A
        show_all_layers
      when RBA::Qt::Key_I
        @isolate_checkbox.setChecked(!@isolate_checkbox.isChecked)
      when RBA::Qt::Key_Home
        jump_to_layer(0)
      when RBA::Qt::Key_End
        jump_to_layer(@layers.length - 1)
      else
        super(event)
      end
    end

    def closeEvent(event)
      super(event)
    end

  end

  # Plugin for toolbar integration
  class LayerBrowserPlugin < RBA::Plugin
    def initialize(view)
      super()
      @view = view
      @dialog = nil
    end

    def activated
      show_dialog
    end

    def deactivated
    end

    def show_dialog
      if @dialog.nil? || @dialog.destroyed?
        @dialog = LayerBrowserDialog.new(@view, RBA::Application.instance.main_window)
      end
      @dialog.show
      @dialog.raise
    end

    def mouse_click_event(p, buttons, prio)
      false
    end
  end

  # Plugin factory
  class LayerBrowserPluginFactory < RBA::PluginFactory
    def initialize
      super
      self.has_tool_entry = true
      self.register(-900, "layer_browser", "Layer Browser")
    end

    def create_plugin(manager, root, view)
      LayerBrowserPlugin.new(view)
    end
  end

  # Create factory instance
  LayerBrowserPluginFactory.new

  # Add menu action
  app = RBA::Application.instance
  mw = app.main_window
  menu = mw.menu
  
  unless menu.is_valid("tools_menu.layer_browser_action")
    action = RBA::Action.new
    action.title = "Layer Browser"
    action.shortcut = "Ctrl+Shift+L"
    action.on_triggered do
      view = mw.current_view
      if view
        dialog = LayerBrowserDialog.new(view, mw)
        dialog.exec
      else
        RBA::MessageBox.warning("No View", "Please open a layout first.", RBA::MessageBox::Ok)
      end
    end
    menu.insert_item("tools_menu.end", "layer_browser_action", action)
  end

end # LayerBrowser
end # KLayoutTools

$klayout_layer_browser_loaded = true
end # unless loaded

# Show dialog when run as macro
app = RBA::Application.instance
mw = app.main_window
view = mw.current_view

if view
  dialog = KLayoutTools::LayerBrowser::LayerBrowserDialog.new(view, mw)
  dialog.exec
else
  RBA::MessageBox.warning("No View", "Please open a layout first.", RBA::MessageBox::Ok)
end
