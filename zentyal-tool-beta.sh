#!/bin/bash

# Zentyal 8.0 Karbantartó és Hibaelhárító Eszköz (Ubuntu 22.04 LTS)
# V2.4 BETA: Rendszer felkészítés (Alapszoftverek és Kompatibilitás) 1. menüpont.

MENU_TITLE="Zentyal Hibaelhárítás és Karbantartás (BÉTA)"
# Host IP-címének lekérése
IP_ADDRESS=$(hostname -I | awk '{print $1}' | awk '{print $1}')

# Színek definiálása
GREEN='\033[0;32m'
ORANGE='\033[0;33m' # A narancssárga a standard shellben a SÁRGA (YELLOW) kódja.
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Függvények ---

# Színes kimenet függvények
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

# 1. Rendszer Felkészítés (Kompatibilitás és Alapszoftverek telepítése)
prepare_system() {
    echo -e "\n--- [1] Rendszer Felkészítés (Kompatibilitás & Alapszoftverek) ---"
    
    print_yellow "1. Csomaglisták frissítése (apt update)..."
    apt update
    if [ $? -ne 0 ]; then
        print_red "Hiba történt a csomaglisták frissítése során. Kérem ellenőrizze az internetkapcsolatot!"
        read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
        return 1
    fi

    # Alapvető szoftverek telepítése
    print_yellow "\n2. Alapvető karbantartó szoftverek telepítése (unzip, zip, curl, htop, mc, bpytop)..."
    REQUIRED_PACKAGES="unzip zip curl htop mc bpytop"
    
    # Csak azokat telepíti, amelyek hiányoznak
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

    # Zentyal kompatibilitási ellenőrzés (például a hálózati elnevezés javítása)
    print_yellow "\n3. Zentyal kompatibilitás (NIC elnevezés) ellenőrzése..."
    if grep -q "net.ifnames=0" /etc/default/grub; then
        print_green "   ✅ Hálózati elnevezés (eth) kompatibilitás beállítva."
    else
        print_red "   ❌ A régi hálózati elnevezés (eth) nincs beállítva."
        print_yellow "   A javítás elvégezhető a főmenü 7. opciójával (Hálózati Elnevezés Javítása)."
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


# 3. Zentyal Telepítés
install_zentyal() {
    echo -e "\n--- [3] Zentyal 8.0 Telepítés Indítása ---"
    
    if [ ! -f "zentyal_installer_8.0.sh" ]; then
        print_yellow "Telepítő script letöltése..."
        wget -q --timeout=30 --tries=3 https://raw.githubusercontent.com/zentyal/zentyal/master/extra/ubuntu_installers/zentyal_installer_8.0.sh
        if [ $? -ne 0 ]; then
            print_red "Hiba: Nem sikerült letölteni a telepítő scriptet."
            print_yellow "Ellenőrizd az internetkapcsolatot."
            sleep 3
            return
        fi
        chmod u+x zentyal_installer_8.0.sh
    fi
    
    chmod u+x zentyal_installer_8.0.sh

    print_green "Zentyal telepítő elindítása..."
    ./zentyal_installer_8.0.sh
    echo -e "\n${GREEN}Telepítés elindult. A webes felület elérhető itt:${NC}"
    print_green "https://${IP_ADDRESS}:8443/"
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 4. Diagnosztika és Hibaelhárítás 🛠️
troubleshoot_zentyal() {
    while true; do
        clear
        echo -e "${ORANGE}=================================================${NC}"
        echo -e "${GREEN}        [4] Diagnosztika és Hibaelhárítás Menü${NC}"
        echo -e "${ORANGE}=================================================${NC}"
        echo "1. Zentyal Modulok és Fő Szolgáltatás Állapotának Ellenőrzése"
        echo "2. Rendszer Logok (Journal) Megtekintése"
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
            2) view_system_logs ;;
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

# 5. Hálózati Információk
network_info() {
    echo -e "\n--- [5] Hálózati Információk ---"
    
    print_yellow "Helyi IP címek:"
    ip a | grep -E 'inet ' | awk '{print "  " $2}' | grep -v '127.0.0.1'
    
    echo -e "\n${YELLOW}Alapértelmezett átjáró (Gateway):${NC}"
    ip route | grep default | awk '{print "  " $3}'
    
    echo -e "\n${YELLOW}Hálózati interfészek (Állapot):${NC}"
    ip link show | grep -E '^[0-9]+:' | awk '{print "  " $2 " (" $9 ")"}'

    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 6. Rendszer újraindítása
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

# 7. Hálózati interfész elnevezés javítása ('eth' sémára)
fix_nic_naming() {
    echo -e "\n--- [7] Hálózati Elnevezés Javítása ('eth' sémára) ---"
    
    print_yellow "Ez a funkció módosítja a GRUB beállításokat, hogy a hálózati interfészek 'eth0', 'eth1', stb. néven jelenjenek meg. Ez kritikus lehet a Zentyal megfelelő működéséhez."
    
    read -r -p "Biztosan módosítod a GRUB-ot és újraindítod a rendszert? (i/n): " confirm
    if [[ "$confirm" =~ ^[iI]$ ]]; then
        
        print_yellow "1. Módosítás a GRUB beállításban..."
        sed -i 's/#GRUB_HIDDEN_TIMEOUT=0/GRUB_HIDDEN_TIMEOUT=0/' /etc/default/grub
        
        if grep -q "net.ifnames=0" /etc/default/grub; then
            print_green "   ✅ net.ifnames=0 biosdevname=0 már hozzáadva. Kihagyás."
        else
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


# --- Fő Menü Futtatás ---
show_menu() {
    while true; do
        clear
        echo -e "${GREEN}=====================================================${NC}"
        echo -e "${ORANGE}        ${MENU_TITLE}${NC}"
        echo -e "${GREEN}=====================================================${NC}"
        echo -e "Aktuális IP: ${YELLOW}${IP_ADDRESS}${NC}"
        echo -e "${ORANGE}-----------------------------------------------------${NC}"
        echo "1. ⚡ Rendszer Felkészítés (Kompatibilitás, Alapszoftverek telepítése)"
        echo "2. Rendszer és Zentyal Frissítés (apt update és dist-upgrade)"
        echo "3. Zentyal 8.0 Telepítése (Ubuntu 22.04-re)"
        echo "4. 🛠️ Diagnosztika és Hibaelhárítás (Részletes menü)"
        echo "5. Hálózati Információk Megtekintése"
        echo "6. Rendszer Újraindítása (reboot)"
        echo "7. Hálózati Elnevezés Javítása ('eth' sémára) és Újraindítás"
        echo "0. Kilépés"
        echo -e "${ORANGE}-----------------------------------------------------${NC}"
        
        read -r -p "Válassz egy opciót [0-7]: " choice
        
        case "$choice" in
            1) prepare_system ;;
            2) system_zentyal_upgrade ;;
            3) install_zentyal ;;
            4) troubleshoot_zentyal ;;
            5) network_info ;;
            6) reboot_system ;;
            7) fix_nic_naming ;;
            0) echo -e "\n${GREEN}Kilépés. Viszlát!${NC}" ; exit 0 ;;
            *) echo -e "\n${RED}Érvénytelen választás, próbáld újra.${NC}" ; sleep 2 ;;
        esac 
    done
}

# ----------------------------------------------------
# --- ALMENÜ FUNKCIÓK (4. Diagnosztika menüpont) ---
# ----------------------------------------------------

# 4.1 Zentyal Modulok és Fő Szolgáltatás Állapotának Ellenőrzése
check_module_status() {
    echo -e "\n--- [4.1] Zentyal Modulok és Fő Szolgáltatás Állapotának Ellenőrzése ---"
    
    echo -e "\n${ORANGE}--- A Zentyal (ebox) Fő Szolgáltatás Állapota ---${NC}"
    if command -v systemctl &> /dev/null; then
        systemctl status ebox --no-pager | head -n 10
        MAIN_SERVICE_STATUS=$(systemctl is-active ebox 2>/dev/null)
        if [ "$MAIN_SERVICE_STATUS" == "active" ]; then
            print_green "  ✅ Fő Zentyal Szolgáltatás (ebox) FUT."
        else
            print_red "  ❌ Fő Zentyal Szolgáltatás (ebox) NEM FUT. (Aktuális állapot: $MAIN_SERVICE_STATUS)"
        fi
    else
        print_yellow "A systemctl parancs nem található."
    fi

    echo -e "\n${ORANGE}--- Telepített Zentyal Modulok Listája (dpkg) ---${NC}"
    INSTALLED_MODULES=$(dpkg -l 2>/dev/null | grep zentyal- | grep '^ii' | awk '{print $2}')
    if [ -z "$INSTALLED_MODULES" ]; then
        print_yellow "Nincsenek telepített Zentyal csomagok."
    else
        echo "A következő Zentyal modulok vannak telepítve:"
        for module in $INSTALLED_MODULES; do
            SERVICE_NAME=$(echo "$module" | sed 's/zentyal-/ebox-/')
            if systemctl is-active "$SERVICE_NAME" &> /dev/null; then
                 print_green "  ✅ $module (Service: $SERVICE_NAME) - FUT"
            elif systemctl is-failed "$SERVICE_NAME" &> /dev/null; then
                 print_red "  ❌ $module (Service: $SERVICE_NAME) - HIBÁS (Failed)"
            elif systemctl list-units --type=service --all 2>/dev/null | grep "$SERVICE_NAME.service" > /dev/null; then
                 print_yellow "  ⚠️ $module (Service: $SERVICE_NAME) - Inaktív/Leállítva"
            else
                 echo "  ℹ️ $module (Kezelés a fő ebox folyamaton keresztül)"
            fi
        done
    fi
    echo -e "\n${YELLOW}Segítség: Ha egy modul HIBÁS (Failed), ellenőrizze a logokat (4.2 opció) a hiba okáért.${NC}"
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 4.2 Rendszer Logok Megtekintése
view_system_logs() {
    echo -e "\n--- [4.2] Rendszer Logok (Journal) Megtekintése ---"
    print_yellow "A Zentyal szolgáltatások (ebox) utolsó 50 log bejegyzése (1 órán belül):"
    echo -e "${ORANGE}---------------------------------------------------------------------${NC}"
    if systemctl is-active ebox &> /dev/null; then
        journalctl -u ebox --since "1 hour ago" -n 50 --no-pager
    else
        print_yellow "Az ebox szolgáltatás nem fut, általános logok megjelenítése..."
    fi
    echo -e "\n${ORANGE}--- Általános Rendszer Logok (Utolsó 20 hiba) ---${NC}"
    journalctl -p err -n 20 --no-pager 2>/dev/null
    echo -e "\n${YELLOW}Teljes Zentyal log elérése: tail -f /var/log/zentyal/zentyal.log${NC}"
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 4.3 Port Ellenőrzés
check_ports() {
    echo -e "\n--- [4.3] Hálózati Port Ellenőrzés (ss -tuln) ---"
    print_yellow "A futó TCP és UDP szolgáltatások, és az általuk használt portok listája:"
    echo -e "${ORANGE}---------------------------------------------------------------------${NC}"
    if command -v ss &> /dev/null; then
        ss -tuln
    else
        print_yellow "Az 'ss' parancs nem elérhető, netstat használata..."
        netstat -tuln 2>/dev/null || print_red "A port információk lekérése nem sikerült."
    fi
    echo -e "\n${YELLOW}Segítség: Ellenőrizze, hogy a szükséges portok (pl. 8443, 53, 25) LISTEN állapotban vannak-e.${NC}"
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 4.4 Konfigurációs Fájl Helyreállítás
restore_config() {
    echo -e "\n--- [4.4] Konfigurációs Fájl Helyreállítás ---"
    print_yellow "A Zentyal adatbázisában tárolt beállításokat újraírja a rendszerszintű fájlokba."
    read -r -p "Biztosan újra akarod generálni a Zentyal konfigurációs fájlokat? (i/n): " confirm
    if [[ "$confirm" =~ ^[iI]$ ]]; then
        if [ -x "/usr/share/zentyal/make-all-config" ]; then
            print_green "Konfiguráció újraírása..."
            /usr/share/zentyal/make-all-config
            print_green "Újraírás befejezve. Ajánlott szolgáltatás újraindítás."
        else
            print_red "A make-all-config parancs nem található."
        fi
    else
        print_yellow "Helyreállítás megszakítva."
    fi
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 4.5 Csomagok és Függőségek Kényszerített Javítása
fix_dependencies() {
    echo -e "\n--- [4.5] Csomagok és Függőségek Kényszerített Javítása ---"
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
    fi
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 4.6 Hálózati Kapcsolatok Ellenőrzése
check_network_connections() {
    echo -e "\n--- [4.6] Hálózati Kapcsolatok Ellenőrzése ---"
    print_yellow "Aktív hálózati kapcsolatok:"
    echo -e "${ORANGE}---------------------------------------------------------------------${NC}"
    if command -v ss &> /dev/null; then
        ss -tunp
    else
        netstat -tunp 2>/dev/null | head -20
    fi
    echo -e "\n${YELLOW}DNS felbontás teszt (google.com):${NC}"
    if nslookup google.com &> /dev/null; then
        print_green "  ✅ DNS felbontás sikeres."
    else
        print_red "  ❌ DNS felbontás sikertelen. Ellenőrizze a Zentyal DNS modulját!${NC}"
    fi
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}

# 4.7 Lemezterület Ellenőrzése
check_disk_space() {
    echo -e "\n--- [4.7] Lemezterület Ellenőrzése ---"
    print_yellow "Rendelkezésre álló lemezterület (df -h):"
    echo -e "${ORANGE}---------------------------------------------------------------------${NC}"
    df -h | grep -E '^(Filesystem|/dev/)'
    echo -e "\n${YELLOW}Nagy fájlok keresése /var/log könyvtárban (felső 10, >10MB):${NC}"
    find /var/log -type f -size +10M -exec ls -lh {} \; 2>/dev/null | sort -k5 -hr | head -10
    read -n 1 -s -r -p "Nyomj meg egy gombot a folytatáshoz..."
}


# Indítás ellenőrzés (Root-ot igényel)
if [[ $EUID -ne 0 ]]; then
    print_red "FIGYELEM: A script futtatásához root jogosultság szükséges!"
    print_yellow "Kérlek, futtasd a scriptet 'sudo ./zentyal_tool_beta.sh' paranccsal."
    exit 1
fi

# Főprogram indítása
print_green "Zentyal Karbantartó Eszköz indítása (ROOT módban, BETA)..."
sleep 2
show_menu
