const textImageEl = document.getElementById("text-image");
const playButton = document.getElementById("play-button");
playButton.onclick = playButtonPress;
const playButtonVisibilityContianer = document.getElementById(
  "play-button-visibility-container",
);
playButtonVisibilityContianer.hidden = true;

// Current video data
let framesArray = undefined;
let audioEl = undefined;

// Current video options
let useAudio = undefined;
let isLoop = undefined;

// Player status
let vidLoaded = false;
let isPlaying = false;

const timeoutIds = [];
function clearTimeouts() {
  while (timeoutIds.length > 0) {
    clearTimeout(timeoutIds.pop());
  }
}

function loadVideoPlayer(
  frames,
  audio = false,
  loop = false,
  audioURL = undefined,
) {
  if (frames === undefined || frames === null) {
    console.error(
      "text-video-player could not find `frames` array when loading video.",
    );
    return;
  }

  framesArray = JSON.parse(JSON.stringify(frames)); // Deep-copy frames array
  isLoop = loop;
  useAudio = audio && !loop; // Audio isn't supported in GIF mode at the moment
  textImageEl.innerHTML = framesArray[0].frame;

  if (useAudio) {
    audioEl = new Audio(audioURL);
    audioEl.load();
  }

  vidLoaded = true;

  if (!isLoop) {
    playButtonVisibilityContianer.hidden = false;
  } else {
    startPlaying();
  }
}

function clearVideoPlayer() {
  if (isPlaying) {
    stopPlaying();
  }
  vidLoaded = false;
  playButtonVisibilityContianer.hidden = true;

  // Clear screen
  textImageEl.innerHTML = "";

  // Reset data and options
  frames = undefined;
  audioEl = undefined;
  useAudio = undefined;
  isLoop = undefined;
}

function updateTextImage(frame) {
  // We get the element again rather than using the variable so that this function can be used in setTimeout
  document.getElementById("text-image").innerHTML = frame;
}

function setIsPlaying(newIsPlaying) {
  if (isPlaying === newIsPlaying) {
    return;
  }
  if (newIsPlaying === true) {
    playButton.innerHTML = "&#9632;"; // Set button to stop symbol
    isPlaying = true;
  } else {
    playButton.innerHTML = "&#9658;"; // Set button to play symbol
    isPlaying = false;
  }
}

function startPlaying() {
  setIsPlaying(true);
  let currentTimeMs = 0;
  for (let i = 0; i < framesArray.length; i++) {
    timeoutIds.push(
      setTimeout(updateTextImage, currentTimeMs, framesArray[i].frame),
    );
    currentTimeMs += framesArray[i].holdFor;
  }
  timeoutIds.push(
    setTimeout(() => {
      if (!isLoop) {
        setIsPlaying(false);
      }
      clearTimeouts();
      if (isLoop) {
        startPlaying();
      }
    }, currentTimeMs),
  );
  if (useAudio) {
    let playResult = audioEl.play();
    playResult.catch((e) => {
      useAudio = false;
    });
    audioEl.currentTime = 0;
  }
}

function stopPlaying() {
  setIsPlaying(false);
  clearTimeouts();
  textImageEl.innerHTML = framesArray[0].frame;
  if (useAudio) {
    audioEl.pause();
  }
}

function playButtonPress() {
  if (isPlaying) {
    stopPlaying();
  } else {
    startPlaying();
  }
}
