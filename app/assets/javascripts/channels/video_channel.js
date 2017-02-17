App.cable.subscriptions.create("VideoChannel", {
  connected: function() {
    return this.install();
  },

  install: function() {
    var webcam = document.querySelector('#webcam-video')
    var training = document.querySelector('#training-video')

    if(webcam) {
      Webcam.set({
        width: 400,
        height: 300,
        image_format: 'jpeg',
        jpeg_quality: 100
      });

      Webcam.attach(webcam);
    } else if (training) {
      // moved to Vue
    }

    if(webcam) {
      snap = function() {
        Webcam.snap( function(imageUri) {
          this.perform("frame", { image_uri: imageUri });
        }.bind(this));
      }.bind(this);

      Webcam.on('live', function() {
        this.perform("start");
        snap();
      }.bind(this));

    } else if (training) {
      // moved to Vue
    }
},

received: function(data) {
  $("#latest").attr('src', data.imageUri);
  snap();
}
});

