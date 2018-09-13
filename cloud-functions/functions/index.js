const functions = require('firebase-functions');
const PushNotifications = require('@pusher/push-notifications-server');
var Pusher = require('pusher');

let pushNotifications = new PushNotifications({
  instanceId: '8fdd0318-52a9-4cc1-8b0d-f08a3b681477',
  secretKey: 'D647B8574B72AB131F50D5CEF5D760D'
});

var pusher = new Pusher({
  appId: '521028',
  key: 'b5bd116d3da803ac6d12',
  secret: '7fc3579b80f5519a65aa',
  cluster: 'eu',
  encrypted: true
});

exports.sendPushNotification = functions.https.onRequest((req, res) => {
  const interest = String(req.body.uid)
  pushNotifications.publish([interest], {
    apns: {
      aps: {
        alert: 'You have a new match!',
      }
    }
  }).then((publishResponse) => {
    console.log('Just published:', req.body.uid);
  }).catch((error) => {
    console.log('Error:' + error + " for uid:" + req.body.uid);
  });
})

exports.triggerPusherChannel = functions.https.onRequest((req, res) => {
  // pusher.trigger(String(req.body.channel), String(req.body.event), {
  //   "message": "Hej ja sam poruka koja je u Firebase Cloud Functions"
  // }).then({
  //   res.sendStatus(200)
  // });
  // firebase deploy --only functions:triggerPusherChannel
  pusher.trigger(String(req.body.channel), String(req.body.event), { message: String(req.body.message) });
})