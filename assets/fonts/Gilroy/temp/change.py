import os
from fontTools import ttLib

# Declare your font file names and the correct weights here
to_change = {
    'Gilroy-Thin.ttf': 100,
    'Gilroy-ThinItalic.ttf': 100,
    'Gilroy-UltraLight.ttf': 200,
    'Gilroy-UltraLightItalic.ttf': 200,
    'Gilroy-Light.ttf': 300,
    'Gilroy-LightItalic.ttf': 300,
    'Gilroy-Regular.ttf': 400,
    'Gilroy-RegularItalic.ttf': 400,
    'Gilroy-SemiBold.ttf': 600,
    'Gilroy-SemiBoldItalic.ttf': 600,
    'Gilroy-Bold.ttf': 700,
    'Gilroy-BoldItalic.ttf': 700,
    'Gilroy-ExtraBold.ttf': 800,
    'Gilroy-ExtraBoldItalic.ttf': 800,
    'Gilroy-Black.ttf': 900,
    'Gilroy-BlackItalic.ttf': 900,
}

for file, weight in to_change.items():
    with ttLib.TTFont(os.path.join('', file)) as tt:
        tt['OS/2'].usWeightClass = weight
        tt.save(os.path.join('out',file))