#!/usr/bin/bash

# ====== OPTIONS ======
help_message="video-to-html -i file_path [OPTIONS]\n
\n
OPTIONS:\n
 -i file_path   \t input file path (REQUIRED)\n
 -f int         \t framerate in frames per second\n
 -n file_name   \t name of the output\n
 -r int         \t resolution reduction factor\n
 -o           \t\t overwrite pre-existing files\n
 -a           \t\t include audio\n
 -k           \t\t keep individual frame files after they are done being compiled\n
 -j           \t\t render to json only (default is both JSON and standalone)\n
 -s           \t\t render to standalone HTML only (default is both JSON and standalone)\n
 -h           \t\t print help message"

# DEFAULT VALUES
overwrite=false
animation_name_flag=false # animation_name defaults to input_file name (set later)
framerate_flag=false # framerate is set to default later
reduction_amount=10
include_audio=false
keep_frames=false
render_json=false
render_html=false

# REQUIRED VALUES
input_file_path_flag=false
# ======================

# === PROCESS OPTIONS ===
while getopts i:f:n:r:oajsh flag
do
    case "${flag}" in
        i) input_file_path_flag=true;input_file_path=${OPTARG};;
        f) framerate_flag=true;framerate=${OPTARG};;
        n) animation_name_flag=true;animation_name=${OPTARG};;
        r) reduction_amount=${OPTARG};;
        o) overwrite=true;;
        a) include_audio=true;;
        k) keep_frames=true;;
        j) render_json=true;;
        s) render_html=true;;
        h) echo -e $help_message;exit 0;;
        \?) echo -e $help_message;exit 0;;
    esac
done

# If no arguments are passed, print help message
if [ $# -lt 1 ]; then
  echo -e $help_message
  exit 0
fi

if [ $input_file_path_flag = false ]; then
  echo "Input file is required. Provide it with: -i file_path"
  exit 1
fi

# If no render type is set, render both
if [ $render_json = false ] && [ $render_html = false ]; then
  render_html=true
  render_json=true
fi

# Set animation_name default if not set
if [ $animation_name_flag = false ]; then
  trimmed=$(basename $input_file_path)
  trimmed="${trimmed%.*}"
  animation_name=$trimmed
fi
# =======================

# === STATIC STRINGS ===
json_header="{\n
    \"frames\": ["
json_footer="\"holdFor\":250}\n
  ]\n
}"
html_header="<!DOCTYPE html>\n
<html>\n
  <head>\n
    <meta charset=\"UTF-8\" />\n
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />\n
    <title>$animation_name</title>\n
\n
    <style>\n
      body {\n
        color: white;\n
        background-color: black;\n
        font-size: 10px;\n
        overflow: auto;\n
        white-space: nowrap;\n
        text-align: center;\n
        justify-content: center;\n
        font-family: monospace;\n
        line-height: 1em;\n
        letter-spacing: 0.3em;\n
        padding: 10px;\n
      }\n
\n
      #screen-container {\n
        width: min-content;\n
        margin: auto;\n
      }\n
\n
      #audio-warning {\n
        font-size: 12px;\n
        margin: 10px;\n
        text-wrap: wrap;\n
        line-height: 15px;\n
      }\n
\n
      button {\n
        color: white;\n
        background-color: black;\n
        border-color: white;\n
        border-width: 4px;\n
        padding: 0.5em;\n
        width: 100%;\n
      }\n
\n
      button:hover {\n
        color: black;\n
        background-color: white;\n
        border-color: white;\n
      }\n
    </style>\n
  </head>\n
  <body>\n
    <div id=\"screen-container\">\n
      <div id="audio-warning" hidden>\n
        <i\n
          >(Warning: The audio for this video could not be found. Please ensure\n
          it is in the same folder, and is named ${animation_name}_Audio.mp3)</i\n
        >\n
      </div>\n
      <button onclick=\"buttonPress()\">&#9658;</button>\n
      <b><div id=\"anim-container\"></div></b>\n
    </div>\n
    <script>\n
      frames = ["
html_footer="holdFor: 250,\n
        },\n
      ];\n
    </script>\n
    <script>\n
      let useAudio = $include_audio;\n
      let audioElement = undefined;\n
      if (useAudio) {\n
        audioElement = new Audio(\n
          window.location.href.replace(/.html/, \"_Audio.mp3\")\n
        );\n
        audioElement.load();\n
      }\n
      let isPlaying = false;\n
\n
      const timeoutIds = [];\n
      function clearTimeouts() {\n
        while (timeoutIds.length > 0) {\n
          clearTimeout(timeoutIds.pop());\n
        }\n
      }\n
\n
      const animContainer = document.getElementById(\"anim-container\");\n
      animContainer.innerHTML = frames[0].frame;\n
      function updateAnimContainer(frame) {\n
        document.getElementById(\"anim-container\").innerHTML = frame;\n
      }\n
\n
      const button = document.querySelector(\"button\");\n
      function setIsPlaying(newIsPlaying) {\n
        if (isPlaying === newIsPlaying) {\n
          return;\n
        }\n
        if (newIsPlaying === true) {\n
          button.innerHTML = \"&#9632;\"; // Set button to stop symbol\n
          isPlaying = true;\n
        } else {\n
          button.innerHTML = \"&#9658;\"; // Set button to play symbol\n
          isPlaying = false;\n
        }\n
      }\n
\n
      function buttonPress() {\n
        if (isPlaying) {\n
          setIsPlaying(false);\n
          clearTimeouts();\n
          animContainer.innerHTML = frames[0].frame;\n
          if (useAudio) {\n
            audioElement.pause();\n
          }\n
        } else {\n
          setIsPlaying(true);\n
          let currentTimeMs = 0;\n
          for (let i = 0; i < frames.length; i++) {\n
            timeoutIds.push(\n
              setTimeout(updateAnimContainer, currentTimeMs, frames[i].frame)\n
            );\n
            currentTimeMs += frames[i].holdFor;\n
          }\n
          timeoutIds.push(\n
            setTimeout(() => {\n
              setIsPlaying(false);\n
              clearTimeouts();\n
            }, currentTimeMs)\n
          );\n
          if (useAudio) {\n
            let playResult = audioElement.play();\n
            playResult.catch((e) => {\n
              useAudio = false;\n
              document.getElementById(\"audio-warning\").hidden = false;\n
            });\n
            audioElement.currentTime = 0;\n
          }\n
        }\n
      }\n
    </script>\n
  </body>\n
</html>"
# ======================

# === GENERATE VIDEO ===
if [ $overwrite = false ] && [ -d "$animation_name" ]; then
  echo "Animation directory cannot be created because a directory with the name \"$animation_name\" already exists."
  echo "Please remove it, or use the -o option to overwrite it."
  echo "(WARNING: With the -o flag, any pre-existing directory contents will be permenantly deleted)"
  exit 1
fi

if [ $overwrite = true ] && [ -d "$animation_name" ]; then
  rm -rf "$animation_name"
fi

mkdir "$animation_name"
mkdir "$animation_name/frames"

# If framerate is not set, set it to the file's default
if [ $framerate_flag = false ]; then
  framerate=$(ffmpeg -i $input_file_path 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p")
fi

# Round to the nearest integer
framerate=$(bc <<< "scale=0; ($framerate+0.5)/1")
framerate=$((framerate))

# Convert video to frames
ffmpeg -i $input_file_path -vf fps=$framerate "$animation_name/frames/%06d.jpg"

if [ $include_audio = true ]; then
  ffmpeg -i $input_file_path "$animation_name/${animation_name}_Audio.mp3"
fi

if [ "$(which image-to-text)" != "" ]; then
  use_bin=true
elif [ -f "./image-to-text.bash" ]; then
  use_bin=false
else
  echo "Could not find image-to-text, make sure it is either in the same folder as video-to-html-animation, or in your bin folder."
  exit 1
fi

echo "Convert Frames to Text:"
for file in ./$animation_name/frames/*
do
  trimmed="${file#./$animation_name/frames/}"
  trimmed="${trimmed%.jpg}"
  echo -ne "\r$trimmed"
  if [ use_bin = true ]; then
    image-to-text -i "$file" -n "./$animation_name/frames/${trimmed}" -r $reduction_amount -m -e
  else
    ./image-to-text.bash -i "$file" -n "./$animation_name/frames/${trimmed}" -r $reduction_amount -m -e
  fi
done

# Calculate miliseconds per frame, rounded down to nearest whole number
msPerFrame=$(((1000 - (1000 % $framerate)) / $framerate))
echo -e "\nmsPerFrame: $msPerFrame"

echo "Compile TextFrames:"

if [ $render_json = true ]; then
  echo -e $json_header > "$animation_name/${animation_name}_TextFrames.json"
fi

if [ $render_html = true ]; then
  echo -e $html_header > "$animation_name/${animation_name}.html"
fi

prevNum=0
for file in $animation_name/frames/*.html
do
  # Get current frame data
  frameData=$(cat "${file}")
  frameData="${frameData//$'\n'/}"

  # Get current frame number
  trimmed="${file#$animation_name/frames/}"
  trimmed="${trimmed%.html}"
  echo -ne "\r$trimmed"
  frameNum=$((10#$trimmed))

  # Set amount of time to hold previous frame
  if [ $prevNum -ne 0 ]; then
    frameJump=$(($frameNum-$prevNum))
    holdFor=$(($frameJump*$msPerFrame))
    if [ $render_json = true ]; then
      echo -e "\"holdFor\":$holdFor}," >> "$animation_name/${animation_name}_TextFrames.json"
    fi
    if [ $render_html = true ]; then
      echo -e "holdFor:$holdFor}," >> "$animation_name/$animation_name.html"
    fi
    
  fi
  prevNum=$frameNum

  # Save current frame data
  if [ $render_json = true ]; then
      echo -ne "{\"frame\": \"$frameData\", " >> "$animation_name/${animation_name}_TextFrames.json"
    fi
    if [ $render_html = true ]; then
      echo -ne "{
      frame: \"$frameData\", " >> "$animation_name/$animation_name.html"
    fi
done
if [ $render_json = true ]; then
  echo -e $json_footer >> "$animation_name/${animation_name}_TextFrames.json"
fi
if [ $render_html = true ]; then
  echo -e $html_footer >> "$animation_name/$animation_name.html"
fi

if [ keep_frames=false ]; then
  rm -rf $animation_name/frames
fi

echo -e "\nSuccess :)"

# ======================