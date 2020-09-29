
self.onmessage = function (event) {
    switch (event.data[0]) {
        case 'play':
          postMessage(['sendMIDI', 0x90, 60, 127 ]);
          setTimeout(function() {
            postMessage(['sendMIDI', 0x80, 60 ]);
          }, 5000);
          break;
        default:
            throw 'no aTopic on incoming message to ChromeWorker';
    }
}