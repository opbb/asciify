# This file isn't intended to be used directly, its just where I develop the python before copying it to the bash script

from PIL import Image, ImageFilter
from math import floor
from sys import argv
from os.path import normpath

# DEFAULT VALUES
maxValue = 255.0
minValue = 0.0

# OPTION VALUES (set by bash)
reductionAmount=10
useAllCharacters=False
enhanceEdges=False
inputFile=None
outputFileName="imageText"
renderPlaintext=False
renderHtml=False

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
im = im.convert("L")

# Get image data as flattened list of pixel values
imData = list(im.getdata())

if useAllCharacters:
    maxValue = max(imData)
    minValue = min(imData)
imStringPlaintext = ""
imStringHTML = ""

for pixel in range(len(imData)):
    if (pixel % im.size[0] == 0):
        if (renderPlaintext): imStringPlaintext += "\n"
        if (renderHtml): imStringHTML += "<br/>\n"
    
    valueIndex = bandValues(imData[pixel])
    if (renderPlaintext): imStringPlaintext += valueToChar[valueIndex]
    if (renderHtml): imStringHTML += valueToHTML[valueIndex]

if (renderPlaintext):
    with open(outputFileName + ".txt", "w") as imTextFile:
        imTextFile.write(imStringPlaintext)

if (renderHtml):
    with open(outputFileName + ".html", "w") as imTextFile:
        imTextFile.write(imStringHTML)