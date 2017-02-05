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
      var training = document.querySelector('#training-video')

      var URL = window.URL || window.webkitURL
      var displayMessage = function (message, isError) {
        var element = document.querySelector('#message')
        element.innerHTML = message
        element.className = isError ? 'error' : 'info'
      }
      var playSelectedFile = function (event) {
        var file = this.files[0]
        var type = file.type
        var canPlay = training.canPlayType(type)
        if (canPlay === '') canPlay = 'no'
        var message = 'Can play type "' + type + '": ' + canPlay
        var isError = canPlay === 'no'
        displayMessage(message, isError)

        if (isError) {
          return
        }

        var fileURL = URL.createObjectURL(file)
        training.src = fileURL
      }

      var inputNode = document.querySelector('input')
      inputNode.addEventListener('change', playSelectedFile, false)

      var setTrackBoundary = function(event) {
        var rect = training.getBoundingClientRect();

        x = event.clientX - rect.left;
        y = event.clientY - rect.top;

        if(training.getAttribute('data-track-boundary-1-x')) {
          training.setAttribute('data-track-boundary-2-x', x);
          training.setAttribute('data-track-boundary-2-y', y);
        } else {
          training.setAttribute('data-track-boundary-1-x', x);
          training.setAttribute('data-track-boundary-1-y', y);
        }
      };
      training.addEventListener('click', setTrackBoundary, false)
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
      snap = function() {
        var canvas = document.createElement("CANVAS");
        if(training.getAttribute('data-track-boundary-2-x')) {
          x_1 = training.getAttribute('data-track-boundary-1-x');
          y_1 = training.getAttribute('data-track-boundary-1-y');
          x_2 = training.getAttribute('data-track-boundary-2-x');
          y_2 = training.getAttribute('data-track-boundary-2-y');
          canvas.width = x_2 - x_1;
          canvas.height = y_2 - y_1;
          canvas.getContext('2d').drawImage(training, x_1, y_1, canvas.width, canvas.height, 0, 0, canvas.width, canvas.height);
        } else {
          canvas.width = training.videoWidth;
          canvas.height = training.videoHeight;
          canvas.getContext('2d').drawImage(training, 0, 0);
        }

        var imageUri = canvas.toDataURL('img/jpeg');
        this.perform("frame", { image_uri: imageUri });
      }.bind(this);


      training.addEventListener('play', function() {
        this.perform("start");
        snap();
      }.bind(this));
    }
},

received: function(data) {
  $("#latest").attr('src', data.imageUri);
  snap();
}
});

