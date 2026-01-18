# encoding: UTF-8
# KLayout Cell Hierarchy Viewer
# 
# Explore the cell hierarchy of your design with instance counts
# and navigation capabilities.
# 
# Author: Adam Sbane
# License: MIT

unless $klayout_cell_hierarchy_loaded

module KLayoutTools
module CellHierarchy

  class CellHierarchyDialog < RBA::QDialog

    def initialize(view, parent = nil)
      super(parent)
      
      @view = view
      @cell_map = {}
      
      self.windowTitle = "Cell Hierarchy Viewer"
      self.setMinimumWidth(500)
      self.setMinimumHeight(600)
      
      setup_ui
      build_hierarchy
    end

    def setup_ui
      main_layout = RBA::QVBoxLayout.new(self)
      
      # Info
      @info_label = RBA::QLabel.new("", self)
      main_layout.addWidget(@info_label)
      
      # Search
      search_layout = RBA::QHBoxLayout.new
      search_layout.addWidget(RBA::QLabel.new("Search:", self))
      @search_edit = RBA::QLineEdit.new(self)
      @search_edit.setPlaceholderText("Filter cells by name...")
      @search_edit.textChanged { |t| filter_tree(t) }
      search_layout.addWidget(@search_edit)
      main_layout.addLayout(search_layout)
      
      # Tree view
      @tree = RBA::QTreeWidget.new(self)
      @tree.setHeaderLabels(["Cell Name", "Instances", "Direct Children"])
      @tree.setColumnWidth(0, 250)
      @tree.itemDoubleClicked { |item, col| goto_cell(item) }
      @tree.itemSelectionChanged { update_info }
      main_layout.addWidget(@tree)
      
      # Cell info group
      info_group = RBA::QGroupBox.new("Selected Cell Info", self)
      info_layout = RBA::QGridLayout.new(info_group)
      
      info_layout.addWidget(RBA::QLabel.new("Cell Name:", self), 0, 0)
      @cell_name_label = RBA::QLabel.new("", self)
      @cell_name_label.setStyleSheet("font-weight: bold;")
      info_layout.addWidget(@cell_name_label, 0, 1)
      
      info_layout.addWidget(RBA::QLabel.new("Bounding Box:", self), 1, 0)
      @bbox_label = RBA::QLabel.new("", self)
      info_layout.addWidget(@bbox_label, 1, 1)
      
      info_layout.addWidget(RBA::QLabel.new("Total Instances:", self), 2, 0)
      @instances_label = RBA::QLabel.new("", self)
      info_layout.addWidget(@instances_label, 2, 1)
      
      info_layout.addWidget(RBA::QLabel.new("Hierarchy Depth:", self), 3, 0)
      @depth_label = RBA::QLabel.new("", self)
      info_layout.addWidget(@depth_label, 3, 1)
      
      main_layout.addWidget(info_group)
      
      # Buttons
      btn_layout = RBA::QHBoxLayout.new
      
      @goto_btn = RBA::QPushButton.new("Go To Cell", self)
      @goto_btn.clicked { goto_selected_cell }
      btn_layout.addWidget(@goto_btn)
      
      @expand_btn = RBA::QPushButton.new("Expand All", self)
      @expand_btn.clicked { @tree.expandAll }
      btn_layout.addWidget(@expand_btn)
      
      @collapse_btn = RBA::QPushButton.new("Collapse All", self)
      @collapse_btn.clicked { @tree.collapseAll }
      btn_layout.addWidget(@collapse_btn)
      
      @export_btn = RBA::QPushButton.new("Export", self)
      @export_btn.clicked { export_hierarchy }
      btn_layout.addWidget(@export_btn)
      
      btn_layout.addStretch(1)
      
      @close_btn = RBA::QPushButton.new("Close", self)
      @close_btn.clicked { self.accept }
      btn_layout.addWidget(@close_btn)
      
      main_layout.addLayout(btn_layout)
    end

    def build_hierarchy
      @tree.clear
      @cell_map = {}
      
      return unless @view && @view.cellview(0)
      
      cv = @view.cellview(0)
      layout = cv.layout
      top_cell = cv.cell
      
      return unless top_cell
      
      # Count total cells
      total_cells = 0
      layout.each_cell { total_cells += 1 }
      
      @info_label.text = "Design: #{top_cell.name} | Total cells: #{total_cells}"
      
      # Build tree starting from top cell
      root_item = build_cell_item(top_cell, layout)
      @tree.addTopLevelItem(root_item)
      root_item.setExpanded(true)
    end

    def build_cell_item(cell, layout)
      item = RBA::QTreeWidgetItem.new
      item.setText(0, cell.name)
      
      # Count instances of this cell
      instance_count = 0
      layout.each_cell do |c|
        c.each_inst do |inst|
          if inst.cell.cell_index == cell.cell_index
            instance_count += 1
          end
        end
      end
      item.setText(1, instance_count.to_s)
      
      # Count direct children
      child_count = 0
      child_cells = {}
      cell.each_inst do |inst|
        child_cell = inst.cell
        child_cells[child_cell.cell_index] ||= 0
        child_cells[child_cell.cell_index] += 1
        child_count += 1
      end
      item.setText(2, child_cells.keys.length.to_s)
      
      # Store cell reference
      @cell_map[item] = cell
      
      # Add child cells (unique)
      child_cells.keys.each do |cell_index|
        child_cell = layout.cell(cell_index)
        child_item = build_cell_item(child_cell, layout)
        item.addChild(child_item)
      end
      
      item
    end

    def filter_tree(text)
      filter_lower = text.downcase
      
      def set_visibility(item, filter_text)
        visible = filter_text.empty? || item.text(0).downcase.include?(filter_text)
        
        # Check children
        child_visible = false
        (0...item.childCount).each do |i|
          if set_visibility(item.child(i), filter_text)
            child_visible = true
          end
        end
        
        visible = visible || child_visible
        item.setHidden(!visible)
        
        if visible && !filter_text.empty?
          item.setExpanded(true)
        end
        
        visible
      end
      
      (0...@tree.topLevelItemCount).each do |i|
        set_visibility(@tree.topLevelItem(i), filter_lower)
      end
    end

    def update_info
      items = @tree.selectedItems
      return if items.empty?
      
      item = items.first
      cell = @cell_map[item]
      return unless cell
      
      cv = @view.cellview(0)
      layout = cv.layout
      dbu = layout.dbu
      
      @cell_name_label.text = cell.name
      
      bbox = cell.bbox
      if bbox && !bbox.empty?
        w = bbox.width * dbu
        h = bbox.height * dbu
        @bbox_label.text = "#{sprintf('%.3f', w)} x #{sprintf('%.3f', h)} um"
      else
        @bbox_label.text = "Empty"
      end
      
      # Count total instances
      instance_count = 0
      layout.each_cell do |c|
        c.each_inst do |inst|
          if inst.cell.cell_index == cell.cell_index
            instance_count += 1
          end
        end
      end
      @instances_label.text = instance_count.to_s
      
      # Calculate hierarchy depth
      depth = calculate_depth(cell)
      @depth_label.text = depth.to_s
    end

    def calculate_depth(cell, visited = {})
      return 0 if visited[cell.cell_index]
      visited[cell.cell_index] = true
      
      max_child_depth = 0
      cell.each_inst do |inst|
        child_depth = calculate_depth(inst.cell, visited.dup)
        max_child_depth = [max_child_depth, child_depth].max
      end
      
      max_child_depth + 1
    end

    def goto_selected_cell
      items = @tree.selectedItems
      return if items.empty?
      goto_cell(items.first)
    end

    def goto_cell(item)
      cell = @cell_map[item]
      return unless cell
      
      cv = @view.cellview(0)
      layout = cv.layout
      
      # Zoom to cell bbox
      bbox = cell.bbox
      if bbox && !bbox.empty?
        @view.zoom_box(bbox.enlarged(bbox.width * 0.1, bbox.height * 0.1))
      end
    end

    def export_hierarchy
      file_path = RBA::FileDialog.get_save_file_name(
        "Export Cell Hierarchy",
        ".",
        "Text files (*.txt);;CSV files (*.csv);;All files (*)"
      )
      
      return if file_path.nil? || file_path.empty?
      
      begin
        File.open(file_path, 'w') do |f|
          f.puts "Cell Hierarchy Export"
          f.puts "=" * 50
          f.puts ""
          
          def write_item(f, item, indent = 0)
            prefix = "  " * indent
            f.puts "#{prefix}#{item.text(0)} (instances: #{item.text(1)}, children: #{item.text(2)})"
            (0...item.childCount).each do |i|
              write_item(f, item.child(i), indent + 1)
            end
          end
          
          (0...@tree.topLevelItemCount).each do |i|
            write_item(f, @tree.topLevelItem(i))
          end
        end
        RBA::MessageBox.info("Export Complete", "Hierarchy exported to #{file_path}", RBA::MessageBox::Ok)
      rescue => e
        RBA::MessageBox.critical("Export Error", e.message, RBA::MessageBox::Ok)
      end
    end

  end

  # Add menu action
  app = RBA::Application.instance
  mw = app.main_window
  menu = mw.menu
  
  unless menu.is_valid("tools_menu.cell_hierarchy_action")
    action = RBA::Action.new
    action.title = "Cell Hierarchy"
    action.shortcut = "Ctrl+Shift+H"
    action.on_triggered do
      view = mw.current_view
      if view
        dialog = CellHierarchyDialog.new(view, mw)
        dialog.exec
      else
        RBA::MessageBox.warning("No View", "Please open a layout first.", RBA::MessageBox::Ok)
      end
    end
    menu.insert_item("tools_menu.end", "cell_hierarchy_action", action)
  end

end # CellHierarchy
end # KLayoutTools

$klayout_cell_hierarchy_loaded = true
end # unless loaded

# Show dialog when run as macro
app = RBA::Application.instance
mw = app.main_window
view = mw.current_view

if view
  dialog = KLayoutTools::CellHierarchy::CellHierarchyDialog.new(view, mw)
  dialog.exec
else
  RBA::MessageBox.warning("No View", "Please open a layout first.", RBA::MessageBox::Ok)
end
