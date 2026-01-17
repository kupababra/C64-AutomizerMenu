# 🖥️ OpenCBM C64 Automizer Menu v0.0.1 alpha

*Created by TinkerWheel – id3fix@retro-technology.pl*  
*Everything for retro, retro for everyone! :)*  
*May the byte transfer be with you.*

---

> - Bash doesn’t ask, bash executes. -  
> - Think before you act. -  

---

## 🔗 Connection diagram

```
[Computer] --USB--> [XUM1541] --IEC--> [C64 1541 II]
```

---

## ⚡ Program Features

1. **Detect drives** – checks connected 1541 II drives.  
2. **Drive status** – shows current status of the disk drive.  
3. **Reset IEC** – resets the IEC bus.  
4. **List disk files** – lists files using `cbmctrl dir`.  
5. **Write .d64 to diskette** – loads a disk image and writes to the drive.  
6. **Write PRG file** – writes a `.PRG` file to the diskette.  
7. **Format diskette** – prepares a disk for use.  
8. **Use d64copy** – copy `.d64` or whole disks (disk ↔ file).  
9. **Help** – displays options and instructions.  
0. **Exit** – closes the menu.

---

## 🐧 Linux Compatibility

C64-AutomizerMenu runs on Linux systems, such as Ubuntu, Debian, Slackware, or NetBSD. Required tools:

- `OpenCBM` – for communication with the 1541 II drive,
- `cbmctrl` – for disk operations,
- `bash` – to run scripts.
- `Legion Go` - works with handheld when connected via cable + USB-C to USB-A adapter <-cable-> USB-A to USB-C -> xum1541
---

## 💾 5.25" Disk (DD) Support

The program supports standard 5.25" Double Density (DD) disks for the Commodore 1541. You can:

- Create `.d64` disk images,
- Backup and write `.PRG` files,
- Format 5.25" disks on the 1541 II drive.

---

## 🚀 Installation & Usage

1. Make sure **bash**, **OpenCBM**, and **cbmctrl** are installed.  
2. Make scripts executable:
```bash
chmod +x *.sh
```
3. Run the program:
```bash
doas ./automizer_menu.sh
```

---

## 🤝 Contributing

Pull requests welcome!  
⭐ Star if you love retro computing.  
Ideas, suggestions, and improvements are always welcome.

---

> “Never go with the mainstream, choose your own path.”

