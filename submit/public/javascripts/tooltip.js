var Tooltip = Class.create({
    initialize: function(element, textOrCallback, tooltipDiv, options) {
      this.elements = $A();
      this.options = $H(options);
      this.content = textOrCallback;
      this.showTimer = undefined;
      this.hideTimer = undefined;
      this.showTimeout = 500;
      this.hideTimeout = 2000;
      if (tooltipDiv && tooltipDiv.update) {
        this.tooltipDiv = tooltipDiv;
        this.tooltipDiv.setStyle({
          position: 'absolute',
          display: 'none',
          backgroundColor: '#FFFFDD',
          padding: '4px',
          border: 'thin solid black',
          zIndex: 1001
        });
      } else {
        this.tooltipDiv = new Element('div');
        this.tooltipDiv.setStyle({
          position: 'absolute',
          display: 'none',
          backgroundColor: '#FFFFDD',
          padding: '4px',
          border: 'thin solid black',
          zIndex: 1001
        });
        document.body.insert(this.tooltipDiv);
      }
      if (element) {
        this.addElement(element);
      }
    },
    addElement: function(element) {
      element.observe('mouseover', this.showTooltip.bind(this));
      element.observe('mouseout', this.hideTooltip.bind(this));
      element.observe('mousemove', this.resetTooltip.bind(this));
      this.elements.push(element);
    },
    showTooltip: function(e, temp_content) {
      if (!temp_content) { temp_content = this.content; }
      var dims = e.element().getDimensions();
      this.cancelTooltip();
      this.showTimer = setTimeout(function() {
          var width = dims.width; var height = dims.height;
          if (this.options.get('usecursor')) {
            this.tooltipDiv.setStyle({
              left:  "" + (e.pointerX()+10) + "px",
              top: "" + (e.pointerY()+10) + "px"
            });
          } else {
            if (this.options.get('scalex')) { width *= this.options.get('scalex'); }
            if (this.options.get('scaley')) { height *= this.options.get('scaley'); }
            this.tooltipDiv.clonePosition(e.element(), { offsetLeft: width, offsetTop: height, setWidth: false, setHeight: false });
          }
          if (typeof(temp_content) == 'function') {
            this.tooltipDiv.update(temp_content(e));
          } else {
            this.tooltipDiv.update(temp_content);
          }
          this.tooltipDiv.setStyle({ display: 'block' });
          this.hideTimer = setTimeout(function() {
            this.hideTooltip();
          }.bind(this), this.hideTimeout);
        }.bind(this), this.showTimeout);
    },
    hideTooltip: function() {
      this.cancelTooltip();
      this.tooltipDiv.setStyle({ display: 'none' });
    },
    resetTooltip: function(e) {
      this.cancelTooltip(e);
      this.showTooltip(e);
    },
    cancelTooltip: function() {
      if (this.showTimer) { clearTimeout(this.showTimer); }
      if (this.hideTimer) { clearTimeout(this.hideTimer); }
    }
});



