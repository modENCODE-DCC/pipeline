var Spinner = Class.create({
  initialize: function(image) {
    this.src = image;
    this.images = $H();
  },
  show: function(element) {
    var spinner_elem = this.images.get(element.identify());
    if (!spinner_elem) {
      spinner_elem = new Element("img", { 'src': this.src, 'alt': "/*/" });
      spinner_elem.setStyle({
        position: 'absolute',
        width: '16px',
        height: '16px',
        top: '0px',
        left: '0px',
        display: 'none',
        zIndex: -1
        });
      document.body.insert(spinner_elem, {position: 'bottom'});
      this.images.set(element.identify(), spinner_elem);
    }
    spinner_elem.clonePosition(element, { offsetLeft: 3, offsetTop: 3, setWidth: false, setHeight: false });
    spinner_elem.show();
  },
  hide: function(element) {
    var spinner_elem = this.images.get(element.identify());
    if (spinner_elem) {
      spinner_elem.hide();
    }
  }
});
Spinner.show = function(element) {
  if (!Spinner.defaultSpinner) {
    Spinner.defaultSpinner = new Spinner("/submit/images/ajax-loader.gif");
  }
  Spinner.defaultSpinner.show(element);
}
Spinner.hide = function(element) {
  if (!Spinner.defaultSpinner) {
    Spinner.defaultSpinner = new Spinner("/submit/images/ajax-loader.gif");
    return;
  }
  Spinner.defaultSpinner.hide(element);
}
