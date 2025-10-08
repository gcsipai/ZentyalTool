#!/bin/bash

# Zentyal 8.0 Karbantartó és Hibaelhárító Eszköz (Ubuntu 22.04 LTS)
# V3.0: Stabil Kiadás (Gyári Zentyal telepítésekhez)

MENU_TITLE="Zentyal Hibaelhárítás és Karbantartás (v3.0)"
# Host IP-címének lekérése
IP_ADDRESS=$(hostname -I | awk '{print $1}' | awk '{print $1}')

# Színek definiálása
GREEN='\033[0;32m'
ORANGE='\033[0;33m' # A narancssárga a standard shellben a SÁRGA (YELLOW) kódja.
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Színes kimenet függvények ---
print_green() {
    echo -e "${GREEN}$1${NC}"
}
print_orange() {
    echo -e "${ORANGE}$1${NC}"
}
print_yellow() {
    echo -e "${YELLOW}$1${NC}"
}
print_red() {
    echo -e "${RED}$1${NC}"
}

# -----------------------------------------------------------------
# --- FŐ FUNKCIÓK (A főmenü hívja) --------------------------------
# -----------------------------------------------------------------

# 1. Rendszer Felkészítés (Kompatibilitás és Alapszoftverek telepítése)
prepare_system() {
    echo -e "\n--- [1] Rendszer Felkészítés (Kompatibilitás & Alapszoftverek) ---"
    print_yellow "MEGJEGYZÉS: Ez a funkció *NEM* telepíti a Zentyalt, csak az alapvető hibaelhárító csomagokat."
    print_yellow "1. Csomaglisták frissítése (apt update)..."
    apt update
    if [ $? -ne 0 ]; then
        print_red "Hiba történt a csomaglisták frissítése során. Kérem ellenőrizze az internetkapcsolatot!"
        read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
        return 1
    fi

    print_yellow "\n2. Alapvető karbantartó szoftverek telepítése (unzip, zip, curl, htop, mc, bpytop)..."
    REQUIRED_PACKAGES="unzip zip curl htop mc bpytop"
    
    MISSING_PACKAGES=""
    for pkg in $REQUIRED_PACKAGES; do
        if ! dpkg -l | grep -q "^ii.* $pkg "; then
            MISSING_PACKAGES+="$pkg "
        fi
    done

    if [ -n "$MISSING_PACKAGES" ]; then
        print_green "Telepítendő csomagok: $MISSING_PACKAGES"
        apt install -y $MISSING_PACKAGES
        if [ $? -ne 0 ]; then
            print_red "Hiba történt a szoftverek telepítésekor."
        else
            print_green "Alapszoftverek sikeresen telepítve."
        fi
    else
        print_green "Minden alapszoftver már telepítve van."
    fi

    print_yellow "\n3. Zentyal kompatibilitás (NIC elnevezés) ellenőrzése..."
    if grep -q "net.ifnames=0" /etc/default/grub; then
        print_green "   ✅ Hálózati elnevezés (eth) kompatibilitás beállítva."
    else
        print_red "   ❌ A régi hálózati elnevezés (eth) nincs beállítva. Ez problémát okozhat a Zentyal konfigurációban."
        print_yellow "   A Javítás elvégezhető a főmenü 6. opciójával."
    fi

    print_green "\nRendszer felkészítés befejezve."
    print_yellow "Ezután futtassa a 2. opciót (Rendszerfrissítés) a tényleges csomagfrissítések elvégzéséhez!${NC}"
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 2. Rendszer és Zentyal Frissítés (Dist-Upgrade + Tisztítás)
system_zentyal_upgrade() {
    echo -e "\n--- [2] Teljes Zentyal Rendszerfrissítés (apt update & dist-upgrade) ---"
    
    print_yellow "1. Csomaglisták frissítése (apt update)..."
    apt update
    if [ $? -ne 0 ]; then
        print_red "Hiba történt a csomaglisták frissítése során. Kérem ellenőrizze az 1. pontot!"
        read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
        return 1
    fi
    
    echo -e "\n${YELLOW}2. Rendszer frissítése és Zentyal függőségek ellenőrzése (apt dist-upgrade)...${NC}"
    print_yellow "Ez a parancs eltávolíthat régebbi csomagokat. Figyelemmel kísérje a kimenetet!"
    
    apt dist-upgrade -y

    echo -e "\n${YELLOW}3. Tisztítás (autoremove és clean)...${NC}"
    apt autoremove -y
    apt clean

    print_green "Teljes Zentyal frissítés befejezve."
    echo -e "${YELLOW}Kérem, ellenőrizze a modulok állapotát, majd indítsa újra a rendszert, ha kernel vagy kritikus frissítés történt!${NC}"
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 3. Diagnosztika és Hibaelhárítás 🛠️
# Ez csak a menüt jeleníti meg, a funkciók lejjebb vannak definiálva (4.1, 4.2, stb.)
troubleshoot_zentyal() {
    while true; do
        clear
        echo -e "${ORANGE}=================================================${NC}"
        echo -e "${GREEN}        [3] Diagnosztika és Hibaelhárítás Menü${NC}"
        echo -e "${ORANGE}=================================================${NC}"
        echo "1. Zentyal Modulok és Fő Szolgáltatás Állapotának Ellenőrzése"
        echo "2. 📜 Zentyal és Modul Logok Megtekintése"
        echo "3. Port Ellenőrzés (ss)"
        echo "4. Konfigurációs Fájl Helyreállítás (make-all-config)"
        echo "5. Csomagok és Függőségek Kényszerített Javítása (apt --fix-broken)"
        echo "6. Hálózati Kapcsolatok Ellenőrzése"
        echo "7. Lemezterület Ellenőrzése"
        echo "8. Vissza a Főmenübe"
        echo -e "${ORANGE}-------------------------------------------------${NC}"
        
        read -r -p "Válassz egy diagnosztikai opciót [1-8]: " diag_choice
        
        case "$diag_choice" in
            1) check_module_status ;;
            2) view_zentyal_logs_menu ;; 
            3) check_ports ;;
            4) restore_config ;;
            5) fix_dependencies ;;
            6) check_network_connections ;;
            7) check_disk_space ;;
            8) return ;;
            *) echo -e "\n${RED}Érvénytelen választás, próbáld újra.${NC}" ; sleep 2 ;;
        esac
    done
}

# 4. Hálózati Információk
network_info() {
    echo -e "\n--- [4] Hálózati Információk ---"
    
    print_yellow "Helyi IP címek:"
    ip a | grep -E 'inet ' | awk '{print "  " $2}' | grep -v '127.0.0.1'
    
    echo -e "\n${YELLOW}Alapértelmezett átjáró (Gateway):${NC}"
    ip route | grep default | awk '{print "  " $3}'
    
    echo -e "\n${YELLOW}Hálózati interfészek (Állapot):${NC}"
    ip link show | grep -E '^[0-9]+:' | awk '{print "  " $2 " (" $9 ")"}'

    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 5. Rendszer újraindítása
reboot_system() {
    echo -e "\n${RED}!!! FIGYELEM - RENDSZER ÚJRAINDÍTÁS !!!${NC}"
    
    read -r -p "Biztosan újra akarod indítani a rendszert most? (i/n): " confirm
    if [[ "$confirm" =~ ^[iI]$ ]]; then
        print_yellow "A rendszer 5 másodperc múlva újraindul..."
        print_red "Mentsd el az összes munkádat mielőtt folytatod!"
        sleep 5
        reboot
    else
        print_green "Újraindítás megszakítva."
    fi
}

# 6. Hálózati interfész elnevezés javítása ('eth' sémára)
fix_nic_naming() {
    echo -e "\n--- [6] Hálózati Elnevezés Javítása ('eth' sémára) ---"
    
    print_yellow "Ez a funkció módosítja a GRUB beállításokat, hogy a hálózati interfészek 'eth0', 'eth1', stb. néven jelenjenek meg. Ez kritikus lehet a Zentyal megfelelő működéséhez."
    
    read -r -p "Biztosan módosítod a GRUB-ot és újraindítod a rendszert? (i/n): " confirm
    if [[ "$confirm" =~ ^[iI]$ ]]; then
        
        print_yellow "1. Módosítás a GRUB beállításban..."
        
        if grep -q "net.ifnames=0" /etc/default/grub; then
            print_green "   ✅ net.ifnames=0 biosdevname=0 már hozzáadva. Kihagyás."
        else
            # Keresd meg a GRUB_CMDLINE_LINUX_DEFAULT sort, és add hozzá a paramétereket
            sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"/\1 net.ifnames=0 biosdevname=0"/' /etc/default/grub
            print_green "   ✅ net.ifnames=0 biosdevname=0 hozzáadva."
        fi
        
        print_yellow "2. GRUB konfiguráció frissítése (update-grub)..."
        update-grub
        
        print_yellow "3. A rendszer újraindítása 5 másodperc múlva..."
        print_red "Mentsd el az összes munkádat!"
        sleep 5
        reboot
    else
        print_green "Módosítás megszakítva."
    fi
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}


# ----------------------------------------------------
# --- ALMENÜ FUNKCIÓK (A 3. Diagnosztika hívja) ---
# ----------------------------------------------------

# 3.1 Zentyal Modulok és Fő Szolgáltatás Állapotának Ellenőrzése
check_module_status() {
    echo -e "\n--- [3.1] Zentyal Modulok és Fő Szolgáltatás Állapotának Ellenőrzése ---"
    
    echo -e "\n${ORANGE}--- A Zentyal (ebox) Fő Szolgáltatás Állapota ---${NC}"
    if command -v systemctl &> /dev/null; then
        # Javított: idézőjelek hozzáadva a megbízhatóbb megjelenítéshez
        systemctl status ebox --no-pager
        MAIN_SERVICE_STATUS=$(systemctl is-active ebox 2>/dev/null)
        if [ "$MAIN_SERVICE_STATUS" == "active" ]; then
            print_green "  ✅ Fő Zentyal Szolgáltatás (ebox) FUT."
        else
            print_red "  ❌ Fő Zentyal Szolgáltatás (ebox) NEM FUT. (Aktuális állapot: $MAIN_SERVICE_STATUS)"
        fi
    else
        print_red "A systemctl parancs nem található. Kézi ellenőrzés szükséges."
    fi

    echo -e "\n${ORANGE}--- Telepített Zentyal Modulok Listája (dpkg) ---${NC}"
    INSTALLED_MODULES=$(dpkg -l 2>/dev/null | grep zentyal- | grep '^ii' | awk '{print $2}')
    
    if [ -z "$INSTALLED_MODULES" ]; then
        print_yellow "Nincsenek telepített Zentyal csomagok."
    else
        echo "A következő Zentyal modulok vannak telepítve:"
        for module in $INSTALLED_MODULES; do
            SERVICE_NAME=$(echo "$module" | sed 's/zentyal-/ebox-/')
            
            # Speciális esetek, amik önálló systemd egységek (egyszerűsített ellenőrzés)
            case "$module" in
                zentyal-antivirus|zentyal-ips|zentyal-openvpn|zentyal-samba) 
                    if systemctl is-active "$SERVICE_NAME" &> /dev/null; then
                        print_green "  ✅ $module (Service: $SERVICE_NAME) - FUT"
                    elif systemctl is-failed "$SERVICE_NAME" &> /dev/null; then
                        print_red "  ❌ $module (Service: $SERVICE_NAME) - HIBÁS (Failed)"
                    elif systemctl list-units --type=service --all 2>/dev/null | grep "$SERVICE_NAME.service" > /dev/null; then
                        print_yellow "  ⚠️ $module (Service: $SERVICE_NAME) - Inaktív/Leállítva"
                    else
                        echo "  ℹ️ $module (Kezelés a fő ebox folyamaton keresztül)"
                    fi
                    ;;
                *)
                    echo "  ℹ️ $module (Kezelés a fő ebox folyamaton keresztül)"
                    ;;
            esac
        done
    fi
    echo -e "\n${YELLOW}Segítség: Ha egy modul HIBÁS (Failed), ellenőrizze a logokat (3.2 opció) a hiba okáért.${NC}"
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 3.2 Zentyal és Modul Logok Megtekintése - ÚJ ALMENÜ
view_zentyal_logs_menu() {
    local INSTALLED_MODULES=$(dpkg -l 2>/dev/null | grep zentyal- | grep '^ii' | awk '{print $2}')
    local MODULE_COUNT=$(echo "$INSTALLED_MODULES" | wc -w)
    local LOG_MENU_CHOICE

    while true; do
        clear
        echo -e "${ORANGE}=================================================${NC}"
        echo -e "${GREEN}      [3.2] Zentyal és Modul Logok Megtekintése${NC}"
        echo -e "${ORANGE}=================================================${NC}"
        echo "1. Zentyal Fő Log (tail -f /var/log/zentyal/zentyal.log)"
        echo "2. Ebox Fő Szolgáltatás Log (journalctl -u ebox)"
        echo "3. Általános Rendszer Logok (Utolsó 20 hiba - journalctl -p err)"
        echo -e "${ORANGE}-------------------------------------------------${NC}"

        if [ "$MODULE_COUNT" -gt 0 ]; then
            print_yellow "Zentyal Modulok Logjai (Csak a Telepítettek):"
            local i=4
            local module_array=()
            for module in $INSTALLED_MODULES; do
                local module_short_name=$(echo "$module" | sed 's/zentyal-//')
                echo "$i. $module_short_name Modul Log (/var/log/zentyal/$module_short_name.log vagy systemd)"
                module_array+=("$module_short_name")
                i=$((i+1))
            done
            echo -e "${ORANGE}-------------------------------------------------${NC}"
            echo "$i. Vissza az Előző Menübe"
        else
            print_yellow "Nincsenek telepített Zentyal modulok."
            i=4 # A Vissza opció sorszáma
            echo "$i. Vissza az Előző Menübe"
        fi

        read -r -p "Válassz egy log opciót [1-$i]: " LOG_MENU_CHOICE

        case "$LOG_MENU_CHOICE" in
            1) view_zentyal_main_log ;;
            2) view_ebox_journal ;;
            3) view_system_error_logs ;;
            [4-9]|[1-9][0-9]*)
                local max_module_choice=$((i-1))
                if [ "$LOG_MENU_CHOICE" -ge 4 ] && [ "$LOG_MENU_CHOICE" -le "$max_module_choice" ] && [ "$MODULE_COUNT" -gt 0 ]; then
                    local index=$((LOG_MENU_CHOICE - 4))
                    view_module_log "${module_array[$index]}"
                elif [ "$LOG_MENU_CHOICE" -eq "$i" ]; then
                    return 0
                else
                    echo -e "\n${RED}Érvénytelen választás, próbáld újra.${NC}" ; sleep 2
                fi
                ;;
            *) echo -e "\n${RED}Érvénytelen választás, próbáld újra.${NC}" ; sleep 2 ;;
        esac
    done
}

# Modul Log megjelenítése
view_module_log() {
    local module_name="$1"
    local log_file="/var/log/zentyal/$module_name.log"
    local service_name="ebox-$module_name"

    echo -e "\n--- Modul Log: $module_name ---"
    
    if [ -f "$log_file" ]; then
        print_yellow "Log Fájl ($log_file) - Utolsó 50 sor:"
        echo -e "${ORANGE}---------------------------------------------------------------------${NC}"
        tail -n 50 "$log_file"
    elif systemctl list-units --type=service --all 2>/dev/null | grep -q "$service_name.service"; then
        print_yellow "Systemd Szolgáltatás Log ($service_name) - Utolsó 50 bejegyzés:"
        echo -e "${ORANGE}---------------------------------------------------------------------${NC}"
        journalctl -u "$service_name" --no-pager -n 50
    else
        print_yellow "Nincs dedikált log fájl ($log_file) vagy systemd szolgáltatás ($service_name) ehhez a modulhoz. Valószínűleg a fő ebox logban találhatók a bejegyzések (3.2.2 opció)."
    fi

    print_yellow "\nAz Enter billentyű megnyomásával visszatérhetsz a Log Menübe.${NC}"
    read -n 1 -s -r
}

# Ebox Fő Szolgáltatás Log
view_ebox_journal() {
    echo -e "\n--- [3.2.2] Ebox Fő Szolgáltatás Log (Journal) ---"
    print_yellow "A Zentyal fő szolgáltatásának (ebox) utolsó 50 log bejegyzése (1 órán belül):"
    echo -e "${ORANGE}---------------------------------------------------------------------${NC}"
    
    if command -v journalctl &> /dev/null; then
        journalctl -u ebox --since "1 hour ago" -n 50 --no-pager
    else
        print_red "Journalctl parancs nem található. Kézi ellenőrzés szükséges."
    fi
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# Zentyal Fő Log (tail -f)
view_zentyal_main_log() {
    echo -e "\n--- [3.2.1] Zentyal Fő Log (/var/log/zentyal/zentyal.log) ---"
    print_yellow "A 'tail -f' parancs indul, amely valós időben mutatja a logot. Kilépés: CTRL+C"
    echo -e "${ORANGE}---------------------------------------------------------------------${NC}"
    sleep 2
    if [ -f "/var/log/zentyal/zentyal.log" ]; then
        tail -f /var/log/zentyal/zentyal.log
    else
        print_red "A fő Zentyal log fájl (/var/log/zentyal/zentyal.log) nem található."
        sleep 2
    fi
}

# Általános Rendszer Hiba Logok
view_system_error_logs() {
    echo -e "\n--- [3.2.3] Általános Rendszer Logok (Journal Hiba) ---${NC}"
    print_yellow "Általános Rendszer Logok (Utolsó 20 hiba - 'journalctl -p err'):"
    echo -e "${ORANGE}---------------------------------------------------------------------${NC}"
    if command -v journalctl &> /dev/null; then
        journalctl -p err -n 20 --no-pager 2>/dev/null
    fi
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 3.3 Port Ellenőrzés
check_ports() {
    echo -e "\n--- [3.3] Hálózati Port Ellenőrzés (ss -tuln) ---"
    print_yellow "A futó TCP és UDP szolgáltatások, és az általuk használt portok listája:"
    echo -e "${ORANGE}---------------------------------------------------------------------${NC}"
    
    if command -v ss &> /dev/null; then
        ss -tuln
    else
        print_red "Az 'ss' parancs nem elérhető. Kézi netstat ellenőrzés szükséges."
        netstat -tuln 2>/dev/null
    fi

    echo -e "\n${YELLOW}Segítség: Ellenőrizze, hogy a szükséges portok (pl. 8443, 53, 25) LISTEN állapotban vannak-e.${NC}"
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 3.4 Konfigurációs Fájl Helyreállítás
restore_config() {
    echo -e "\n--- [3.4] Konfigurációs Fájl Helyreállítás ---"
    print_yellow "A Zentyal adatbázisában tárolt beállításokat újraírja a rendszerszintű fájlokba."
    
    read -r -p "Biztosan újra akarod generálni a Zentyal konfigurációs fájlokat? (i/n): " confirm
    if [[ "$confirm" =~ ^[iI]$ ]]; then
        if [ -x "/usr/share/zentyal/make-all-config" ]; then
            print_green "Konfiguráció újraírása..."
            /usr/share/zentyal/make-all-config
            if [ $? -eq 0 ]; then
                print_green "Újraírás befejezve. Ajánlott szolgáltatás újraindítás."
            else
                print_red "Hiba történt a make-all-config futtatása során."
            fi
        else
            print_red "A make-all-config parancs nem található. Lehetséges, hogy a Zentyal nincs telepítve."
        fi
    else
        print_yellow "Helyreállítás megszakítva."
    fi
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 3.5 Csomagok és Függőségek Kényszerített Javítása
fix_dependencies() {
    echo -e "\n--- [3.5] Csomagok és Függőségek Kényszerített Javítása ---"
    print_yellow "Ez a funkció megpróbálja javítani a hiányzó vagy hibás csomagfüggőségeket a 'apt --fix-broken install' paranccsal."
    
    read -r -p "Folytatod a csomagjavítást? (i/n): " confirm
    if [[ "$confirm" =~ ^[iI]$ ]]; then
        print_green "Csomagjavítás indítása..."
        apt --fix-broken install -y
        if [ $? -eq 0 ]; then
            print_green "Csomagfüggőségek javítása sikeresen befejeződött."
            echo -e "${YELLOW}Kérem, futtassa a 2. opciót (Frissítés) a rendszer teljes szinkronizálásához!${NC}"
        else
            print_red "A csomagfüggőségek javítása HIBÁVAL zárult. Ellenőrizze a kimenetet!"
        fi
    else
        print_yellow "Csomagjavítás megszakítva."
        sleep 1
    fi
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 3.6 Hálózati Kapcsolatok Ellenőrzése
check_network_connections() {
    echo -e "\n--- [3.6] Hálózati Kapcsolatok Ellenőrzése ---"
    print_yellow "Aktív hálózati kapcsolatok:"
    echo -e "${ORANGE}---------------------------------------------------------------------${NC}"
    
    if command -v ss &> /dev/null; then
        ss -tunp
    else
        netstat -tunp 2>/dev/null
    fi

    echo -e "\n${YELLOW}DNS felbontás teszt (google.com):${NC}"
    # Egyszerű nslookup ellenőrzés
    if nslookup google.com &> /dev/null; then
        print_green "  ✅ DNS felbontás sikeres."
    else
        print_red "  ❌ DNS felbontás sikertelen. Ellenőrizze a Zentyal DNS modulját!${NC}"
    fi
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 3.7 Lemezterület Ellenőrzése
check_disk_space() {
    echo -e "\n--- [3.7] Lemezterület Ellenőrzése ---"
    print_yellow "Rendelkezésre álló lemezterület (df -h):"
    echo -e "${ORANGE}---------------------------------------------------------------------${NC}"
    df -h | grep -E '^(Filesystem|/dev/|/mnt/|/media/)' # Csak a fájlrendszereket és a fejlécet mutatja

    echo -e "\n${YELLOW}Nagy fájlok keresése /var/log könyvtárban (felső 10, >10MB):${NC}"
    # Hibaüzeneteket elnyomjuk a tiszta kimenetért
    find /var/log -type f -size +10M -exec ls -lh {} \; 2>/dev/null | sort -k5 -hr | head -10

    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# --- Fő Menü Futtatás ---
show_menu() {
    while true; do
        clear
        echo -e "${GREEN}=====================================================${NC}"
        echo -e "${ORANGE}        ${MENU_TITLE}${NC}"
        echo -e "${RED}        Csak GYÁRI Zentyal telepítésekhez!${NC}"
        echo -e "${GREEN}=====================================================${NC}"
        echo -e "Aktuális IP: ${YELLOW}${IP_ADDRESS}${NC}"
        echo -e "${ORANGE}-----------------------------------------------------${NC}"
        echo "1. ⚡ Rendszer Felkészítés (Alapszoftverek telepítése)"
        echo "2. Rendszer és Zentyal Frissítés (apt update és dist-upgrade)"
        echo "3. 🛠️ Diagnosztika és Hibaelhárítás (Részletes menü)"
        echo "4. Hálózati Információk Megtekintése"
        echo "5. Rendszer Újraindítása (reboot)"
        echo "6. Hálózati Elnevezés Javítása ('eth' sémára) és Újraindítás"
        echo "0. Kilépés"
        echo -e "${ORANGE}-----------------------------------------------------${NC}"
        
        read -r -p "Válassz egy opciót [0-6]: " choice
        
        case "$choice" in
            1) prepare_system ;;
            2) system_zentyal_upgrade ;;
            3) troubleshoot_zentyal ;;
            4) network_info ;;
            5) reboot_system ;;
            6) fix_nic_naming ;;
            0) echo -e "\n${GREEN}Kilépés. Viszlát!${NC}" ; exit 0 ;;
            *) echo -e "\n${RED}Érvénytelen választás, próbáld újra.${NC}" ; sleep 2 ;;
        esac
    done
}

# Indítás ellenőrzés (Root-ot igényel)
if [[ $EUID -ne 0 ]]; then
    print_red "FIGYELEM: A script futtatásához root jogosultság szükséges!"
    print_yellow "Kérlek, futtasd a scriptet 'sudo ./zentyal-tool-v3.sh' paranccsal."
    exit 1
fi

# Főprogram indítása
print_green "Zentyal Karbantartó Eszköz indítása (ROOT módban, v3.0 - STABIL)..."
sleep 2
show_menu
