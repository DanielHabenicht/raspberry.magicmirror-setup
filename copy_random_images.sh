mount -a
cd /var/ds216/photo
FOLDER=$(ls -1d */ | grep -P '^\d{4}' | shuf -n 1)

echo $FOLDER


DESTINATION="/home/pi/MagicMirror/modules/copyimages"
STASH_DESTINATION="/home/pi/MagicMirror/modules/copyimages-stash"
rm -r $STASH_DESTINATION
mkdir $STASH_DESTINATION

FOLDER_COUNT=$(find $FOLDER -type f ! -path '*/@eaDir/*' | grep -P -i '(jpg|png)$' | wc -l)
echo $FOLDER_COUNT

if [ $FOLDER_COUNT -lt 50 ]; then
   SECOND_FOLDER=$(ls -1d */ | grep -P '^\d{4}' | shuf -n 1)
   echo "Need Second Folder"
   echo $SECOND_FOLDER
   /usr/bin/rsync -ah --progress --exclude="@eaDir" --exclude="*.avi" --exclude="*.flv" --exclude="*.mts" --exclude="*.FLV" --exclude="*.MTS" --exclude="*.AVI" --exclude="*.mp4" --exclude="*.db" /var/ds216/photo/$SECOND_FOLDER $STASH_DESTINATION/$SECOND_FOLDER
fi

/usr/bin/rsync -ah --progress --exclude="@eaDir" --exclude="*.avi" --exclude="*.flv" --exclude="*.mts" --exclude="*.FLV" --exclude="*.MTS" --exclude="*.AVI" --exclude="*.mp4" --exclude="*.db" /var/ds216/photo/$FOLDER $STASH_DESTINATION/$FOLDER

rm -r $DESTINATION
mkdir $DESTINATION

/bin/mv $STASH_DESTINATION/* $DESTINATION

sudo /sbin/shutdown -r -f now
