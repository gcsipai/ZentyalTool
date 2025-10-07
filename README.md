# 🛠️ Zentyal Karbantartó és Hibaelhárító Eszköz (BÉTA v2.4)

Egy robusztus Bash script a Zentyal Server 8.0 (Ubuntu 22.04 LTS alapú) egyszerűsített karbantartásához, frissítéséhez és hibaelhárításához. Automatikus kompatibilitási javításokat és kulcsfontosságú rendszerműveleteket végez el menüvezérelt felületen.

**FIGYELEM:** Ez egy BÉTA kiadás. Kérjük, óvatosan használja éles rendszereken.

## 🚀 Főbb Jellemzők

* **Rendszerfelkészítés:** Telepíti az alapvető karbantartó szoftvereket (`mc`, `htop`, `bpytop`, `curl`, `zip`, `unzip`).
* **Kompatibilitási Ellenőrzés:** Diagnosztizálja a Zentyal számára kritikus hálózati elnevezési problémákat (pl. `enp0s3` helyett `eth0`).
* **Frissítés:** Egyetlen ponton végzi el az `apt update` és `apt dist-upgrade` parancsokat.
* **Diagnosztika:** Részletes almenü a Zentyal szolgáltatások, logok, portok és csomagfüggőségek ellenőrzésére/javítására.

## 📋 Előfeltételek

* **Operációs rendszer:** Ubuntu Server 22.04 LTS
* **Célkörnyezet:** Zentyal 8.0 telepítése előtt vagy után

## 💾 Telepítés és Futtatás

Az eszköz futtatásához root (rendszergazdai) jogosultság szükséges.

1.  **A script letöltése:**
    ```bash
    wget [A script GitHub/GitLab linkje ide] -O zentyal-tool-beta.sh
    ```

2.  **Futtatási jog adása:**
    ```bash
    chmod +x zentyal-tool-beta.sh
    ```

3.  **Futtatás root jogosultsággal:**
    ```bash
    sudo ./zentyal-tool-beta.sh
    ```

## 🌐 Főmenü Opciók Részletesen

| Opció | Leírás | Figyelem |
| :---: | :--- | :--- |
| **1.** | **⚡ Rendszer Felkészítés** | Telepíti az alapvető szoftvereket (`mc`, `htop`, `bpytop`, stb.) és ellenőrzi a Zentyal kompatibilitást. |
| **2.** | **Rendszer és Zentyal Frissítés** | Lefuttatja az `apt update`-et és az `apt dist-upgrade`-et a rendszer és az összes telepített Zentyal modul frissítéséhez. |
| **3.** | **Zentyal 8.0 Telepítése** | Letölti és elindítja a hivatalos Zentyal 8.0 telepítő scriptet. |
| **4.** | **🛠️ Diagnosztika és Hibaelhárítás** | Belép a részletes hibaelhárító almenübe (logok, portok, szolgáltatásállapotok). |
| **5.** | **Hálózati Információk** | Megjeleníti a helyi IP címeket, átjárót és az interfészek állapotát. |
| **6.** | **Rendszer Újraindítása** | Megerősítés után azonnal újraindítja a rendszert (`reboot`). |
| **7.** | **Hálózati Elnevezés Javítása** | Módosítja a GRUB beállításokat (`net.ifnames=0 biosdevname=0`) a Zentyal által elvárt `eth0` séma érvényesítéséhez, majd **újraindítja** a rendszert. |
| **0.** | **Kilépés** | Kilép a scriptből. |

## 🛠️ Diagnosztika és Hibaelhárítás (4. menüpont almenüje)

A 4. opció választásával elérhető almenü a következő funkciókat tartalmazza:

| Opció | Funkció |
| :---: | :--- |
| **1.** | **Zentyal Modulok és Fő Szolgáltatás Állapotának Ellenőrzése** (Lekérdezi az `ebox` és az egyes modulok `systemctl` állapotát) |
| **2.** | **Rendszer Logok (Journal) Megtekintése** (Megjeleníti az `ebox` logokat és a legújabb általános rendszerhibákat) |
| **3.** | **Port Ellenőrzés (ss)** (Lekérdezi az aktívan hallgató TCP/UDP portokat) |
| **4.** | **Konfigurációs Fájl Helyreállítás** (Lefuttatja a `/usr/share/zentyal/make-all-config` parancsot) |
| **5.** | **Csomagok és Függőségek Kényszerített Javítása** (Lefuttatja az `apt --fix-broken install` parancsot) |
| **6.** | **Hálózati Kapcsolatok Ellenőrzése** (Aktív kapcsolatok listázása és DNS felbontás teszt) |
| **7.** | **Lemezterület Ellenőrzése** (Lekérdezi a `df -h` kimenetet és a nagy fájlokat a `/var/log` alatt) |

## ⚠️ Fontos Megjegyzés

A script a rendszer kritikus beállításait módosíthatja (pl. GRUB, csomagok). **Minden parancs root jogosultsággal fut.** Mindig olvassa el a kimenetet, mielőtt megerősíti az újraindítást vagy más kritikus műveletet!
