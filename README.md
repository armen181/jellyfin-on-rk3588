# Jellyfin Installation on Orange Pi 5 with Armbian

This guide documents the process of setting up **Jellyfin** on an **Orange Pi 5** using the Armbian image `Armbian_24.2.1_Orangepi5_jammy_legacy_5.10.160_minimal.img.xz`. It also includes optional steps to configure an NVMe drive for storage and set up **Transmission** for downloading media.

---

## Prerequisites
- Orange Pi 5 with Armbian installed and running.
- Internet access.

## Step 1: Installing Jellyfin

1. Add the necessary repositories:
   ```bash
   sudo add-apt-repository ppa:liujianfeng1994/panfork-mesa
   sudo add-apt-repository ppa:liujianfeng1994/rockchip-multimedia
   ```

2. Update and upgrade the system:
   ```bash
   sudo apt update
   sudo apt dist-upgrade
   ```

3. Install required libraries and firmware:
   ```bash
   sudo apt install libv4l-0
   sudo apt install mali-g610-firmware rockchip-multimedia-config
   ```

4. Install Jellyfin:
   ```bash
   curl https://repo.jellyfin.org/install-debuntu.sh | sudo bash
   ```

5. If you are using Joshua's Ubuntu-Rockchip or Armbian Legacy 5.1 LTS, install the appropriate Mali library:
   ```bash
   wget https://github.com/tsukumijima/libmali-rockchip/releases/download/v1.9-1-2d267b0/libmali-valhall-g610-g13p0-gbm_1.9-1_arm64.deb
   sudo dpkg -i libmali-valhall-g610-g13p0-gbm_1.9-1_arm64.deb
   ```
   
   **For Armbian 6.1 LTS, use the following version:**
   ```bash
   wget https://github.com/tsukumijima/libmali-rockchip/releases/download/v1.9-1-55611b0/libmali-valhall-g610-g13p0-gbm_1.9-1_arm64.deb
   sudo dpkg -i libmali-valhall-g610-g13p0-gbm_1.9-1_arm64.deb
   ```

6. Add Jellyfin to the appropriate groups:
   ```bash
   sudo usermod -aG render jellyfin
   sudo usermod -aG video jellyfin
   sudo systemctl restart jellyfin
   ```

## Step 2: Configuring Device Permissions

1. Create the `udev` rules file:
   ```bash
   sudo nano /etc/udev/rules.d/99-rk-device-permissions.rules
   ```

2. Add the following content:
   ```bash
   KERNEL=="mpp_service", MODE="0660", GROUP="video" RUN+="/usr/bin/create-chromium-vda-vea-devices.sh"
   KERNEL=="rga", MODE="0660", GROUP="video"
   KERNEL=="system", MODE="0660", GROUP="video"
   KERNEL=="cma", MODE="0660", GROUP="video"
   KERNEL=="system-dma32", MODE="0666", GROUP="video"
   KERNEL=="system-uncached", MODE="0666", GROUP="video"
   KERNEL=="system-uncached-dma32", MODE="0666", GROUP="video" RUN+="/usr/bin/chmod a+rw /dev/dma_heap"
   ```

3. Verify RKMPP functionality:
   ```bash
   ls -l /dev | grep -E "mpp|rga|dri|dma_heap"
   sudo /usr/lib/jellyfin-ffmpeg/ffmpeg -v debug -init_hw_device rkmpp=rk -init_hw_device opencl=ocl@rk
   ```

---

## Step 3: Setting a Static IP Address

1. Modify the network configuration file:
   ```bash
   sudo nano /etc/network/interfaces
   ```

2. Add the following:
   ```bash
   auto eth0
   iface eth0 inet static
       address 192.168.1.10
       netmask 255.255.255.0
       gateway 192.168.1.1
       hwaddress ether 00:11:22:33:44:55
   ```

3. Restart the network service:
   ```bash
   sudo systemctl restart networking
   ```

---

## Step 4: Setting Up NVMe Drive for Storage

1. Identify the NVMe drive:
   ```bash
   lsblk
   ```
   Example output might show `nvme0n1` as the NVMe drive.

2. Partition the NVMe drive:
   ```bash
   sudo fdisk /dev/nvme0n1
   ```
   - Press `n` to create a new partition.
   - Accept defaults or specify custom size.
   - Press `w` to save changes.

3. Format the partition:
   ```bash
   sudo mkfs.ext4 /dev/nvme0n1p1
   ```

4. Create a mount point:
   ```bash
   sudo mkdir -p /mnt/nvme-storage
   ```

5. Mount the filesystem:
   ```bash
   sudo mount /dev/nvme0n1p1 /mnt/nvme-storage
   ```

6. Make the mount permanent:
   ```bash
   blkid /dev/nvme0n1p1
   sudo nano /etc/fstab
   ```
   Add:
   ```
   UUID=<your-uuid>   /mnt/nvme-storage   ext4   defaults   0   2
   ```

---

## Step 5: Installing and Configuring Transmission

1. Install Transmission daemon:
   ```bash
   sudo apt install transmission-daemon
   ```

2. Edit the Transmission configuration file:
   ```bash
   sudo nano /etc/transmission-daemon/settings.json
   ```
   Modify or add:
   ```json
   "rpc-whitelist": "127.0.0.1,192.168.1.*",
   "rpc-username": "armen",
   "rpc-password": "{4ac5f0f82b9eee54232b208e41068b78ccceab54",
   "download-dir": "/mnt/nvme-storage/transmission/completed",
   "incomplete-dir": "/mnt/nvme-storage/transmission/Downloads",
   "incomplete-dir-enabled": true,
   "script-torrent-done-enabled": true,
   "script-torrent-done-filename": "/mnt/nvme-storage/transmission/on_complete.sh"
   ```

   - **rpc-username**: The username for the Transmission Web UI login.
   - **rpc-password**: The password for the Web UI (in SHA1 encoded format).
   - **download-dir**: Directory where completed files will be stored.
   - **incomplete-dir**: Directory for incomplete downloads.
   - **script-torrent-done-filename**: Script to execute when a download completes.

3. Reload the Transmission service:
   ```bash
   sudo systemctl reload transmission-daemon
   ```

4. **Script for Sorting Downloaded Files**

Use the script file from repo and copy it into /mnt/nvme-storage/transmission/on_complete.sh then edit it:
   ```bash
   sudo nano /mnt/nvme-storage/transmission/on_complete.sh
   ```
   Add the following content change directories where you want to keep your libraries:
   ```bash
   #!/usr/bin/env bash
   
   DOWNLOAD_DIR="/mnt/nvme/data/transmission/completed"
   
   TV_DIR="/mnt/nvme/data/media/TVShows"
   MOVIES_DIR="/mnt/nvme/data/media/Movies"
   MUSIC_DIR="/mnt/nvme/data/media/Music"
   BOOKS_DIR="/mnt/nvme/data/media/Books"
   OTHER_DIR="/mnt/nvme/data/media/Others"
   
   mkdir -p "$TV_DIR" "$MOVIES_DIR" "$MUSIC_DIR" "$BOOKS_DIR" "$OTHER_DIR"
   
   move_to_dir() {
       mv "$1" "$2" && echo "Moved $1 to $2"
   }
   
   # File classification logic here...
   ```

5. Make the script executable:
   ```bash
   sudo chmod +x /mnt/nvme-storage/transmission/on_complete.sh
   ```
---

6. **Configure Jellyfin to Use Script Directories**

   In the **Jellyfin Web UI**, configure your libraries to point to the directories where the script organizes files:
   - `/mnt/nvme/data/media/TVShows`
   - `/mnt/nvme/data/media/Movies`
   - `/mnt/nvme/data/media/Music`
   - `/mnt/nvme/data/media/Books`
   - `/mnt/nvme/data/media/Others`
     
---

## Conclusion
At this point, Jellyfin is installed, your NVMe storage is configured, and Transmission is set up to download and organize media files. Enjoy your fully configured media server on Orange Pi 5!

---
