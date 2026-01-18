# encoding: UTF-8
# KLayout GDS Compare
# 
# Visual comparison between two GDS files using XOR operation.
# Highlights differences between designs.
# 
# Author: Adam Sbane
# License: MIT

unless $klayout_gds_compare_loaded

module KLayoutTools
module GDSCompare

  class GDSCompareDialog < RBA::QDialog

    def initialize(parent = nil)
      super(parent)
      
      @layout1 = nil
      @layout2 = nil
      @result_layout = nil
      
      self.windowTitle = "GDS Compare"
      self.setMinimumWidth(500)
      self.setMinimumHeight(400)
      
      setup_ui
    end

    def setup_ui
      main_layout = RBA::QVBoxLayout.new(self)
      
      # File selection
      files_group = RBA::QGroupBox.new("Files to Compare", self)
      files_layout = RBA::QGridLayout.new(files_group)
      
      files_layout.addWidget(RBA::QLabel.new("File 1 (Reference):", self), 0, 0)
      @file1_edit = RBA::QLineEdit.new(self)
      @file1_edit.setReadOnly(true)
      files_layout.addWidget(@file1_edit, 0, 1)
      @browse1_btn = RBA::QPushButton.new("Browse...", self)
      @browse1_btn.clicked { browse_file1 }
      files_layout.addWidget(@browse1_btn, 0, 2)
      
      files_layout.addWidget(RBA::QLabel.new("File 2 (Compare):", self), 1, 0)
      @file2_edit = RBA::QLineEdit.new(self)
      @file2_edit.setReadOnly(true)
      files_layout.addWidget(@file2_edit, 1, 1)
      @browse2_btn = RBA::QPushButton.new("Browse...", self)
      @browse2_btn.clicked { browse_file2 }
      files_layout.addWidget(@browse2_btn, 1, 2)
      
      main_layout.addWidget(files_group)
      
      # Options
      options_group = RBA::QGroupBox.new("Options", self)
      options_layout = RBA::QVBoxLayout.new(options_group)
      
      @all_layers_checkbox = RBA::QCheckBox.new("Compare all layers", self)
      @all_layers_checkbox.setChecked(true)
      options_layout.addWidget(@all_layers_checkbox)
      
      @flatten_checkbox = RBA::QCheckBox.new("Flatten before compare", self)
      @flatten_checkbox.setChecked(false)
      options_layout.addWidget(@flatten_checkbox)
      
      cell_layout = RBA::QHBoxLayout.new
      cell_layout.addWidget(RBA::QLabel.new("Top cell (empty for auto):", self))
      @cell_edit = RBA::QLineEdit.new(self)
      cell_layout.addWidget(@cell_edit)
      options_layout.addLayout(cell_layout)
      
      main_layout.addWidget(options_group)
      
      # Progress
      @progress_label = RBA::QLabel.new("", self)
      main_layout.addWidget(@progress_label)
      
      @progress_bar = RBA::QProgressBar.new(self)
      @progress_bar.setVisible(false)
      main_layout.addWidget(@progress_bar)
      
      # Results
      results_group = RBA::QGroupBox.new("Results", self)
      results_layout = RBA::QVBoxLayout.new(results_group)
      
      @results_text = RBA::QTextEdit.new(self)
      @results_text.setReadOnly(true)
      @results_text.setMinimumHeight(150)
      results_layout.addWidget(@results_text)
      
      main_layout.addWidget(results_group)
      
      # Buttons
      btn_layout = RBA::QHBoxLayout.new
      
      @compare_btn = RBA::QPushButton.new("Compare", self)
      @compare_btn.clicked { run_compare }
      btn_layout.addWidget(@compare_btn)
      
      @view_btn = RBA::QPushButton.new("View Result", self)
      @view_btn.clicked { view_result }
      @view_btn.setEnabled(false)
      btn_layout.addWidget(@view_btn)
      
      @export_btn = RBA::QPushButton.new("Export Report", self)
      @export_btn.clicked { export_report }
      @export_btn.setEnabled(false)
      btn_layout.addWidget(@export_btn)
      
      btn_layout.addStretch(1)
      
      @close_btn = RBA::QPushButton.new("Close", self)
      @close_btn.clicked { self.accept }
      btn_layout.addWidget(@close_btn)
      
      main_layout.addLayout(btn_layout)
    end

    def browse_file1
      file = RBA::FileDialog.get_open_file_name(
        "Select Reference GDS",
        ".",
        "GDS files (*.gds *.gds2 *.GDS);;OASIS files (*.oas *.oasis);;All files (*)"
      )
      @file1_edit.text = file if file && !file.empty?
    end

    def browse_file2
      file = RBA::FileDialog.get_open_file_name(
        "Select Compare GDS",
        ".",
        "GDS files (*.gds *.gds2 *.GDS);;OASIS files (*.oas *.oasis);;All files (*)"
      )
      @file2_edit.text = file if file && !file.empty?
    end

    def run_compare
      file1 = @file1_edit.text
      file2 = @file2_edit.text
      
      if file1.empty? || file2.empty?
        RBA::MessageBox.warning("Missing Files", "Please select both files to compare.", RBA::MessageBox::Ok)
        return
      end
      
      unless File.exist?(file1)
        RBA::MessageBox.warning("File Not Found", "Reference file not found: #{file1}", RBA::MessageBox::Ok)
        return
      end
      
      unless File.exist?(file2)
        RBA::MessageBox.warning("File Not Found", "Compare file not found: #{file2}", RBA::MessageBox::Ok)
        return
      end
      
      @progress_label.text = "Loading files..."
      @progress_bar.setVisible(true)
      @progress_bar.setValue(10)
      @results_text.clear
      
      begin
        # Load layouts
        @layout1 = RBA::Layout.new
        @layout1.read(file1)
        @progress_bar.setValue(30)
        
        @layout2 = RBA::Layout.new
        @layout2.read(file2)
        @progress_bar.setValue(50)
        
        # Get top cells
        top_cell_name = @cell_edit.text
        
        if top_cell_name.empty?
          top1 = @layout1.top_cell
          top2 = @layout2.top_cell
        else
          top1 = @layout1.cell(top_cell_name)
          top2 = @layout2.cell(top_cell_name)
        end
        
        unless top1 && top2
          RBA::MessageBox.warning("Cell Not Found", "Could not find matching top cells.", RBA::MessageBox::Ok)
          return
        end
        
        @progress_label.text = "Comparing layouts..."
        @progress_bar.setValue(60)
        
        # Create result layout
        @result_layout = RBA::Layout.new
        @result_layout.dbu = @layout1.dbu
        result_top = @result_layout.create_cell("XOR_RESULT")
        
        # Flatten if requested
        if @flatten_checkbox.isChecked
          top1.flatten(true)
          top2.flatten(true)
        end
        
        # Perform XOR on each layer
        results = []
        total_diff_shapes = 0
        
        layers1 = []
        @layout1.layer_indices.each { |li| layers1 << @layout1.get_info(li) }
        
        layers1.each_with_index do |layer_info, idx|
          layer_num = layer_info.layer
          datatype = layer_info.datatype
          
          li1 = @layout1.find_layer(layer_num, datatype)
          li2 = @layout2.find_layer(layer_num, datatype)
          
          next unless li1
          
          # Get regions
          region1 = RBA::Region.new(top1.begin_shapes_rec(li1))
          
          if li2
            region2 = RBA::Region.new(top2.begin_shapes_rec(li2))
          else
            region2 = RBA::Region.new
          end
          
          # XOR operation
          xor_result = region1 ^ region2
          
          if !xor_result.is_empty?
            # Add to result layout
            result_li = @result_layout.layer(layer_num, datatype)
            result_top.shapes(result_li).insert(xor_result)
            
            diff_count = 0
            xor_result.each { diff_count += 1 }
            total_diff_shapes += diff_count
            
            results << {
              :layer => layer_num,
              :datatype => datatype,
              :diff_count => diff_count
            }
          end
        end
        
        @progress_bar.setValue(90)
        
        # Check for layers only in layout2
        @layout2.layer_indices.each do |li|
          layer_info = @layout2.get_info(li)
          unless @layout1.find_layer(layer_info.layer, layer_info.datatype)
            region2 = RBA::Region.new(top2.begin_shapes_rec(li))
            unless region2.is_empty?
              result_li = @result_layout.layer(layer_info.layer, layer_info.datatype)
              result_top.shapes(result_li).insert(region2)
              
              diff_count = 0
              region2.each { diff_count += 1 }
              total_diff_shapes += diff_count
              
              results << {
                :layer => layer_info.layer,
                :datatype => layer_info.datatype,
                :diff_count => diff_count,
                :note => "Only in file 2"
              }
            end
          end
        end
        
        @progress_bar.setValue(100)
        
        # Display results
        report = "GDS Compare Results\n"
        report += "=" * 50 + "\n\n"
        report += "File 1: #{file1}\n"
        report += "File 2: #{file2}\n\n"
        
        if results.empty?
          report += "No differences found! Files are identical.\n"
        else
          report += "Differences found on #{results.length} layers:\n\n"
          results.each do |r|
            note = r[:note] ? " (#{r[:note]})" : ""
            report += "  Layer #{r[:layer]}/#{r[:datatype]}: #{r[:diff_count]} differences#{note}\n"
          end
          report += "\nTotal difference shapes: #{total_diff_shapes}\n"
        end
        
        @results_text.setText(report)
        @progress_label.text = "Compare complete."
        
        @view_btn.setEnabled(!results.empty?)
        @export_btn.setEnabled(true)
        
      rescue => e
        RBA::MessageBox.critical("Compare Error", e.message, RBA::MessageBox::Ok)
        @progress_label.text = "Error: #{e.message}"
      ensure
        @progress_bar.setVisible(false)
      end
    end

    def view_result
      return unless @result_layout
      
      # Save to temp file and open
      temp_file = File.join(Dir.tmpdir, "gds_compare_result.gds")
      @result_layout.write(temp_file)
      
      mw = RBA::MainWindow.instance
      mw.load_layout(temp_file, 1)
      
      RBA::MessageBox.info("View Result", 
        "XOR result loaded in new view.\n\n" +
        "Shapes shown are differences between the two files.",
        RBA::MessageBox::Ok)
    end

    def export_report
      file_path = RBA::FileDialog.get_save_file_name(
        "Export Compare Report",
        ".",
        "Text files (*.txt);;All files (*)"
      )
      
      return if file_path.nil? || file_path.empty?
      
      begin
        File.open(file_path, 'w') do |f|
          f.puts @results_text.toPlainText
        end
        RBA::MessageBox.info("Export Complete", "Report exported to #{file_path}", RBA::MessageBox::Ok)
      rescue => e
        RBA::MessageBox.critical("Export Error", e.message, RBA::MessageBox::Ok)
      end
    end

  end

  # Add menu action
  app = RBA::Application.instance
  mw = app.main_window
  menu = mw.menu
  
  unless menu.is_valid("tools_menu.gds_compare_action")
    action = RBA::Action.new
    action.title = "GDS Compare"
    action.shortcut = "Ctrl+Shift+C"
    action.on_triggered do
      dialog = GDSCompareDialog.new(mw)
      dialog.exec
    end
    menu.insert_item("tools_menu.end", "gds_compare_action", action)
  end

end # GDSCompare
end # KLayoutTools

$klayout_gds_compare_loaded = true
end # unless loaded

# Show dialog when run as macro
app = RBA::Application.instance
mw = app.main_window
dialog = KLayoutTools::GDSCompare::GDSCompareDialog.new(mw)
dialog.exec
