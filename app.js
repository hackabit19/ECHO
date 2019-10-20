const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
var sdk = require("microsoft-cognitiveservices-speech-sdk");
var fs = require("fs");

const app = express();
app.use(express.static(__dirname + '/'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));


app.get('/givejson', function (req, res, next) {
    console.log("in the reconising  page");
    "use strict";
    var subscriptionKey = "95bda8b9567247e69b5eae5b1a133cc5";
    var serviceRegion = "westus"; // e.g., "westus"
    var filename = "finalAudio.wav"; // 16000 Hz, Mono
    var pushStream = sdk.AudioInputStream.createPushStream();
    fs.createReadStream(filename).on('data', function (arrayBuffer) {
        pushStream.write(arrayBuffer.slice());
    }).on('end', function () {
        pushStream.close();
    });

    console.log("Now recognizing from: " + filename);
    var audioConfig = sdk.AudioConfig.fromStreamInput(pushStream);
    var speechConfig = sdk.SpeechConfig.fromSubscription(subscriptionKey, serviceRegion);
    speechConfig.speechRecognitionLanguage = "en-US";
    var recognizer = new sdk.SpeechRecognizer(speechConfig, audioConfig);
    recognizer.recognizeOnceAsync(
        function (result) {
            console.log(result);
            recognizer.close();
            recognizer = undefined;
            return res.json(result);
        },
        function (err) {
            console.trace("err - " + err);

            recognizer.close();
            recognizer = undefined;
        });

  
});


app.use('/', function (req, res, next) {
    console.log("in the search page page");
    res.sendFile(path.join(__dirname, 'view', 'index.html'));
});

app.listen(3600);
