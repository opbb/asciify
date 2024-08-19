#!/usr/bin/python3
from PIL import Image, ImageFilter
from math import floor
from sys import argv
from os.path import normpath

# DEFAULT VALUES
reductionAmount = 10
useAllCharacters = True
enhanceEdges = True
maxValue = 255.0
minValue = 0.0
inputFile = None
outputFileName = "imageText"

# MESSAGES
helpMsg = """=== IMAGE TO TEXT ===
image-to-text [OPTIONS]... IN_FILE [OUT_FILE]

OPTIONS:
-a, --all-chars                         Use all characters to represent an image. Increases quality, but makes all images a similar brightness.
-r [int], --reduction-amount [int]      Set reduction factor.
-e, --enhance-edges                     Enhance edges.
-h, --help                              Help."""
indexOutOfBoundsErrMsg = "ERROR: Argument index {index} is out of bounds."
invalidArgumentErrMsg = "ERROR: {argument} is not a valid argument."
invalidIntegerArgErrMsg = "ERROR: {argument} is not a valid integer."

# PROCESS COMMAND LINE ARGS
if (len(argv) == 1):
    print(helpMsg)
    exit(0)

skipCounter = 0 # used to skip values for options, such as reduction amount
for i in range(1,len(argv)):
    arg = argv[i]

    if (skipCounter > 0):
        skipCounter -= 1
        continue

    # If this is the last argument, assume it's the input or output file.
    if (i == len(argv) - 1):
        if (inputFile == None):
            inputFile = normpath(arg)
        else:
            outputFileName = normpath(arg)
        continue

    if (arg == "-a" or arg == "--all-chars"):
        useAllCharacters = True
        continue

    if (arg == "-e" or arg == "--enhance-edges"):
        enhanceEdges = True
        continue

    if (arg == "-h" or arg == "--help"):
        print(helpMsg)
        exit(0)

    if (arg == "-r" or arg == "--reduction-amount"):
        if (not argv[i + 1].isdigit()):
            print(invalidIntegerArgErrMsg.format(argument = argv[i + 1]))
            exit(1)
            
        reductionAmount = int(argv[i + 1])
        skipCounter += 1
        continue
    
    # If it's the 2nd to last argument and it is not a valid option, assume it is the input file.
    if (i == len(argv) - 2):
        inputFile = normpath(arg)
        continue

    # If it's not any of the above, it's an invalid argument.
    print(invalidArgumentErrMsg.format(argument = arg))
    exit(1)

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
        imStringPlaintext += "\n"
        imStringHTML += "<br/>\n"
    
    valueIndex = bandValues(imData[pixel])
    imStringPlaintext += valueToChar[valueIndex]
    imStringHTML += valueToHTML[valueIndex]

with open(outputFileName + ".txt", "w") as imTextFile:
    imTextFile.write(imStringPlaintext)

with open(outputFileName + ".html", "w") as imTextFile:
    imTextFile.write(imStringHTML)