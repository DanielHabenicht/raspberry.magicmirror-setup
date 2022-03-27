import piexif
from PIL import Image
import os
import piexif.helper
import re
import numpy as np

print("running")


def extractText(x):
    entry = re.findall(
        r"([^\x00]*)(\x00*).(.+)", x)[0]
    comment = entry[2]
    comment = re.sub(r"\s\s+", ' ', comment)
    comment = comment.strip()
    # (.+?)(\d{1,2}[\.,]{0,1}\d{1,2}[\.,]{0,1}\d\d\d\d)([^\.]+)
    return [entry[0].replace("\x00", ""), entry[1], comment]


# directory = "D:\OpaArchiv"
directory = ".\\fileconvert\\data"
for root, subFolder, files in os.walk(directory):
    print(root)
    filteredFiles = np.array(
        list(filter(lambda x: re.search("\.(jpg|jpeg)", x.lower()), files)))
    notFilteredFiles = np.array(
        list(filter(lambda x: not x.lower().endswith('.jpg'), files)))
    if len(notFilteredFiles) > 1:
        print(f"WARNING: Following files wont be covered: {notFilteredFiles}")
    filedescriptions = {}
    if len(filteredFiles) > 0:
        # try:
        fileNamePath = str(os.path.join(root, 'keyword.bas'))
        with open(fileNamePath, 'r', encoding='iso-8859-15', errors="ignore") as f:
            text = f.read()
            positions = np.array(list(map(
                lambda x: text.find(x), filteredFiles)))
            removeIndexes = np.where(positions == -1)[0]
            keepIndices = np.ones(len(positions), bool)
            keepIndices[removeIndexes] = 0

            if len(removeIndexes) > 0:
                print(
                    f"WARNING: Removed {len(removeIndexes)}/{len(filteredFiles)} {filteredFiles[removeIndexes]} ")
            # foreach with index
            # for index, position in enumerate(positions):
            #     if position == -1:
            positions = positions[keepIndices]
            filteredFiles = filteredFiles[keepIndices]

            if not all((positions[i] <= positions[i+1]) for i in range(len(positions)-1)):

                print("WARNING: not sorted")
                positions, filteredFiles = list(zip(*sorted(
                    zip(positions, filteredFiles))))

            # betterPositions = dict(zip(filteredFiles, positions))

            substrings = [text[v1:v2]
                          for v1, v2 in zip([0]+list(positions), list(positions)+[None])]

            subcomments = list(map(extractText, substrings[1:]))

            comments = dict(zip(filteredFiles, subcomments))

            # Sanity
            for index, name in enumerate(comments.keys()):
                if not name in subcomments[index][0]:
                    raise Exception(
                        f"Not same order {name} - {subcomments[index][0]} at {index}")

            # print(comments)
        # except Exception as e:
        #     print(e)
        for file in filteredFiles:
            fileNamePath = str(os.path.join(root, file))
            result = list(filter(lambda x: file.lower()
                                 in x.lower(), comments.keys()))
            if len(result) > 0:
                descriptionString = comments[result[0]][2]
                print(" - " + file + ": " + descriptionString)
                user_comment = piexif.helper.UserComment.dump(
                    descriptionString)

                exif_dict = piexif.load(fileNamePath)

                # Add EXIF Description Data https://exiv2.org/tags.html
                exif_dict["Exif"][piexif.ExifIFD.UserComment] = user_comment
                try:
                    exif_bytes = piexif.dump(exif_dict)
                except piexif.InvalidImageDataError:
                    del exif_dict["1st"]
                    del exif_dict["thumbnail"]
                    exif_bytes = piexif.dump(exif_dict)
                piexif.insert(exif_bytes, fileNamePath)
            else:
                print("WARNING: No Description found for '" + fileNamePath + "'")


# exif_bytes = piexif.dump(exif_dict)
# img.save('_%s' % fname, "jpeg", exif=exif_bytes)
