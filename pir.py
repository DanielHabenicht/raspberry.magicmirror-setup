import sys
import time
import RPi.GPIO as GPIO
import time
import requests
import json



SENSOR_PIN = 23
SHUTOFF_DELAY = 60

GPIO.setmode(GPIO.BCM)
GPIO.setup(SENSOR_PIN, GPIO.IN)


last_motion_time = time.time()

def callback(channel):
    global last_motion_time
    last_motion_time = time.time()
    url = 'http://192.168.178.40:8080/api/monitor/on?apiKey=4988fbcf-1d37-408b-a7a4-c69351d09f34'
    response = requests.get(url)
    print(response.status_code)

try:
    GPIO.add_event_detect(SENSOR_PIN , GPIO.RISING, callback=callback)
    while True:
        is_on = requests.get("http://192.168.178.40:8080/api/monitor/status?apiKey=4988fbcf-1d37-408b-a7a4-c69351d09f34").json()["monitor"] == "on"
        if is_on and time.time() > (last_motion_time + SHUTOFF_DELAY):
            response = requests.get("http://192.168.178.40:8080/api/monitor/off?apiKey=4988fbcf-1d37-408b-a7a4-c69351d09f34")
            print(response.status_code)
        time.sleep(.1)

except KeyboardInterrupt:
    print("Shutting down...")
GPIO.cleanup()


# Use the following system service: 
# [Unit]
# Description=PIR Screen Sleeper
# After=network.target
# StartLimitIntervalSec=0

# [Service]
# Type=simple
# Restart=always
# RestartSec=1
# User=pi
# WorkingDirectory=/home/pi
# ExecStart=/usr/bin/python /home/pi/pir.py

# [Install]
# WantedBy=multi-user.target