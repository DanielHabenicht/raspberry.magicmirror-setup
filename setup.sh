#!/bin/bash

echo "Install node"
## Install node
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install -y nodejs

echo "Installing Magicmirror, this might take a while"

## Install magic mirror
git clone https://github.com/MichMich/MagicMirror
cd ~/MagicMirror/
npm install


## Install Modules
cd ~/MagicMirror/modules/
git clone https://github.com/fewieden/MMM-ip.git

cd ~/MagicMirror/modules/
git clone https://github.com/glitch452/MMM-LocalTemperature.git
sudo apt-get update && sudo apt-get upgrade && sudo apt-get install build-essential wiringpi
cd MMM-LocalTemperature && chmod +x DHT


cd ~/MagicMirror/modules/
git clone https://github.com/deg0nz/MMM-PublicTransportBerlin.git
cd MMM-PublicTransportBerlin
npm install


cd ~/MagicMirror/modules/
git clone https://github.com/darickc/MMM-BackgroundSlideshow.git
cd MMM-BackgroundSlideshow
npm install


echo "Setting up the client"
## Setting up desktop (client)

#########################
# Enter Sudo Mode
#########################
sudo -s
## Write config.txt

cat >/boot/config.txt <<EOL
# For more options and information see
# http://rpf.io/configtxt
# Some settings may impact device functionality. See link above for details

# uncomment if you get no picture on HDMI for a default "safe" mode
#hdmi_safe=1

# uncomment this if your display has a black border of unused pixels visible
# and your display can output without overscan
#disable_overscan=1
display_rotate=2
avoid_warnings=1 

# Power Saving
dtoverlay=pi3-disable-bt

# uncomment the following to adjust overscan. Use positive numbers if console
# goes off screen, and negative if there is too much border
#overscan_left=16
#overscan_right=16
#overscan_top=16
#overscan_bottom=16

# uncomment to force a console size. By default it will be display's size minus
# overscan.
#framebuffer_width=1280
#framebuffer_height=720

# uncomment if hdmi display is not detected and composite is being output
#hdmi_force_hotplug=1

# uncomment to force a specific HDMI mode (this will force VGA)
#hdmi_group=1
#hdmi_mode=1

# uncomment to force a HDMI mode rather than DVI. This can make audio work in
# DMT (computer monitor) modes
#hdmi_drive=2

# uncomment to increase signal to HDMI, if you have interference, blanking, or
# no display
#config_hdmi_boost=4

# uncomment for composite PAL
#sdtv_mode=2

#uncomment to overclock the arm. 700 MHz is the default.
#arm_freq=800

# Uncomment some or all of these to enable the optional hardware interfaces
#dtparam=i2c_arm=on
#dtparam=i2s=on
#dtparam=spi=on

# Uncomment this to enable infrared communication.
#dtoverlay=gpio-ir,gpio_pin=17
#dtoverlay=gpio-ir-tx,gpio_pin=18

# Additional overlays and parameters are documented /boot/overlays/README

# Enable audio (loads snd_bcm2835)
dtparam=audio=on

[pi4]
# Enable DRM VC4 V3D driver on top of the dispmanx display stack
dtoverlay=vc4-fkms-v3d
max_framebuffers=2

[all]
#dtoverlay=vc4-fkms-v3d
EOL

cat >/etc/systemd/system/magicmirror.service <<EOL
[Unit]
Description=Magic Mirror
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=pi
WorkingDirectory=/home/pi/MagicMirror/
ExecStart=/usr/bin/node serveronly

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl enable magicmirror.service
sudo systemctl start magicmirror.service


#########################
# Leave Sudo Mode
#########################
exit
mkdir /home/pi/.config/lxsession
mkdir /home/pi/.config/lxsession/LXDE-pi
cat >/home/pi/.config/lxsession/LXDE-pi/autostart <<EOL
@xset s noblank
@xset s off
@xset -dpms
@unclutter -display :0 -idle 3 -root -noevents

@lxpanel --profile LXDE-pi
@pcmanfm --desktop --profile LXDE-pi
@xscreensaver -no-splash
@point-rpi
@sh /home/pi/bin/start-chromium.sh
EOL


mkdir /home/pi/bin
cat >/home/pi/bin/start-chromium.sh <<EOL
#!/bin/sh

set -e

CHROMIUM_TEMP=~/tmp/chromium
rm -Rf ~/.config/chromium/
rm -Rf $CHROMIUM_TEMP
mkdir -p $CHROMIUM_TEMP

# Power Saving
echo '1-1' |sudo tee /sys/bus/usb/drivers/usb/unbind
sudo /opt/vc/bin/tvservice -o

chromium-browser \
        --disable \
        --disable-translate \
        --disable-infobars \
        --disable-suggestions-service \
        --disable-save-password-bubble \
        --disk-cache-dir=$CHROMIUM_TEMP/cache/ \
        --user-data-dir=$CHROMIUM_TEMP/user_data/ \
        --start-maximized \
        --kiosk http://localhost:8080 &
EOL


### Add Conjobs for turning on or off the display

MARK=TURN OFF
LINE="echo 1 | sudo tee /sys/class/backlight/rpi_backlight/bl_power # $MARK"
# NOTE: I'm using -e because I might want to avoid weird bash expansions for '*' or '$' and place:
# \x2A instead of *
# \x24 instead of $
( crontab -l | grep -v $MARK ; echo -e "0 23 * * *" $LINE ) | crontab -

MARK=TURN ON
LINE="echo 0 | sudo tee /sys/class/backlight/rpi_backlight/bl_power # $MARK"
( crontab -l | grep -v $MARK ; echo -e "0 8 * * *" $LINE ) | crontab -



# sudo reboot