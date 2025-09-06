# 🖥️ OpenCBM C64 Automizer Menu v0.0.1 alpha

*Created by TinkerWheel – bofh@retro-technology.pl*  
*Wszystko dla retro, retro dla wszystkich! :)*  
*Niech transfer bajtów będzie z Wami.*

---

> - Bash doesn’t ask, bash executes. -  
> - Think before you act. -  

---

## 🔗 Schemat połączenia

```
[Komputer] --USB--> [XUM1541] --IEC--> [C64 1541 II]
```

---

## ⚡ Funkcje programu

1. **Wykryj stacje (detect)** – sprawdza podłączone stacje 1541 II.  
2. **Status stacji** – pokazuje aktualny stan stacji dyskietek.  
3. **Reset IEC** – resetuje magistralę IEC.  
4. **Wyświetl pliki na dyskietce** – listing za pomocą `cbmctrl dir`.  
5. **Zapisz .d64 na dyskietkę** – wczytuje obraz dysku i zapisuje na stacji.  
6. **Zapisz program PRG** – wgrywa plik `.PRG` na dyskietkę.  
7. **Formatuj dyskietkę** – przygotowuje dysk do użycia.  
8. **Użyj d64copy** – kopiowanie `.d64` lub całych dysków (disk ↔ file).  
9. **Pomoc** – wyświetla dostępne opcje i instrukcje.  
0. **Wyjście** – zamyka menu.

---

## 🚀 Instalacja i użycie

1. Upewnij się, że masz zainstalowany **bash** i **OpenCBM / cbmctrl**.  
2. Nadaj plikom prawa wykonywania:
```bash
chmod +x *.sh
```
3. Uruchom program:
```bash
./automizer_menu.sh
```

---

## 🤝 Contributing

Pull requests welcome!  
⭐ Star if you love retro computing.  
Pomysły, sugestie i poprawki są zawsze mile widziane.

---

> “Never go with the mainstream, choose your own path.”

