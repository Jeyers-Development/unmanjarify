#!/bin/bash
set -e

# Color codes
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
RED='\e[1;31m'
BLUE='\e[1;34m'
RESET='\e[0m'

echo -e "${BLUE}🚀 Starting Unmanjarify...${RESET}"

packages=(
  ark audiocd-kio elisa ffmpegthumbs filelight gwenview kamera kcalc
  keditbookmarks kfind khelpcenter skanlite spectacle yakuake okular
  dolphin-plugins manjaro-hello manjaro-application-utility
  plymouth-theme-manjaro plymouth-kcm unarchiver
  pamac-tray-icon-plasma pamac-gtk3 pamac-cli
)

echo -e "${YELLOW}🧹 Removing bloatware...${RESET}"
for pkg in "${packages[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null; then
        echo -e "✅ Removing $pkg..."
        sudo pacman -Rns --noconfirm "$pkg"
    else
        echo -e "⚠️ Skipping $pkg (not installed)"
    fi
done

# Function to check if a package is installed
is_installed() {
    pacman -Qi "$1" &>/dev/null
}

# Remove Kate
read -p "🗑️ Would you like to remove Kate? (y/n): " remove_kate
if [[ "$remove_kate" == [Yy] ]]; then
    if is_installed kate; then
        sudo pacman -Rns kate
        echo -e "✅ Kate removed!"
    else
        echo -e "⚠️ Kate not installed."
    fi
else
    echo -e "ℹ️ Kate was not removed."
fi

# Install VS Code & AleScript
read -p "⬆️ Install VS Code & AleScript? (y/n): " add_tools
if [[ "$add_tools" == [Yy] ]]; then
    if ! is_installed code; then
        echo -e "⬆️ Installing VS Code..."
        sudo pacman -S --needed --noconfirm code
    else
        echo -e "ℹ️ VS Code already installed."
    fi

    if ! is_installed alescript; then
        echo -e "⬆️ Installing AleScript from AUR..."
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/alescript.git /tmp/alescript
        cd /tmp/alescript
        makepkg -si --noconfirm
        cd ~
        rm -rf /tmp/alescript
        echo -e "✅ AleScript installed!"
    else
        echo -e "ℹ️ AleScript already installed."
    fi
else
    echo -e "ℹ️ VS Code & AleScript were not installed."
fi

# Remove orphaned packages
orphans=$(pacman -Qtdq || true)
if [ -n "$orphans" ]; then
    echo -e "${YELLOW}🧹 Removing orphaned packages...${RESET}"
    sudo pacman -Rns --noconfirm $orphans
else
    echo -e "${GREEN}✅ No orphaned packages found.${RESET}"
fi

echo -e "${BLUE}💻 Cleaning shell and Konsole...${RESET}"
# Default shell
chsh -s /bin/bash "$USER" || echo -e "${RED}⚠️ Could not change shell. Log out manually.${RESET}"

# Remove Zsh configs
rm -f ~/.zshrc ~/.zprofile ~/.zlogin ~/.zshenv

# Clean Bash config with lime-green prompt
cat > ~/.bashrc <<'EOF'
PS1='\[\e[1;32m\]\u@desktop:\w\[\e[0m\]% '
EOF

# Konsole profiles and color scheme
mkdir -p ~/.local/share/konsole/ColorSchemes
rm -rf ~/.local/share/konsole/*

mkdir -p ~/.local/share/konsole/ColorSchemes
mkdir -p ~/.local/share/konsole

cat > ~/.local/share/konsole/ColorSchemes/WhiteOnBlack.colorscheme <<'EOF'
[Background]
Color=0,0,0
Transparency=0
[BackgroundIntense]
Color=0,0,0
[Foreground]
Color=255,255,255
[ForegroundIntense]
Color=255,255,255
[Color0] Color=0,0,0
[Color1] Color=255,0,0
[Color2] Color=0,255,0
[Color3] Color=255,255,0
[Color4] Color=0,0,255
[Color5] Color=255,0,255
[Color6] Color=0,255,255
[Color7] Color=255,255,255
[Color8] Color=128,128,128
[Color9] Color=255,0,0
[Color10] Color=0,255,0
[Color11] Color=255,255,0
[Color12] Color=0,0,255
[Color13] Color=255,0,255
[Color14] Color=0,255,255
[Color15] Color=255,255,255
EOF

cat > ~/.local/share/konsole/Default.profile <<'EOF'
[General]
Name=Default
Command=/bin/bash
WorkingDirectory=
ScrollBarPosition=Right
ScrollBarVisible=true
SilenceBell=false
ShowTabsBar=true
UseSystemColorScheme=false
MonitorActivity=false
MonitorSilence=false
[Appearance]
ColorScheme=WhiteOnBlack
EOF

mkdir -p ~/.config
cat > ~/.config/konsolerc <<'EOF'
[Desktop Entry]
DefaultProfile=Default.profile
EOF

echo -e "${BLUE}💾 Installing GRUB...${RESET}"
sudo pacman -S --noconfirm grub os-prober efibootmgr

if [ -d /sys/firmware/efi ]; then
    echo -e "${GREEN}✅ UEFI system detected.${RESET}"
    EFI_DIR="/boot/efi"
    DISK=$(lsblk -nd -o NAME,TYPE | grep disk | head -n1 | awk '{print "/dev/" $1}')
    sudo grub-install --target=x86_64-efi --efi-directory=$EFI_DIR --bootloader-id=GRUB
else
    echo -e "${GREEN}✅ BIOS (Legacy) system detected.${RESET}"
    DISK=$(lsblk -nd -o NAME,TYPE | grep disk | head -n1 | awk '{print "/dev/" $1}')
    sudo grub-install --target=i386-pc $DISK
fi

sudo grub-mkconfig -o /boot/grub/grub.cfg
echo -e "${GREEN}✅ GRUB installation complete! Reboot recommended.${RESET}"

echo "🦊 Configuring Firefox default homepage..."
FIREFOX_PREF_DIR="$HOME/.mozilla/firefox"
DEFAULT_PROFILE=$(find "$FIREFOX_PREF_DIR" -maxdepth 1 -type d -name "*.default*" | head -n1)

if [ -n "$DEFAULT_PROFILE" ]; then
    PREF_FILE="$DEFAULT_PROFILE/user.js"
    echo 'user_pref("browser.startup.homepage", "about:blank");' >> "$PREF_FILE"
    echo 'user_pref("browser.startup.page", 0);' >> "$PREF_FILE"  # 0 = blank page
    echo "✅ Firefox homepage set to blank."
else
    echo "❔ Firefox profile not found. Will set homepage on first launch."
fi


echo -e "${BLUE}🎉 Unmanjarify finished! Enjoy your clean Arch-style system.${RESET}"
