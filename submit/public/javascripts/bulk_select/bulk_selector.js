var BulkSelector = Class.create({
    initialize: function(target_div, selection_callback) {
      this.targetDiv = target_div;
      this.toggleCheckboxDragging = 0;
      this.selectionCallback = selection_callback;
      this.checkedColor = "#000000";
      this.loadHandler = function(evt) {
          this.targetDiv = $(this.targetDiv);
          this.clearCheckboxes(this.targetDiv);
          $$('DIV#' + this.targetDiv.identify() + ' DIV.row DIV:not(:first-child)').each(function(cell) {
            cell.observe('mouseover', this.showCrosshairs.bind(this));
            cell.observe('mouseout', this.hideCrosshairs.bind(this));
            cell.observe('mousedown', this.toggleCheckboxDragStart.bind(this));
            cell.observe('mouseover', this.toggleCheckboxDragContinue.bind(this));
            }, this);
          $$('DIV#' + this.targetDiv.identify() + ' DIV.row DIV:first-child').each(function(row_header) {
            row_header.observe('click', this.toggleCheckboxRow.bind(this));
            }, this);
          $$('DIV#' + this.targetDiv.identify() + ' DIV.bulk_header DIV').each(function(column_header) {
            column_header.observe('click', this.toggleCheckboxColumn.bind(this));
            }, this);
          document.observe('mouseup', this.toggleCheckboxDragStop.bind(this));
        }.bind(this);
      
      if (!window.loaded) {
        Event.observe(window, 'load', this.loadHandler);
      }
    },
    showCrosshairs: function(evt) {
      var brightening = 40;
      var cell = evt.findElement('DIV');
      var column = cell.previousSiblings().size();
      var row = 0;
      var prev = cell.up('div');
      while (prev) { row++; prev = prev.previous('DIV.row') }

      // Highlight cell
      cell.addClassName('crosshairs');
      cell.setStyle({ 'backgroundColor': new RGBColor(cell.getStyle('backgroundColor')).brighten(brightening).toHex() });

      // Highlight column header
      var c = cell.up('DIV.row').previous('DIV.bulk_header').down('DIV:nth-child(' + column + ') SPAN');
      var brighter = new RGBColor(c.getStyle('backgroundColor')).brighten(brightening).toHex();
      c.addClassName('crosshairs');
      c.setStyle({ 'backgroundColor': brighter });
      c.up('DIV').addClassName('crosshairs');
      c.up('DIV').setStyle({ 'backgroundColor': brighter });

      // Highlight row header
      c = cell.previous('DIV.row DIV:first-child');
      c.addClassName('crosshairs');
      c.setStyle({ 'backgroundColor': new RGBColor(c.getStyle('backgroundColor')).brighten(brightening).toHex() });

      // Highlight current row
      cell.up('DIV.row').select('DIV:not(:first-child)').each(function(c) { 
          if (c != cell) {
            c.addClassName('crosshairs');
            c.setStyle({ 'backgroundColor': new RGBColor(c.getStyle('backgroundColor')).brighten(brightening).toHex() });
          }
        });
      // Highlight current column
      cell.up('DIV.row').up().select('DIV.row').each(function(col) {
        var c = col.down('DIV:nth-child(' + (column+1) + ')');
            if (c != cell) {
              c.addClassName('crosshairs');
              c.setStyle({ 'backgroundColor': new RGBColor(c.getStyle('backgroundColor')).brighten(brightening).toHex() });
            }
        });
      cell.addClassName('crosshairs');
    },
    hideCrosshairs: function(evt) {
      $$('.crosshairs').each(function(cell) {
          if (cell.hasClassName('checked')) {
            cell.setStyle({ 'backgroundColor': this.checkedColor });
          } else {
            cell.setStyle({ 'backgroundColor': '' });
          }
          cell.removeClassName('crosshairs');
          }, this);
    },
    toggleCheckbox: function(evt, force_direction, skip_update_list) {
      var cell;
      if (evt.findElement) {
        cell = evt.findElement('DIV');
      } else {
        cell = evt;
      }
      var checkbox = cell.down('INPUT');
      if (force_direction != undefined) {
        checkbox.checked = (force_direction == true ? true : false);
      } else {
        checkbox.checked = (checkbox.checked == true ? false : true);
      }
      if (checkbox.checked) {
        cell.addClassName('checked');
        cell.setStyle({ 'backgroundColor': this.checkedColor });
      } else {
        cell.removeClassName('checked');
        cell.setStyle({ 'backgroundColor': '' });
      }
      if (!skip_update_list) {
        this.updateCheckedSubmissions(cell.up('DIV').up('DIV'));
      }
      return checkbox.checked;
    },
    toggleCheckboxDragStart: function(evt) {
      var res = this.toggleCheckbox(evt);
      if (res) {
        // Set all checked
        this.toggleCheckboxDragging = 1;
      } else {
        // Set all unchecked
        this.toggleCheckboxDragging = 2;
      }
      evt.stop();
    },
    toggleCheckboxDragContinue: function(evt) {
      if (this.toggleCheckboxDragging) {
        var force_direction = (this.toggleCheckboxDragging == 1 ? true : false);
        this.toggleCheckbox(evt, force_direction);
      }
      evt.stop();
    },
    toggleCheckboxDragStop: function(evt) {
      this.toggleCheckboxDragging = false;
      evt.stop();
    },
    toggleCheckboxRow: function(evt) {
      var row_header = evt.findElement('DIV');
      var cells = row_header.up().select('DIV:not(:first-child)');
      var force_direction = true;
      if (cells.find(function(cell) { return cell.down("INPUT").checked; })) {
        force_direction = false;
      }
      cells.each(function(cell) {
          this.toggleCheckbox(cell, force_direction, true);
          }, this);
      this.updateCheckedSubmissions(row_header.up('DIV').up('DIV'));
    },
    toggleCheckboxColumn: function(evt) {
      var column_header = evt.findElement('DIV');
      var column = column_header.previousSiblings().size();
      var cells = column_header.up("DIV.bulk_header").up().select("DIV.row DIV:nth-child(" + (column+2) + ")");
      var force_direction = true;
      if (cells.find(function(cell) { return cell.down("INPUT").checked; })) {
        force_direction = false;
      }
      cells.each(function(cell) {
          this.toggleCheckbox(cell, force_direction, true);
          }, this);
      this.updateCheckedSubmissions(column_header.up('DIV').up('DIV'));
    },
    clearCheckboxes: function(bulk_section) {
      bulk_section.select('DIV.row INPUT').each(function(checkbox) {
          checkbox.checked = false;
          }, this);
      // TODO: Clear colors too?
      this.updateCheckedSubmissions(bulk_section);
    },
    eachColHeader: function(callback) {
      $$('DIV#' + this.targetDiv.identify() + ' DIV.bulk_header DIV').each(function(header) {
          callback(header);
      });
    },
    eachRowHeader: function(callback) {
      $$('DIV#' + this.targetDiv.identify() + ' DIV.row DIV:first-child').each(function(header) {
          callback(header);
      });
    },
    eachCell: function(callback) {
      $$('DIV#' + this.targetDiv.identify() + ' DIV.row DIV:not(:first-child)').each(function(header) {
          callback(header);
      });
    },
    updateCheckedSubmissions: function(bulk_section) {
      bulk_section = $(bulk_section); // Make sure it's an element
      if (!this.selectionCallback) { return; }

      var list = $(bulk_section).select("DIV.row DIV.checked INPUT").map(function(checkbox) { return checkbox.getValue().split(/,\s*/); }).flatten().uniq().compact().without("");
      if (this.selectionCallback.update) {
        this.selectionCallback.update(list);
      } else {
        this.selectionCallback(list);
      }
    }
});


var MatrixDefiner = Class.create({
    initialize: function(sample_div, inputs_hash) {
      this.sampleDiv = $(sample_div);
      this.updatingConstraints = false;

      if (Object.isHash(inputs_hash)) {
        this.rowsInput = $(inputs_hash.get('rows'));
        this.colsInput = $(inputs_hash.get('cols'));
        this.splitByInput = $(inputs_hash.get('split_by'));
        this.groupByInput = $(inputs_hash.get('group_by'));
        this.showAttrsInput = $(inputs_hash.get('show_attrs'));
      } else {
        this.rowsInput = $('rows');
        this.colsInput = $('cols');
        this.splitByInput = $('split_by');
        this.groupByInput = $('group_by');
        this.showAttrsInput = $('show_attrs');
      }

      $A([ this.rowsInput, this.colsInput, this.splitByInput, this.groupByInput, this.showAttrsInput ]).each(function(elem) {
        if (elem) {
          elem.observe('change', this.updateFormConstraints.bind(this));
        }
      }, this);
      $A([ this.rowsInput, this.colsInput, this.splitByInput, this.groupByInput, this.showAttrsInput ]).each(function(elem) {
          if (elem) {
            this.updateFormConstraints(elem);
          }
        }, this);
    },
    showSampleMatrix: function() {
      if (!this.sampleDiv || !this.colsInput || !this.rowsInput) { return; }

      var cols = this.colsInput.getValue();
      var rows = this.rowsInput.getValue();

      var split_tables = new Element('span');
      var num_split = (this.splitByInput && this.splitByInput.getValue()) ? 2 : 1;
      this.sampleDiv.update();
      for (var spliti = 0; spliti < num_split; spliti++) {
        var table = new Element('table', { border: 1});
        var header = new Element('tr').update(new Element('td').update("&nbsp;"));
        var group_by = [ null ];
        if (this.groupByInput && this.groupByInput.getValue()) {
          group_by = [ this.groupByInput.getValue() + "1", this.groupByInput.getValue() + "2" ];
          group_row = new Element("tr").update(new Element('td').update("&nbsp;"));
          group_by.each(function(g) {
            group_row.appendChild(new Element("th", { colspan: Math.pow(2, cols.size()) }).update(g));
            });
            table.appendChild(group_row);
        }
        for (var g = 0; g < group_by.size(); g++) {
          for (var i = 0; i < Math.pow(2, cols.size()); i++) {
            cell = new Element('td');
            out = cols[0] + ((i&1)+1);
            for (var j = 1; j < cols.size(); j++) {
              out = cols[j] + (((i>>j)&1)+1) + ", " + out;
            }
            cell.update(out);
            header.appendChild(cell);
          }
        }
        table.appendChild(header);

        cellContent = 'X';
        attrs = this.showAttrsInput ? this.showAttrsInput.getValue().without("") : $A();
        if (attrs.size() > 0) {
          cellContent += " (" + attrs.join(", ") + ")";
        }
        for (var i = 0; i < Math.pow(2, rows.size()); i++) {
          cell = new Element('td');
          out = rows[0] + ((i&1)+1);
          for (var j = 1; j < rows.size(); j++) {
            out = rows[j] + (((i>>j)&1)+1) + ", " + out;
          }
          cell.update(out);
          row = new Element('tr').update(cell);
          for (var k = 0; k < Math.pow(2, cols.size())*group_by.size(); k++) {
            row.appendChild(new Element('td').update(cellContent));
          }
          table.appendChild(row);
        }
        if (num_split > 1) { this.sampleDiv.appendChild(new Element('b').update($('split_by').getValue() + (spliti+1))) };
        this.sampleDiv.appendChild(table);
      }
    },
    updateFormConstraints: function(evt) {
      var changed_elem;
      if (Object.isElement(evt)) {
        changed_elem = evt;
      } else {
        changed_elem = evt.findElement('select');
      }
      if (!changed_elem || this.updatingConstraints) { return; }
      this.updatingConstraints = true;

      first_update = [ this.splitByInput, this.rowsInput, this.colsInput, this.groupByInput, this.showAttrsInput ];
      selected_vals = changed_elem.getValue() || [];
      enabled_vals = changed_elem.childElements().findAll( function(e) { return e.disabled == false; } ).map( function(e) { return e.value; } ) || [];

      first_update = first_update.without(changed_elem);
      first_update.each(function (element) {
          if (element) {
            element.childElements().each( function (e) {
              if (e.value != "" && selected_vals.include(e.value)) { e.disabled = true; if (e.selected) { e.selected = false; } }
              else if (enabled_vals.include(e.value)) { e.disabled = false; }
            });
          }
        });
      default_none = [ this.splitByInput, this.groupByInput, this.showAttrsInput ];
      default_none.each(function (element) {
          if (element && !element.getValue()) {
            element.childElements().find ( function(e) { return e.value == "" } ).selected = true;
          }
        });
          
      var notOkayToDrawSample = ($('cols').getValue().size() == 0 || $('rows').getValue().size() == 0);
      this.updatingConstraints = false;
      if (!notOkayToDrawSample) {
        this.showSampleMatrix();
      }
    }
});
