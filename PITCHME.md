#### Who's turn is it anyway?

Augmented reality board games.

@davetapley

+++

Disclaimer:

This talk is full of _terrible things_.

+++

But it's been a lot of fun.

---

# PitchCar

_Photo of box_

+++

# Demo time

_Show people playing via camera_

+++

#### Building the track

* n straights
* m corners

+++

Trivia: There are z combinations, h/t @jonah

+++

#### There are walls

* Around the outside of corners
* On _one side_ of each straight

+++

#### There *aren't* walls

aka: cars can and will  _leave the track_

_Show people flicking themselves and/or others off the track_

+++

|                     | Your car | Other cars |
|---------------------|----------|------------|
| The good            | Stays on | Stay on    |
| The bad             | Goes off | Stay on   |
| The ugly            | Goes off | Go off   |
| The just plain rude | Stays on | Go off   |

+++

### The good

You’re done, well done, next player.

+++

### The bad and ugly

All the cars which left the track go back.

+++

### The rude

You go back as well.

+++

*Go back*

+++

* Remembering is hard
* Especially impartial remembering

_Let's have computers do it_

+++

### Some rules

1. No hardware mods
1. Be as noninvasive as possible

---

#### The goal

After each player's turn, either:

* Tell the next player they can go, or:
* Show which cars need to be put back.

+++

### What do we need

* Video acquisition and rendering
* Image processing
* Real time communication

+++

#### Video acquisition and rendering

> This article shows how to use WebRTC to access the camera on a computer or mobile phone with WebRTC support and take a photo with it.

https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Taking_still_photos

+++

> Now let's take a look at the JavaScript code.

https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Taking_still_photos

Why not try Vue.js?

+++

#### Image processing

Going to cheat and use **OpenCV**
* C/C++ image processing library
* BSD license
* 16 years old

* Ruby wrapper:
  https://github.com/ruby-opencv

+++

# Be real time

> WebSocket protocol enables interaction between a browser and a web server with lower overheads, facilitating real-time data transfer from and to the server.

Did someone say **ACTION CABLE**?

+++

### Let's use

|                                      |              |
|--------------------------------------|--------------|
| Video acquisition and rendering      | Vue.js       |
| Image processing                     | OpenCV       |
| Real time asynchronous communication | Action Cable |

---

#### The plan

1. Get images from a webcam
1. Send it over a websocket
1. Load it in to OpenCV
1. Figure out when cars have moved
1. Display whose turn it is

+++

#### Get images from a webcam

##### vue-webcam

> A Vue component for capturing image from webcam.

https://github.com/smronju/vue-webcam

+++

```html
<vue-webcam ref='webcam'></vue-webcam>
<img :src="photo">
<button type="button" @click="take_photo">Take Photo</button>
```

+++

```javascript
    methods: {
        take_photo () {
            this.photo = this.$refs.webcam.getPhoto();
        }
    }
```

What is `this.photo`?

+++

#### Data URIs

>  URLs prefixed with the data: scheme, allow content creators to embed small files inline in documents.

https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URIs

+++

![](http://rubyonrails.org/images/imagine.png)

+++

---?gist=b716ae62881ba7f058fba393932d69ba

+++

```html
<img src="data:image/png;base64,iVBORw0K...">
```

---

1. ~~Get images from a webcam~~
1. Send it over a websocket
1. Load it in to OpenCV
1. Figure out when cars have moved
1. Display whose turn it is

+++

#### Send it over a websocket

#### ActionCable

_Show https://github.com/rlafranchi/pong_ repo

> demonstrate JavaScript framework Vue.js and Rails ActionCable

+++

Spolier: Suprisingly easy

1. Reference ActionCable within Vue
2. Subscribe to a channel
4. Receive data from that channel (to a Vue component)
3. Send data to that channel (from a Vue component)

+++

#### Reference ActionCable in Vue
```javascript
import ActionCable from 'actioncable'
const cable = ActionCable.createConsumer('wss://' + process.env.RAILS_URL.replace(/.*?:\/\//g, '') + '/cable')
Vue.prototype.$cable = cable
```

+++
#### Subscribe to a channel
```javascript
  created () {
    var that = this
    this.pongChannel = this.$cable.subscriptions.create({ channel: 'PongChannel', game_id: this.game.id }, {
```

+++
#### Receive data from that channel (to a Vue component)
```javascript
 received (data) {
        that.y = data.y
        that.x = data.x
      }
```

+++
#### Send data to that channel (from a Vue component)
```javascript
   this.paddleChannel.send({y: this.currentPaddle().y})
```
+++
