const functions = require('firebase-functions');
const Chatkit = require('@pusher/chatkit-server');

const chatkit = new Chatkit.default({
  instanceLocator: 'v1:us1:451f331c-a7a7-4374-8f78-08e72a680f4c',
  key: '732c60ea-5e9a-40ca-b964-c14cda4c1fa7:7Zgp160uaUNxoI87xXTGdNSJpgI909qEs4n0EgPSqhc=',
})

exports.createPusheruser = functions.https.onRequest((req, res) => {
    const pusherUserUID = req.body.uid;
    const pusherName = req.body.name;
    chatkit.createUser({
      id: pusherUserUID,
      name: pusherName,
    })
      .then(() => {
        res.status(200).send({ success: true });
      }).catch((err) => {
        res.status(400).send({ success: false, error: err});
      });
});

exports.createToken = functions.https.onRequest((req, res) => {
    const authData = chatkit.authenticate({
      userId: req.body.uid
    });
    res.status(authData.status).send(authData.body);
})

exports.triggerEvent = functions.https.onRequest((req, res) => {
  const channel = req.body.channel
  const event = req.body.event
  const data = req.body.data
  pusher.trigger(channel, event, data);
  res.status(authData.status).send(authData.body);
})