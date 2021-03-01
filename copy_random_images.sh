
mount -a
OUT_FILE="/home/pi/log.txt"
ALREADY_FILE="/home/pi/already.txt"
COMPARE_FILE="/home/pi/compare.txt"

if [ ! "$(ls -A /var/ds216/photo)" ]
then
    echo "<path> is empty!"
    echo "<path> is empty!" >> $OUT_FILE
else

cd /var/ds216/photo
ls -1d */ | grep -P '^\d{4}' >> $COMPARE_FILE

FOLDER=$(grep -Fxv -f $ALREADY_FILE $COMPARE_FILE | shuf -n 1)

echo "---------------------------------" >> $OUT_FILE
date "+DATE: %D%nTIME: %T" >> $OUT_FILE
echo $FOLDER >> $OUT_FILE
echo $FOLDER



DESTINATION="/home/pi/MagicMirror/modules/copyimages"
STASH_DESTINATION="/home/pi/MagicMirror/modules/copyimages-stash"
rm -r $STASH_DESTINATION
mkdir $STASH_DESTINATION

FOLDER_COUNT=$(find "$FOLDER" -type f ! -path '*/@eaDir/*' | grep -P -i '(jpg|png)$' | wc -l)
echo $FOLDER_COUNT >> $OUT_FILE
echo $FOLDER
echo $FOLDER_COUNT

if [ $FOLDER_COUNT -lt 50 ]; then
   SECOND_FOLDER=$(ls -1d */ | grep -P '^\d{4}' | shuf -n 1)
   SECOND_FOLDER_COUNT=$(find "$SECOND_FOLDER" -type f ! -path '*/@eaDir/*' | grep -P -i '(jpg|png)$' | wc -l)
   echo $SECOND_FOLDER >> $OUT_FILE
   echo $SECOND_FOLDER_COUNT >> $OUT_FILE
   echo "Need Second Folder"
   echo $SECOND_FOLDER
   /usr/bin/rsync -ah --progress --exclude="@eaDir" --include="*.png" --include="*.PNG" --include="*.jpg" --include="*.JPG" --include="**/" --exclude="*" /var/ds216/photo/$SECOND_FOLDER $ST$
fi

/usr/bin/rsync -ah --progress --exclude="@eaDir" --include="*.png" --include="*.PNG" --include="*.jpg" --include="*.JPG" --include="**/" --exclude="*" /var/ds216/photo/$FOLDER $STASH_DESTIN$

rm -r $DESTINATION
mkdir $DESTINATION

/bin/mv $STASH_DESTINATION/* $DESTINATION

echo $SECOND_FOLDER >> $ALREADY_FILE
echo $FOLDER >> $ALREADY_FILE

sudo /sbin/shutdown -r -f now

fi
