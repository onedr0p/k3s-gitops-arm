# Ubuntu

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
    "http://cdimage.ubuntu.com/releases/eoan/release/ubuntu-19.10.1-preinstalled-server-arm64+raspi3.img.xz" \
    -o ~/Downloads/ubuntu-19.10.1-preinstalled-server-arm64+raspi3.img.xz

cd ~/Downloads
unxz -T 0 ~/Downloads/ubuntu-19.10.1-preinstalled-server-arm64+raspi3.img.xz
```

## Configure

Update [user-data.yml](../setup/ubuntu/user-data.yml) as you see fit, add more [user-data.yml](../setup/ubuntu/user-data.yml) files if you have more hosts.

## Flash

```bash
# Replace my-awesome-hostname in the --hostname flag
flash \
    --userdata setup/ubuntu/user-data.yml \
    --hostname my-awesome-hostname \
    ~/Downloads/ubuntu-19.10.1-preinstalled-server-arm64+raspi3.img
```

## Boot

Place the SD Card in your RPi and give the system 5 minutes to boot before trying to SSH in.
