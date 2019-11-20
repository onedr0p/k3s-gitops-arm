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

## Configure and Flash

Update `config.txt` or `user-data.yml` as you see fit, add more `user-data.yml` files if you have more hosts. My `config.txt` disables hdmi, audio, wifi and bluetooth.

To use WiFi see [this](https://johnwyles.github.io/posts/setting-up-kubernetes-and-openfaas-on-a-raspberry-pi-cluster-using-hypriot/) blog post and adjust the `config.txt` and `user-data.yml` accordingly.

```bash
# Replace pik3s01 in the --userdata and --hostname flags
flash \
    --bootconf setup/hypriotos/config.txt \
    --userdata setup/hypriotos/user-data.yml \
    --hostname pik3s01 \
    ~/Downloads/hypriotos-rpi-v1.11.4.img
```
