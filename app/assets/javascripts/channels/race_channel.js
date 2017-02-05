App.cable.subscriptions.create("RaceChannel", {
  connected: function() {
    return this.install();
  },
  install: function() {
    return $(document).on("click", "[data-behavior~=start-race]", function() {
      return this.perform("start");
    }.bind(this));
  },

  received: function(data) {
    if(data.dirtyColors.length >0 ) {
      var node = document.createElement("LI");
      var textnode = document.createTextNode(data);
      node.appendChild(textnode);

      var feed = document.querySelector('#race-feed')
      feed.appendChild(node);
    }

    if(data.config) {
    }
  }
});

