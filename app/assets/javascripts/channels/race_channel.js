App.cable.subscriptions.create("RaceChannel", {
  connected: function() {
    return this.install();
  },
  install: function() {
    return $(document).on("click", "[data-behavior~=start-race]", function() {
      return this.perform("start");
    }.bind(this));
  }
});
