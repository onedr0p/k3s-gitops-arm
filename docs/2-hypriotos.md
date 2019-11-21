# HypriotOS

> All these commands are run from your computer, not the RPi.

## Downloads the Flash tool

```bash
sudo curl -L \
    "https://github.com/hypriot/flash/releases/download/2.3.0/flash" \
    -o /usr/local/bin/flash

sudo chmod +x /usr/local/bin/flash
```

## Download and extract the image

```bash
curl -L \
    "https://github.com/hypriot/image-builder-rpi/releases/download/v1.11.4/hypriotos-rpi-v1.11.4.img.zip" \
    -o ~/Downloads/hypriotos-rpi-v1.11.4.img.zip

unzip ~/Downloads/hypriotos-rpi-v1.11.4.img.zip -d ~/Downloads/
```

## Configure

Update [config.txt](../setup/hypriotos/config.txt) and [user-data.yml](../setup/hypriotos/user-data.yml) as you see fit, add more [user-data.yml](../setup/hypriotos/user-data.yml) files if you have more hosts. My [config.txt](../setup/hypriotos/config.txt) disables hdmi, audio, wifi, bluetooth and also overclocks the CPU just a bit.

To use WiFi see [this](https://johnwyles.github.io/posts/setting-up-kubernetes-and-openfaas-on-a-raspberry-pi-cluster-using-hypriot/) blog post and adjust the [config.txt](../setup/hypriotos/config.txt) and [user-data.yml](../setup/hypriotos/user-data.yml) accordingly.

## Flash

```bash
# Replace my-awesome-hostname in the --hostname flag
flash \
    --bootconf setup/hypriotos/config.txt \
    --userdata setup/hypriotos/user-data.yml \
    --hostname my-awesome-hostname \
    ~/Downloads/hypriotos-rpi-v1.11.4.img
```
