#!/usr/bin/python3
from PIL import Image, ImageFilter
from math import floor
from sys import argv

# DEFAULT VALUES
reductionAmount = 10
useAllCharacters = True
enhanceEdges = True
maxValue = 255.0
minValue = 0.0
inputFile = None
outputFileName = "imageText"

# MESSAGES
helpMsg = """
=== IMAGE TO TEXT ===
image-to-text [OPTIONS]... IN_FILE [OUT_FILE]

OPTIONS:
-a, --all-chars                         Use all characters to represent an image. Increases quality, but makes all images a similar brightness.
-r [int], --reduction-amount [int]      Set reduction factor.
-e, --enhance-edges                     Enhance edges.
-h, --help                              Help.
"""
indexOutOfBoundsErrMsg = "ERROR: Argument index {index} is out of bounds."
invalidArgumentErrMsg = "ERROR: {argument} is not a valid argument."
needReductionAmountErrMsg = "ERROR: Must provide a reduction amount with {tag}."
invalidIntegerArgErrMsg = "ERROR: {argument} is not a valid integer."

# PROCESS COMMAND LINE ARGS
# there has to be a better way to do this this is so uglY
# (but im not figureing it out now, I slep)
def processArgv(i: int) -> None:
        if (i >= len(argv)):
            print(indexOutOfBoundsErrMsg.format(index = str(i)))
            exit(1)

        arg = argv[i]
        global reductionAmount
        global useAllCharacters
        global enhanceEdges
        global inputFile
        global outputFileName
        nextIndex = i + 1
        if (i == len(argv) - 1):
            if (inputFile == None):
                inputFile = arg
            else:
                outputFileName = arg

        elif (i == len(argv) - 2 and arg[:1] != "-"):
            inputFile = arg

        elif (len(arg) < 2):
            print(invalidArgumentErrMsg.format(argument = arg))
            exit(1)

        elif (arg[:1] == "-"):
            if (arg == "-a" or arg == "--all-chars"):
                useAllCharacters = True

            elif (arg == "-e" or arg == "--enhance-edges"):
                enhanceEdges = True

            elif (arg == "-h" or arg == "--help"):
                print(helpMsg)
                exit(0)

            elif (arg == "-r" or arg == "--reduction-amount"):
                if (len(argv) - i <= 2):
                    print(needReductionAmountErrMsg.format(tag = arg))
                    exit(1)

                if (not argv[i + 1].isdigit()):
                    print(invalidIntegerArgErrMsg.format(argument = argv[i + 1]))
                    exit(1)
                    
                reductionAmount = int(argv[i + 1])
                nextIndex += 1
        
        else:
            print(invalidArgumentErrMsg.format(argument = arg))
            exit(1)
        
        if (nextIndex < len(argv)):
            processArgv(nextIndex)
        
        return

if (len(argv) == 1):
    print(helpMsg)
    exit(0)

processArgv(1)

if (inputFile == None):
    print("input file is null")
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