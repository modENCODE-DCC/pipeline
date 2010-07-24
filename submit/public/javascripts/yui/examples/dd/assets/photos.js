YUI(yuiConfig).use('gallery-yql', 'node', 'anim', 'dd', 'slider', 'stylesheet', 'event-delegate', function(Y) {
    //Get a reference to the wrapper to use later and add a loading class to it.
    var wrapper = Y.one('#yui-main .yui-g ul').addClass('loading');
    //Set it's height to the height of the viewport so we can scroll it.
    wrapper.setStyle('height', (wrapper.get('winHeight') - 50 )+ 'px');
    Y.on('windowresize', function() { wrapper.setStyle('height', (wrapper.get('winHeight') - 50 )+ 'px'); });
    //Make the YQL query.
    //new Y.yql('select * from flickr.photos.search(100) where text="openhacklondon" and safe_search = 1 and media = "photos" and extras = "o_dims" and ((o_width = "1600" and o_height = "1200") or (o_width = "1200" and o_height = "1600") or (o_width = "800" and o_height = "600") or (o_width = "600" and o_height = "800"))', function(e) {
    new Y.yql('SELECT * FROM flickr.photos.search(100) WHERE (text="yuiconf") AND (safe_search = 1) AND (media = "photos")', function(e) {
        if (e.query) {
            var photos = e.query.results.photo;
            //Walk the returned photos array
            Y.each(photos, function(v, k) {
                //Create our URL
                var url = 'http:/'+'/static.flickr.com/' + v.server + '/' + v.id + '_' + v.secret + '_m.jpg',
                    //Create the image and the LI
                    li = Y.Node.create('<li class="loading"><img src="' + url + '" title="' + v.title + '"></li>'),
                    //Get the image from the LI
                    img = li.get('firstChild');
                //Append the li to the wrapper
                wrapper.appendChild(li);
                //This little hack moves the tall images to the bottom of the list
                //So they float better ;)
                img.on('load', function() {
                    //Is the height longer than the width?
                    var c = ((this.get('height') > this.get('width')) ? 'tall' : 'wide');
                    this.addClass(c);
                    if (c === 'tall') {
                        //Move it to the end of the list.
                        this.get('parentNode.parentNode').removeChild(this.get('parentNode'));
                        wrapper.appendChild(this.get('parentNode'));
                    }
                    this.get('parentNode').removeClass('loading');
                });
            });
            //Get all the newly added li's
            wrapper.all('li').each(function(node) {
                //Plugin the Drag plugin
                this.plug(Y.Plugin.Drag, {
                    offsetNode: false
                });
                //Plug the Proxy into the DD object
                this.dd.plug(Y.Plugin.DDProxy, {
                    resizeFrame: false,
                    moveOnEnd: false,
                    borderStyle: 'none'
                });
            });
            //Create and render the slider
            var sl = new Y.Slider({
                length: '200px', value: 40, max: 70, min: 5
            }).render('.horiz_slider');
            //Listen for the change
            sl.after('valueChange',function (e) {
                //Insert a dynamic stylesheet rule:
                var sheet = new Y.StyleSheet('image_slider');
                sheet.set('#yui-main .yui-g ul li', {
                    width: (e.newVal / 2) + '%'
                });
            });
            //Remove the DDM as a bubble target..
            sl._dd.removeTarget(Y.DD.DDM);
            //Remove the wrappers loading class
            wrapper.removeClass('loading');
            Y.one('#ft').removeClass('loading');
        }
    });
    //Listen for all mouseup's on the document (selecting/deselecting images)
    Y.delegate('mouseup', function(e) {
        if (!e.shiftKey) {
            //No shift key - remove all selected images
            wrapper.all('img.selected').removeClass('selected');
        }
        //Check if the target is an image and select it.
        if (e.target.test('#yui-main .yui-g ul li img')) {
            e.target.addClass('selected');
        }
    }, document, '*');

    //Listen for all clicks on the '#photoList li' selector
    Y.delegate('click', function(e) {
        //Prevent the click
        e.halt();
        //Remove all the selected items
        e.currentTarget.get('parentNode').all('li.selected').removeClass('selected');
        //Add the selected class to the one that one clicked
        e.currentTarget.addClass('selected');
        //The "All Photos" link was clicked
        if (e.currentTarget.hasClass('all')) {
            //Remove all the hidden classes
            wrapper.all('li').removeClass('hidden');
        } else {
            //Another "album" was clicked, get it's id
            var c = e.currentTarget.get('id');
            //Hide all items by adding the hidden class
            wrapper.all('li').addClass('hidden');
            //Now, find all the items with the class name the same as the album id
            //and remove the hidden class
            wrapper.all('li.' + c).removeClass('hidden');
        }
    }, document, '#photoList li');

    //Stop the drag with the escape key
    Y.one(document).on('keypress', function(e) {
        //The escape key was pressed
        if ((e.keyCode === 27) || (e.charCode === 27)) {
            //We have an active Drag
            if (Y.DD.DDM.activeDrag) {
                //Stop the drag
                Y.DD.DDM.activeDrag.stopDrag();
            }
        }
    });
    //On the drag:mouseDown add the selected class
    Y.DD.DDM.on('drag:mouseDown', function(e) {
        e.target.get('node').all('img').addClass('selected');
    });
    //On drag start, get all the selected elements
    //Add the count to the proxy element and offset it to the cursor.
    Y.DD.DDM.on('drag:start', function(e) {
        //How many items are selected
        var count = wrapper.all('img.selected').size();
        //Set the style on the proxy node
        e.target.get('dragNode').setStyles({
            height: '25px', width: '25px'
        }).set('innerHTML', '<span>' + count + '</span>');
        //Offset the dragNode
        e.target.deltaXY = [25, 5];
    });
    //We dropped on a drop target
    Y.DD.DDM.on('drag:drophit', function(e) {
        //get the images that are selected.
        var imgs = wrapper.all('img.selected'),
            //The xy position of the item we dropped on
            toXY = e.drop.get('node').getXY();
        
        imgs.each(function(node) {
            //Clone the image, position it on top of the original and animate it to the drop target
            node.get('parentNode').addClass(e.drop.get('node').get('id'));
            var n = node.cloneNode().set('id', '').setStyle('position', 'absolute');
            Y.one('body').appendChild(n);
            n.setXY(node.getXY());
            new Y.Anim({
                node: n,
                to: {
                    height: 20, width: 20, opacity: 0,
                    top: toXY[1], left: toXY[0]
                },
                from: {
                    width: node.get('offsetWidth'),
                    height: node.get('offsetHeight')
                },
                duration: .5
            }).run();
        });
        //Update the count
        var count = wrapper.all('li.' + e.drop.get('node').get('id')).size();
        e.drop.get('node').one('span').set('innerHTML', '(' + count + ')');
    });
    //Add drop support to the albums
    Y.all('#photoList li').each(function(node) {
        if (!node.hasClass('all')) {
            //make all albums Drop Targets except the all photos.
            node.plug(Y.Plugin.Drop);
        }
    });
});
