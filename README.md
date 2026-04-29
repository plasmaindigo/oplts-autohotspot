# oplts-autohotspot
A set of automatic hotspot for Orange Pi Zero LTS

**!!This project is made for the Orange Pi Zero LTS (H2+ CPU version, not H3 CPU version) running Armbian 25.5.1 Debian Bookworm (6.12.23_minimal)!!**
http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-Zero-LTS.html

<img width="1000" height="800" alt="zero-top" src="https://github.com/user-attachments/assets/cbf80ca1-8f61-49c6-8a68-72d04e777f59" />

The goal of this project is creating an "Auto Wifi/Hotspot Switcher" mode to an obsolete SBC which is Orange Pi Zero LTS (2016).


_**What does the scripts do?**_

**install-omnissiah.sh**

-> Enter your own WiFi settings so it can connect to the network for updates.

-> Enter your desired name and password for the hotspot which is going to be created.

-> Installs the required packages.

-> Sets up the required configuration files.

-> Adds the custom created script as a service.


**debug-omnissiah.sh**

-> Checks wifi interfaces.

-> Checks packages.

-> Checks configuration files.

-> Checks systemd services.

-> Detects current network state.

-> Logs if any problem/error has been found.


**repair-omnissiah.sh**

-> Let's the user choose which part of the program to repair.
