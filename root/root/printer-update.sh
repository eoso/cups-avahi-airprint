#!/bin/bash
inotifywait -m -e close_write,moved_to,create /etc/cups | 
while read -r directory events filename; do
	if [ "$filename" = "printers.conf" ]; then
		rm -rf /services/AirPrint-*.service
		/root/airprint-generate.py -d /services
		cp /etc/cups/printers.conf /config/printers.conf
		rsync -avh /services/ /etc/avahi/services/
	fi
	if [ "$filename" = "cupsd.conf" ]; then
		cp /etc/cups/cupsd.conf /config/cupsd.conf
	fi
done
