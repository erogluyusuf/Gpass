#!/bin/bash

function matrix_effect() {
    text="$1"          # Metin
    delay="$2"         # Karakterlerin gecikme süresi

    # Her bir karakteri yan yana yazdır
    for ((i=0; i<${#text}; i++)); do
        # Karakteri al
        char="${text:i:1}"
        
        # Karakteri ekrana yazdır
        echo -n "$char"
        
        # Gecikme
        sleep $delay
    done
    echo ""  # Sonunda yeni bir satır
}

function blink_effect() {
    text="$1"          # Metin
    delay="$2"         # Gecikme süresi
    count=0            # Sayaç başlat

    # 2 kere yanıp sönmesi için döngü
    while [ $count -lt 2 ]; do
        # Metni ekrana yazdır
        echo -n "$text"

        # Gecikme
        sleep $delay

        # Ekranı temizle (Metni sil)
        echo -ne "\r\033[K"

        # Gecikme
        sleep $delay

        # Sayaç artır
        ((count++))
    done
}






# Dil ayarlarını kontrol et
LANGUAGE=$(echo $LANG | cut -d_ -f1)

# Yardım fonksiyonu
function show_help() {
    if [[ "$LANGUAGE" == "tr" ]]; then
        echo "Gpass - Güçlü Şifre Üretici"
        echo ""
        echo "Kullanım:"
        echo "  ./Gpass [seçenekler]"
        echo ""
        echo "Seçenekler:"
        echo "  -l, --length <sayı>    Şifre uzunluğunu belirler"
        echo "  -u, --upper            Büyük harfler ekler (A-Z)"
        echo "  -s, --lower            Küçük harfler ekler (a-z)"
        echo "  -n, --number           Rakamlar ekler (0-9)"
        echo "  -c, --special          Özel karakterler ekler (!@#\$%^&*)"
        echo "  -h, --help             Yardım ekranını gösterir"
        echo ""
        echo "Örnek:"
        echo "  Gpass -l 12 -u -n"
        echo "  (12 karakterlik, büyük harf ve rakamlardan oluşan şifre üretir.)"
    else
        echo "Gpass - Strong Password Generator"
        echo ""
        echo "Usage:"
        echo "  ./Gpass [options]"
        echo ""
        echo "Options:"
        echo "  -l, --length <number>   Set the password length"
        echo "  -u, --upper             Add uppercase letters (A-Z)"
        echo "  -s, --lower             Add lowercase letters (a-z)"
        echo "  -n, --number            Add numbers (0-9)"
        echo "  -c, --special           Add special characters (!@#\$%^&*)"
        echo "  -h, --help              Show this help message"
        echo ""
        echo "Example:"
        echo "  Gpass -l 12 -u -n"
        echo "  (Generates a password with 12 characters, including uppercase letters and numbers.)"
    fi
}

# Varsayılan değerler
LENGTH=0
USE_UPPER=false
USE_LOWER=false
USE_NUMBER=false
USE_SPECIAL=false

# xclip veya xsel'in yüklü olup olmadığını kontrol et ve yükle
function check_and_install_tools() {
    # Dağıtımı tespit et
    DISTRO=$(grep ^ID= /etc/os-release | cut -d'=' -f2 | tr -d '"')

    # Dağıtıma göre uygun komutu seç
    if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
        if ! command -v xclip &> /dev/null; then
            sudo apt update && sudo apt install -y xclip
            if [ $? -eq 0 ]; then
                if [[ "$LANGUAGE" == "tr" ]]; then
                    echo "xclip başarıyla yüklendi!"
                else
                    echo "xclip successfully installed!"
                fi
            else
                if [[ "$LANGUAGE" == "tr" ]]; then
                    echo "xclip yüklenemedi. Lütfen manuel olarak yükleyin."
                else
                    echo "Failed to install xclip. Please install manually."
                fi
                exit 1
            fi
        fi
    elif [[ "$DISTRO" == "fedora" ]]; then
        if ! command -v xsel &> /dev/null; then
            sudo dnf install -y xsel
            if [ $? -eq 0 ]; then
                if [[ "$LANGUAGE" == "tr" ]]; then
                    echo "xsel başarıyla yüklendi!"
                else
                    echo "xsel successfully installed!"
                fi
            else
                if [[ "$LANGUAGE" == "tr" ]]; then
                    echo "xsel yüklenemedi. Lütfen manuel olarak yükleyin."
                else
                    echo "Failed to install xsel. Please install manually."
                fi
                exit 1
            fi
        fi
    elif [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" ]]; then
        if ! command -v xclip &> /dev/null; then
            sudo pacman -Syu --noconfirm xclip
            if [ $? -eq 0 ]; then
                if [[ "$LANGUAGE" == "tr" ]]; then
                    echo "xclip başarıyla yüklendi!"
                else
                    echo "xclip successfully installed!"
                fi
            else
                if [[ "$LANGUAGE" == "tr" ]]; then
                    echo "xclip yüklenemedi. Lütfen manuel olarak yükleyin."
                else
                    echo "Failed to install xclip. Please install manually."
                fi
                exit 1
            fi
        fi
    else
        if [[ "$LANGUAGE" == "tr" ]]; then
            echo "Desteklenmeyen dağıtım: $DISTRO"
        else
            echo "Unsupported distribution: $DISTRO"
        fi
        exit 1
    fi
}

# Parametreleri oku
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -l|--length) LENGTH="$2"; shift ;;
        -u|--upper) USE_UPPER=true ;;
        -s|--lower) USE_LOWER=true ;;
        -n|--number) USE_NUMBER=true ;;
        -c|--special) USE_SPECIAL=true ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Bilinmeyen parametre: $1"; exit 1 ;;
    esac
    shift
done

# Eğer hiç parametre girilmemişse, en güvenli şifreyi üret
if [[ "$LENGTH" -eq 0 ]]; then
    LENGTH=12  # Varsayılan uzunluk 12
    USE_UPPER=true
    USE_LOWER=true
    USE_NUMBER=true
    USE_SPECIAL=true
fi

# Uzunluk kontrolü
if [[ "$LENGTH" -le 0 ]]; then
    if [[ "$LANGUAGE" == "tr" ]]; then
        echo "Hata: Şifre uzunluğunu belirtmek için -l parametresini kullanın."
    else
        echo "Error: Use the -l parameter to specify the password length."
    fi
    exit 1
fi

# Eğer hiç karakter seti seçilmediyse, hepsini aktif et
if ! $USE_UPPER && ! $USE_LOWER && ! $USE_NUMBER && ! $USE_SPECIAL; then
    USE_UPPER=true
    USE_LOWER=true
    USE_NUMBER=true
    USE_SPECIAL=true
fi

# xclip veya xsel'i kontrol et ve yükle
check_and_install_tools

# Karakter havuzu oluştur
CHAR_SET=""

if $USE_UPPER; then
    CHAR_SET+="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
fi

if $USE_LOWER; then
    CHAR_SET+="abcdefghijklmnopqrstuvwxyz"
fi

if $USE_NUMBER; then
    CHAR_SET+="0123456789"
fi

if $USE_SPECIAL; then
    CHAR_SET+="!@#$%^&*()-_=+[]{}"
fi

# Şifreyi oluştur
PASSWORD=""
for ((i=0; i<LENGTH; i++)); do
    PASSWORD+="${CHAR_SET:RANDOM%${#CHAR_SET}:1}"
done

# Matrix efektiyle şifreyi ekranda göster
matrix_effect "$PASSWORD" 0.1  # 0.1 saniye gecikme ile
# Sonucu göster
# echo "$PASSWORD"

# Panoya kopyala (xsel veya xclip gerektiriyor)
if command -v xclip &> /dev/null; then
    echo "$PASSWORD" | xclip -selection clipboard
elif command -v xsel &> /dev/null; then
    echo "$PASSWORD" | xsel --clipboard --input
else
    if [[ "$LANGUAGE" == "tr" ]]; then
        echo "Panoya kopyalama aracı bulunamadı!"
    else
        echo "Clipboard copy tool not found!"
    fi
    exit 1
fi

# Mesajları dil seçimine göre düzenle
if [[ "$LANGUAGE" == "tr" ]]; then
    
	blink_effect "Şifre panoya kopyalandı!" 0.5

else
    echo "Password copied to clipboard!"
	blink_effect "Password copied to clipboard!" 0.5
fi
