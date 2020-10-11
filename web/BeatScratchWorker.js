
var currentScore;
var playing = false;
var playbackMode = 'score';
var currentTick = 0;
var bpm = 123;
var currentSectionId;
var metronomeEnabled = true;
var activeAttacks = [];

self.onmessage = function (event) {
  switch (event.data.shift()) {
    case 'play':
      playing = true;
      tick();
      break;
    case 'pause':
      playing = false;
      break;
    case 'stop':
      playing = false;
      currentTick = 0;
      break;
    case 'setPlaybackMode':
      playbackMode = event.data[0];
      break;
    case 'createScore':
      currentScore = event.data[0];
      currentSectionId = currentScore.sections[0].id;
      break;
    case 'updateSections':
      currentScore.sections = event.data[0].sections;
      if (!currentScore.sections.some(s => s.id == currentSectionId)) {
        currentSectionId = currentScore.sections[0].id;
      }
      break;
    case 'setCurrentSection':
      currentSectionId = event.data[0];
      break;
    case 'setBeat':
      currentTick = event.data[0] * 24;
      break;
    case 'createMelody':
      var partId = event.data[0];
      var melody = event.data[1];
      currentScore.parts.filter(part => part.id == partId)[0].melodies.push(melody);
      break;
    case 'updateMelody':
      var melody = event.data[0];
      var part = currentScore.parts.filter(part => part.melodies.some(m => m.id = melody.id))[0];
      part.melodies = part.melodies.filter(m => m.id != melody.id);
      part.melodies.push(melody);
      break;
    case 'deletePart':
      currentScore.parts = currentScore.parts.filter(part => part.id != event.data[0]);
      break;
    case 'setMetronomeEnabled':
      metronomeEnabled = event.data[0];
      break;
    default:
      throw 'invalid call to worker';
  }
}

function sendMIDI(...bytes) {
  postMessage(['sendMIDI', ...bytes ]);
}

function findMelody(melodyId) {
  for(part in currentScore.parts) {
    for(m in part.melodies) {
      if(m.id == melodyId) {
        return m;
      }
    }
  }
  return null;
}

function tick() {
  var section = currentScore.sections.filter(it => it.id == currentSectionId)[0];
  if(metronomeEnabled && currentTick % 24 == 0) {
    sendMIDI(0x99, 75, 127)
    sendMIDI(0x89, 75, 127)
  }
  (section.melodies ?? []).forEach( melodyId => {
    var melody = findMelody(melodyId);
    if (melody == null) return;
    // TODO playback actual data from melody
  });
  currentTick++;

  var now = Date.now();
  var tickTime = 60000 / (bpm * 24);
  setTimeout(() => {
    while (Date.now() < now + tickTime) {}
    if (playing) tick();
  });
}