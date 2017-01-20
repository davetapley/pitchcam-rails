App.cable.subscriptions.create("VideoChannel", {
  connected: function() {
    return this.install();
  },

  install: function() {
    Webcam.set({
      width: 400,
      height: 300,
      image_format: 'jpeg',
      jpeg_quality: 100
    });

    Webcam.attach( '#my_camera' );

    snap = function() {
      Webcam.snap( function(imageUri) {
        this.perform("frame", { image_uri: imageUri });
        //snap();
      }.bind(this));
    }.bind(this);

    Webcam.on('live', function() {
      this.perform("start");
      snap();
    }.bind(this));
  },

  received: function(data) {
    $("#latest").attr('src', data.imageUri);
    snap();
  }
});

