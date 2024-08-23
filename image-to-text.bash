#!/usr/bin/bash

# ====== OPTIONS ======
help_message="=== IMAGE TO TEXT ===\n
image-to-text -i file_path [OPTIONS]\n
\n
OPTIONS:\n
 -i file_path   \t input file path (REQUIRED)\n
 -n file_name   \t output file name (without the extension)\n
 -r int         \t set factor image resolution will be reduced by.\n
 -a           \t\t use all characters to represent an image (increases quality, but makes all images a similar brightness)\n
 -e           \t\t enhance edges.\n
 -p           \t\t render only in plaintext\n
 -m           \t\t render only in HTML (m is for markup)\n
 -h           \t\t print help text."

# DEFAULT VALUES
reduction_amount=10
use_all_characters="False"
enhance_edges="False"
input_file_path="None"
output_file_name="imageText"
render_plaintext="False"
render_html="False"

# REQUIRED VALUES
input_file_path_flag=false
# ======================

# === PROCESS OPTIONS ===
while getopts i:n:r:aepmh flag
do
    case "${flag}" in
        i) input_file_path_flag=true;input_file_path=${OPTARG};;
        n) output_file_name=${OPTARG};;
        r) reduction_amount=${OPTARG};;
        a) use_all_characters="True";;
        e) enhanceEdges="True";;
        p) render_plaintext="True";;
        m) render_html="True";;
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
if [ $render_plaintext = "False" ] && [ $render_html = "False" ]; then
  render_html="True"
  render_plaintext="True"
fi

# =======================

python3 <<< "
from PIL import Image, ImageFilter
from math import floor
from sys import argv
from os.path import normpath

# DEFAULT VALUES
maxValue = 255.0
minValue = 0.0

# OPTION VALUES
reductionAmount=$reduction_amount
useAllCharacters=$use_all_characters
enhanceEdges=$enhance_edges
inputFile=\"$input_file_path\"
outputFileName=\"$output_file_name\"
renderPlaintext=$render_plaintext
renderHtml=$render_html

valueToChar = {
    0 : '\u00A0',
    1 : '.',
    2 : ',',
    3 : '-',
    4 : '~',
    5 : ':',
    6 : ';',
    7 : '=',
    8 : '!',
    9 : '*',
    10 : '#',
    11 : '$',
    12 : '@',
}

valueToHTML = {
    0 : '&nbsp;',
    1 : '.',
    2 : ',',
    3 : '-',
    4 : '~',
    5 : ':',
    6 : ';',
    7 : '=',
    8 : '!',
    9 : '*',
    10 : '#',
    11 : '$',
    12 : '@',
}

# Reduces all 256 possible values down to just 13
def bandValues(value: int) -> int:
    return floor(((value - minValue) * 13.0) / (maxValue - minValue + 1.0))

#Read image
im = Image.open(inputFile)

if enhanceEdges:
    im = im.filter(ImageFilter.EDGE_ENHANCE_MORE)

# Pixelate image
im = im.reduce(reductionAmount)

# Convert image to grayscale
im = im.convert(\"L\")

# Get image data as flattened list of pixel values
imData = list(im.getdata())

if useAllCharacters:
    maxValue = max(imData)
    minValue = min(imData)
imStringPlaintext = \"\"
imStringHTML = \"\"

for pixel in range(len(imData)):
    if (pixel % im.size[0] == 0):
        if (renderPlaintext): imStringPlaintext += \"\n\"
        if (renderHtml): imStringHTML += \"<br/>\n\"
    
    valueIndex = bandValues(imData[pixel])
    if (renderPlaintext): imStringPlaintext += valueToChar[valueIndex]
    if (renderHtml): imStringHTML += valueToHTML[valueIndex]

if (renderPlaintext):
    with open(outputFileName + \".txt\", \"w\") as imTextFile:
        imTextFile.write(imStringPlaintext)

if (renderHtml):
    with open(outputFileName + \".html\", \"w\") as imTextFile:
        imTextFile.write(imStringHTML)"