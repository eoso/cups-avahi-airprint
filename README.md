# eoso/cups-avahi-airprint 

Fork from [chuckcharlie/cups-avahi-airprint](https://github.com/chuckcharlie/cups-avahi-airprint)
Which was a Fork from [quadportnick/docker-cups-airprint](https://github.com/quadportnick/docker-cups-airprint)

This also uses much of the Dockerfile from [olbat/dockerfiles](https://github.com/olbat/dockerfiles/tree/master/cupsd)

### Changes
This is honestly mostly a kludge that works for my purposes.
I needed a cups server that supported airprint and could run on an RaspberryPi. The project this is forked functioned almost 
perfectly. The specific ancient HP printer I use requires the hp-plugin drivers. I couldn't get the drivers to install in alpine 
(could be user error - I'll document some of the info I found below). I used debian and a dependency list with an updated cups 
version from [olbat/dockerfiles](https://github.com/olbat/dockerfiles/tree/master/cupsd) which mostly worked. 

Next steps were to install an older python version (3.11) which the hp-plugin installation requires. After that, downloading the
driver files solved the issue. 

The hp-plugin installation was where alpine caused me issues - I wasn't able to get python3.11 installed without messing up the
system python. I also couldn't compile from sources and suspect with more tinkering, this would be possible. If it is possible,
hp-plugin installation should be doable in alpine with:
```
echo -ne '\n' | python3.11 /usr/share/hplip/check-plugin.py -p /plugin-files
```

Either debian or alpine, hp-plugin install requires downloading the HP plugin files because the downloader seems to be broken 
(or possibly CLI tools are blocked on the [HP download page](https://developers.hp.com/hp-linux-imaging-and-printing/plugins). 
Both the `.run` and `.run.asc` need to be downloaded into `./root/plugin-files/`. At time of writing, the files needed are 
`hplip-3.22.10-plugin.run` and `hplip-3.22.10-plugin.run.asc`.


## Configuration

Clone this repo to a directory for building the docker image (since it requires the hp-plugin files, I won't upload it to
docker hub).

In the project directory, download the above hp-plugins into the `./root/plugin-files/` dir.

Build the image:
```
docker build . -t localhost/hp-plugin-cups-avahi
```

### Volumes:
* `/config`: where the persistent printer configs will be stored
* `/services`: where the Avahi service files will be generated

### Variables:
* `CUPSADMIN`: the CUPS admin user you want created - default is CUPSADMIN if unspecified
* `CUPSPASSWORD`: the password for the CUPS admin user - default is the same value as `CUPSADMIN` if unspecified

### Ports/Network:
* Must be run on host network. This is required to support multicasting which is needed for Airprint.

### Example docker compose config for running on an RaspberryPi:
```
services:
  cups:
    image: localhost/hp-plugin-cups-avahi:latest
    container_name: cups
    network_mode: host
    devices:
      - /dev/bus/usb/001
      - /dev/bus/usb/002
    volumes:
      - </your/services/dir>:/services
      - </your/config/dir>:/config
      - /var/run/dbus:/var/run/dbus
    environment:
      CUPSADMIN: "<YourAdminUsername>"
      CUPSPASSWORD: "<YourPassword>"
    restart: unless-stopped
```

## Add and set up printer:
* CUPS will be configurable at http://[host ip]:631 using the CUPSADMIN/CUPSPASSWORD.
* Make sure you select `Share This Printer` when configuring the printer in CUPS.
* ***After configuring your printer, you need to close the web browser for at least 60 seconds. CUPS will not write the config files until it detects the connection is closed for as long as a minute.***

## Fix sharing after adding printer:
The version of cups at writing has an issue with configuring printers to share. This can be fixed from the lpadmin CLI. First, list printers:
```
docker exec cups lpstat -p
```
Then add the printer name (this will be the second field in the above output):
```
docker exec cups lpadmin -p <printer-name> -o printer-is-shared=true
```

Wait 60 seconds for cups to refresh the files. It will have succeeded when the printer has `Shared yes` in `./config/printers.conf`. This should cause printer-update.sh to 
pick up the changes and write to ./services/ which should enable airprint.
