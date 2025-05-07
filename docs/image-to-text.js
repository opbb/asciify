const valueToPlainText = {
  0: "\u00A0", // Non-breaking space
  1: ".",
  2: ",",
  3: "-",
  4: "~",
  5: ":",
  6: ";",
  7: "=",
  8: "!",
  9: "*",
  10: "#",
  11: "$",
  12: "@",
};

valueToHTML = {
  0: "&nbsp;", // Non-breaking space
  1: ".",
  2: ",",
  3: "-",
  4: "~",
  5: ":",
  6: ";",
  7: "=",
  8: "!",
  9: "*",
  10: "#",
  11: "$",
  12: "@",
};

function imageToText(
  image, // Assumes image is Image class from image-js (https://github.com/image-js/image-js)
  invert = true,
  reductionFactor = 10.0,
  // adjustValueRange = true,
) {
  const adjustValueRange = true;

  if (image === undefined || image === null) {
    return;
  }

  let reducedGrayscaledImage = image
    .resize({ factor: 1.0 / reductionFactor })
    .grey();

  // Default max and min values
  let maxValue = 255.0;
  let minValue = 0.0;

  // Adjust max and min values to most extreme values in the image
  if (adjustValueRange) {
    maxValue = reducedGrayscaledImage.max[0];
    minValue = reducedGrayscaledImage.min[0];
  }

  const rowsArray = [];
  for (let i = 0; i < reducedGrayscaledImage.height; i++) {
    rowsArray.push(reducedGrayscaledImage.getRow(i));
  }

  plainTextImage = "";
  htmlImage = "";
  rowsArray.forEach((row) => {
    row.forEach((pixelValue) => {
      // Reduces all 256 possible values down to 13, which we have characters to represent
      charIndex = Math.floor(
        ((pixelValue - minValue) * 13.0) / (maxValue - minValue + 1.0),
      );
      if (invert) {
        charIndex = 12 - charIndex;
      }
      plainTextImage += valueToPlainText[charIndex];
      htmlImage += valueToHTML[charIndex];
    });
    plainTextImage += "\n";
    htmlImage += "<br/>\n";
  });

  return {
    plainTextImage: plainTextImage,
    htmlImage: htmlImage,
  };
}
