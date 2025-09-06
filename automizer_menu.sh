#!/bin/sh
set -eu

# ====== Uprawnienia: doas -> sudo -> błąd ======
if [ "$(id -u)" -ne 0 ]; then
    if command -v doas >/dev/null 2>&1; then
        exec doas "$0" "$@"
    elif command -v sudo >/dev/null 2>&1; then
        exec sudo "$0" "$@"
    else
        echo "❌ Wymagane uprawnienia administratora (brak doas/sudo). Uruchom jako root."
        exit 1
    fi
fi

# ====== Wymagane narzędzia ======
need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Brak programu: $1"; exit 1; }; }
need cbmctrl
need cbmcopy
need cbmformat
need d64copy

QUIET=0
FORCE=0
DRIVE=""
IN=""
OUT=""
DISKNAME=""
DISKID=""
FORMATTER="cbmformat"

usage() {
cat <<'EOF'
Użycie:
  automizer_menu.sh [opcje]

Możesz wybrać z menu interaktywnego lub użyć komend:
  menu                - wywołuje menu wyboru akcji (domyślne przy starcie bez argumentów)
  detect              - wykryj urządzenia IEC (cbmctrl detect)
  status              - pokaż status stacji (cbmctrl status NR)
  reset               - reset magistrali IEC (cbmctrl reset)
  read    [...]       - odczyt dysku/plików z dyskietki → plik (.d64, .prg, ...)
  write   [...]       - zapis pliku .d64 → dyskietka
  write-prg [...]     - zapis PRG do stacji
  format  [...]       - formatuj dyskietkę
  d64copy [...]       - kopiuj .d64 korzystając z d64copy
  exit                - zakończ program

Opcje ogólne (do komend po nazwie komendy):
  -d, --drive NR      - numer stacji (domyślnie: 8)
  -i, --in  PLIK      - plik wejściowy (.d64 lub .prg)
  -o, --out PLIK      - plik wyjściowy (.d64/.prg/...)
  -f, --force         - nadpisz istniejący plik wyjściowy
  -n, --name NAZWA    - nazwa dysku (formatowanie)
  --diskid ID         - ID dysku (formatowanie)
  --formatter TYP     - narzędzie formatowania: cbmformat lub d64copy
  -q, --quiet         - mniej logów
  -h, --help          - pomoc

Na starcie pojawia się menu wielokrotnego wyboru!
EOF
}

log() { [ "$QUIET" = "1" ] || echo "$@"; }

auto_detect_drive() {
    nr="$(cbmctrl detect | sed -n 's/^\([0-9][0-9]*\):.*/\1/p' | head -n1 || true)"
    [ -n "$nr" ] && echo "$nr" || echo 8
}

ensure_drive() {
    if [ -z "$DRIVE" ]; then
        DRIVE="$(auto_detect_drive || echo 8)"
        [ -z "$DRIVE" ] && DRIVE=8
        log "🧭 Ustawiam numer stacji: $DRIVE"
    fi
}

# ====== Główne MENU INTERAKTYWNE (pętla!) ======
show_menu() {
while true; do
    echo
    echo -e "\033[1;34m===== \033[1;31mOpenCBM \033[1;37mC64 \033[1;36mAutomizer Menu v.0.0.1 alpha \033[1;34m=====\033[0m\n"
    # --- AUTOR (turkusowy) ---
    echo -e "\033[36m * Created by TinkerWheel - bofh@retro-technology.pl\033[0m"
    echo -e "\033[36m * Wszystko dla retro, retro dla wszystkich! :)\033[0m"
    echo -e "\033[36m * Niech transfer bajtów będzie z Wami.\033[0m\n"
    echo -e "\033[36m - Bash doesn’t ask, bash executes. -\033[0m\n"
    echo -e "\033[36m - Think before you act. - \033[0m\n"
    echo -e "\033[36m - [Komputer] --USB--> [XUM1541] --IEC--> [C64 1541 II]\033[0m\n"
    echo -e "\e[32m1.\e[0m Wykryj stacje (detect)"
    echo -e "\e[32m2.\e[0m Status stacji"
    echo -e "\e[32m3.\e[0m Reset IEC"
    echo -e "\e[32m4.\e[0m Wyświetl pliki na dyskietce (listing cbmctrl dir)"
    echo -e "\e[32m5.\e[0m Zapisz .d64 na dyskietkę"
    echo -e "\e[32m6.\e[0m Zapisz program PRG"
    echo -e "\e[32m7.\e[0m Formatuj dyskietkę"
    echo -e "\e[32m8.\e[0m Użyj d64copy (kopiuj .d64 lub dysk ←→ plik)"
    echo -e "\e[32m9.\e[0m Pomoc"
    echo -e "\e[32m0.\e[0m Wyjście"
    
    printf "Wybierz opcję [0-9]: "
    read -r CHOICE
    case "$CHOICE" in
        1)
            log "🔎 Wykrywanie urządzeń (cbmctrl detect)"
            cbmctrl detect || true
            ;;
        2)
            read -p "Numer stacji (Enter = domyślnie 8): " nr
            [ -z "$nr" ] && nr=8
            log "📟 Status stacji $nr"
            cbmctrl status "$nr" || true
            ;;
        3)
            log "♻️  Reset magistrali (cbmctrl reset)"
            cbmctrl reset
            ;;
        4)
            read -p "Numer stacji (Enter = domyślnie 8): " nr
            [ -z "$nr" ] && nr=8
            log "🗂️  Listing plików na dyskietce (cbmctrl dir $nr)"
            cbmctrl dir "$nr"
            ;;
        5)
            echo "Podaj ścieżkę do pliku .d64 do zapisu na dyskietkę."
            read -p "Plik .d64 (Enter = anuluj): " d64file
            if [ -z "$d64file" ]; then
                echo "Anulowano wybór pliku."
                continue
            fi
            if [ ! -f "$d64file" ]; then
                echo "❌ Plik nie istnieje: $d64file"
                continue
            fi
            read -p "Numer stacji (Enter = domyślnie 8): " nr
            [ -z "$nr" ] && nr=8

            log "🔧 Reset magistrali (cbmctrl reset)"; cbmctrl reset
            log "🔎 Wykrywanie stacji (cbmctrl detect)"; cbmctrl detect || true
            log "📟 Status stacji $nr"; cbmctrl status "$nr" || true
            log "📤 Zapis obrazu $d64file → stacja $nr (cbmcopy -w $nr $d64file)"
            # Dodano: potwierdzenie przed faktycznym nagraniem:
            read -p "Czy na pewno nagrać plik '$d64file' na stację $nr? (y/N): " go
            if [ "$go" = "y" ] || [ "$go" = "Y" ]; then
                log "⏳ Trwa kopiowanie... (to może potrwać)"
                cbmcopy -w "$nr" "$d64file"
                RESULT=$?
                if [ $RESULT -eq 0 ]; then
                    log "✅ Zapis zakończony."
                else
                    echo "❌ Błąd zapisu przez cbmcopy! Kod: $RESULT"
                fi
            else
                echo "Anulowano zapisywanie."
            fi
            ;;
        6)
            read -p "Numer stacji (Enter = domyślnie 8): " nr
            [ -z "$nr" ] && nr=8
            read -p "Plik .prg: " in
            if [ ! -f "$in" ]; then
                echo "❌ Plik nie istnieje: $in"
                continue
            fi
            log "🔧 Reset magistrali (cbmctrl reset)"; cbmctrl reset
            log "📟 Status stacji $nr"; cbmctrl status "$nr" || true
            log "📤 Zapis programu $in → stacja $nr (cbmcopy -w $nr $in)"
            cbmcopy -w "$nr" "$in"
            RESULT=$?
            if [ $RESULT -eq 0 ]; then
                log "✅ Program nagrany."
            else
                echo "❌ Błąd zapisu przez cbmcopy! Kod: $RESULT"
            fi
            ;;
        7)
            read -p "Numer stacji (Enter = domyślnie 8): " nr; [ -z "$nr" ] && nr=8
            read -p "Nazwa dysku: " name
            read -p "ID dysku (np. 42): " id
            read -p "Formatter: cbmformat (Enter)/d64copy: " frmt
            [ -z "$frmt" ] && frmt="cbmformat"
            log "📟 Formatowanie dysku w stacji $nr: nazwa='$name', id='$id', formatter=$frmt"
            if [ "$frmt" = "cbmformat" ]; then
                cbmformat -x "$nr" "$name","$id"
            elif [ "$frmt" = "d64copy" ]; then
                d64copy --format "$name/$id" "$nr"
            else
                echo "❌ Nieznany formatter: $frmt"
                continue
            fi
            log "✅ Formatowanie zakończone."
            ;;
        8)
            read -p "Numer stacji (Enter = domyślnie 8): " nr; [ -z "$nr" ] && nr=8
            read -p "Plik wejściowy (.d64, Enter jeśli kopia z fizycznej): " in
            read -p "Plik wyjściowy (.d64, Enter jeśli kopia na fizyczną): " out
            if [ -n "$in" ] && [ -n "$out" ]; then
                log "🗂️  Kopiowanie pliku d64copy $in $out"
                d64copy "$in" "$out"
                log "✅ Gotowe: $out"
            elif [ -n "$in" ]; then
                log "📤 d64copy: $in → stacja $nr"
                d64copy "$in" "$nr"
                log "✅ Gotowe."
            elif [ -n "$out" ]; then
                log "📥 d64copy: stacja $nr → $out"
                d64copy "$nr" "$out"
                log "✅ Gotowe."
            else
                echo "❌ Podaj -i plik.d64 lub -o plik.d64!"
            fi
            ;;
        9) usage;;
        0) echo "Bye!"; exit 0;;
        *) echo "Nieznana opcja!" ;;
    esac
    echo
    read -p "Naciśnij Enter, aby wrócić do menu..." dummy
done
}

# ====== Odczyt dyskietki: ======
menu_read_disk_fixed() {
    local use_drive="$1"
    local use_out="$2"
    ext="$(echo "$use_out" | awk -F. '{print tolower($NF)}')"
    log "🔧 Reset magistrali (cbmctrl reset)"; cbmctrl reset
    log "🔎 Wykrywanie stacji (cbmctrl detect)"; cbmctrl detect || true
    log "📟 Status stacji $use_drive"; cbmctrl status "$use_drive" || true
    if [ "$ext" = "d64" ]; then
        log "📥 Kopiowanie całej dyskietki → $use_out (cbmcopy $use_drive $use_out)"
        cbmcopy "$use_drive" "$use_out"
        log "✅ Zakończono. Plik zapisany: $use_out"
    else
        log "🗂️  Pobieranie listy plików na dyskietce..."
        mapfile -t files < <(cbmctrl dir "$use_drive" | awk 'NR>1{gsub(/^ /, "", $0); fname=substr($0, 1, 16); sub(/ *$/, "", fname); if(fname!="") print fname;}')
        count="${#files[@]}"
        if [ "$count" -eq 0 ]; then
            echo "❌ Brak plików na dyskietce!"
            return
        fi

        echo ""
        echo "Pliki na dyskietce:"
        for idx in $(seq 0 $((count - 1))); do
            printf "  %d. %s\n" $((idx + 1)) "${files[$idx]}"
        done

        sel_file=""
        if [ "$count" -eq 1 ]; then
            sel_file="${files[0]}"
            echo "Wybrano jedyny plik: $sel_file"
        else
            while true; do
                read -p "Podaj numer pliku do odczytu lub nazwę: " filenum
                if echo "$filenum" | grep -E '^[0-9]+$' >/dev/null && [ "$filenum" -ge 1 ] && [ "$filenum" -le "$count" ]; then
                    sel_file="${files[$((filenum - 1))]}"
                    break
                else
                    # Spróbuj po nazwie
                    for idx in $(seq 0 $((count - 1))); do
                        [ "$filenum" = "${files[$idx]}" ] && sel_file="${files[$idx]}"
                    done
                    [ -n "$sel_file" ] && break
                    echo "Nieprawidłowy numer/nazwa."
                fi
            done
        fi
        log "📥 Odczyt pliku \"$sel_file\" do $use_out (cbmcopy -r \"$sel_file\" $use_drive $use_out)"
        cbmcopy -r "$sel_file" "$use_drive" "$use_out"
        log "✅ Zakończono. Plik zapisano: $use_out"
    fi
}

# ====== Tryb komend oraz uruchamianie menu jako domyślna opcja ======

CMD="${1:-}"
[ $# -gt 0 ] && shift || true

while [ $# -gt 0 ]; do
    case "$1" in
        -d|--drive)    DRIVE="$2"; shift 2;;
        -i|--in)       IN="$2"; shift 2;;
        -o|--out)      OUT="$2"; shift 2;;
        -f|--force)    FORCE=1; shift;;
        -q|--quiet)    QUIET=1; shift;;
        -n|--name)     DISKNAME="$2"; shift 2;;
        --diskid)      DISKID="$2"; shift 2;;
        --formatter)   FORMATTER="$2"; shift 2;;
        -h|--help)     usage; exit 0;;
        menu)          show_menu; exit 0;;
        exit)          exit 0;;
        *) CMD="${CMD:-$1}"; shift;;
    esac
done

# Jeśli nie podano komendy, uruchom interaktywne menu na starcie
[ -z "${CMD:-}" ] && show_menu

case "$CMD" in
    detect)
        log "🔎 Wykrywanie urządzeń (cbmctrl detect)"
        cbmctrl detect || true
        ;;
    status)
        ensure_drive
        log "📟 Status stacji $DRIVE (cbmctrl status $DRIVE)"
        cbmctrl status "$DRIVE" || true
        ;;
    reset)
        log "♻️  Reset magistrali (cbmctrl reset)"
        cbmctrl reset
        ;;
    read)
        ensure_drive
        [ -z "${OUT:-}" ] && OUT="disk_${DRIVE}_$(date +%Y%m%d_%H%M%S).d64"
        menu_read_disk_fixed "$DRIVE" "$OUT"
        ;;
    write)
        ensure_drive
        if [ -z "$IN" ]; then echo "❌ Brak pliku wejściowego. Użycie: write -i PLIK.d64 [-d NR]"; exit 1; fi
        if [ ! -f "$IN" ]; then echo "❌ Plik nie istnieje: $IN"; exit 1; fi
        log "🔧 Reset magistrali (cbmctrl reset)"; cbmctrl reset
        log "🔎 Wykrywanie stacji (cbmctrl detect)"; cbmctrl detect || true
        log "📟 Status stacji $DRIVE"; cbmctrl status "$DRIVE" || true
        log "📤 Zapis obrazu $IN → stacja $DRIVE (cbmcopy $DRIVE $IN)"
        cbmcopy "$DRIVE" "$IN"
        log "✅ Zapis zakończony."
        ;;
    write-prg)
        if [ -z "$IN" ]; then echo "❌ Brak pliku wejściowego. Użycie: write-prg -i PLIK.prg [-d NR]"; exit 1; fi
        if [ ! -f "$IN" ]; then echo "❌ Plik nie istnieje: $IN"; exit 1; fi
        log "🔧 Reset magistrali (cbmctrl reset)"; cbmctrl reset
        log "📟 Status stacji $DRIVE"; cbmctrl status "$DRIVE" || true
        log "📤 Zapis programu $IN → stacja $DRIVE (cbmcopy -w $DRIVE $IN)"
        cbmcopy -w "$DRIVE" "$IN"
        log "✅ Program nagrany."
        ;;
    format)
        if [ -z "$DISKNAME" ]; then echo "❌ Brak nazwy dysku! Użycie: format -d NR -n NAZWA -i ID"; exit 1; fi
        if [ -z "$DISKID" ]; then echo "❌ Brak ID dysku! Użycie: format -d NR -n NAZWA -i ID"; exit 1; fi
        log "📟 Formatowanie dysku w stacji $DRIVE: nazwa='$DISKNAME', id='$DISKID', formatter=$FORMATTER"
        if [ "$FORMATTER" = "cbmformat" ]; then
            cbmformat -x "$DRIVE" "$DISKNAME","$DISKID"
        elif [ "$FORMATTER" = "d64copy" ]; then
            d64copy --format "$DISKNAME/$DISKID" "$DRIVE"
        else
            echo "❌ Nieznany formatter: $FORMATTER"
            exit 1
        fi
        log "✅ Formatowanie zakończone."
        ;;
    d64copy)
        ensure_drive
        [ -n "$IN" ] || [ -n "$OUT" ] || { echo "❌ Podaj -i plik.d64 lub -o plik.d64!"; exit 1; }
        if [ -n "$IN" ] && [ -n "$OUT" ]; then
            log "🗂️  Kopiowanie pliku d64copy $IN $OUT"
            d64copy "$IN" "$OUT"
            log "✅ Gotowe: $OUT"
        elif [ -n "$IN" ]; then
            log "📤 d64copy: $IN → stacja $DRIVE"
            d64copy "$IN" "$DRIVE"
            log "✅ Gotowe."
        elif [ -n "$OUT" ]; then
            log "📥 d64copy: stacja $DRIVE → $OUT"
            d64copy "$DRIVE" "$OUT"
            log "✅ Gotowe."
        fi
        ;;
    -h|--help)
        usage
        ;;
    *)
        echo "❌ Nieznana komenda: $CMD"
        usage
        exit 1
        ;;
esac
