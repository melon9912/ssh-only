#!/usr/bin/env bash
# One-Click Dropbear 2019 Installer by Rerechan02

set -e

# Warna
BIWhite='\033[1;97m'
BIGreen='\033[1;92m'
BIRed='\033[1;91m'
BIYellow='\033[1;93m'
NC='\033[0m'

DROPBEAR_VERSION="2019.78"
DROPBEAR_URL="https://matt.ucc.asn.au/dropbear/releases"
DROPBEAR_BIN="/usr/sbin/dropbear"
DROPBEAR_LIB="/usr/lib/dropbear"
DROPBEAR_CONFIG="/etc/dropbear"
DROPBEAR_MAN="/usr/share/man/man8/dropbear.8.gz"

clear
echo -e "${BIWhite}──────────────────────────────────────────${NC}"
echo -e "${BIWhite}🚀 One-Click Dropbear Installer - v$DROPBEAR_VERSION${NC}"
echo -e "${BIWhite}──────────────────────────────────────────${NC}"

# Stop Dropbear jika ada
systemctl stop dropbear 2>/dev/null || service dropbear stop 2>/dev/null

# Backup dan bersih
[ -f "$DROPBEAR_BIN" ] && cp $DROPBEAR_BIN "${DROPBEAR_BIN}.bak"
rm -f $DROPBEAR_BIN 2>/dev/null
rm -rf $DROPBEAR_LIB/* $DROPBEAR_CONFIG/* $DROPBEAR_MAN 2>/dev/null

# Install dependensi
echo -e "${BIGreen}🔧 Menginstall dependensi...${NC}"
if [ -f "/etc/debian_version" ]; then
  apt update -y
  apt install -y build-essential zlib1g-dev wget
else
  yum groupinstall "Development Tools" -y
  yum install -y zlib-devel wget
fi

# Unduh dan kompilasi
echo -e "${BIGreen}⬇️ Mengunduh Dropbear v$DROPBEAR_VERSION...${NC}"
wget --no-check-certificate -O dropbear.tar.bz2 "$DROPBEAR_URL/dropbear-$DROPBEAR_VERSION.tar.bz2"

echo -e "${BIGreen}📦 Mengekstrak dan mengkompilasi...${NC}"
tar -xjf dropbear.tar.bz2
cd "dropbear-$DROPBEAR_VERSION"
./configure --prefix=/usr
make && make install

# Installasi binary
echo -e "${BIGreen}✅ Instalasi selesai, menyalin binary...${NC}"
mv dropbear $DROPBEAR_BIN
mkdir -p $DROPBEAR_LIB $DROPBEAR_CONFIG
[ -f "/usr/share/man/man8/dropbear.8.gz" ] && mv /usr/share/man/man8/dropbear.8.gz $DROPBEAR_MAN

# Buat key baru
echo -e "${BIGreen}🔑 Membuat ulang host key...${NC}"
rm -f $DROPBEAR_CONFIG/dropbear_*_host_key
dropbearkey -t rsa -f $DROPBEAR_CONFIG/dropbear_rsa_host_key
dropbearkey -t dss -f $DROPBEAR_CONFIG/dropbear_dss_host_key
dropbearkey -t ecdsa -f $DROPBEAR_CONFIG/dropbear_ecdsa_host_key

chmod 600 $DROPBEAR_CONFIG/dropbear_*_host_key

# Jalankan ulang Dropbear
echo -e "${BIGreen}🚀 Menjalankan Dropbear...${NC}"
systemctl start dropbear 2>/dev/null || service dropbear start 2>/dev/null

# Cek versi
echo -e "${BIGreen}📋 Verifikasi versi:${NC}"
$DROPBEAR_BIN -V || echo -e "${BIRed}⚠️ Gagal verifikasi versi!${NC}"

# Bersih-bersih
cd ..
rm -rf dropbear.tar.bz2 "dropbear-$DROPBEAR_VERSION"

echo -e "${BIWhite}──────────────────────────────────────────${NC}"
echo -e "${BIGreen}🎉 Dropbear v$DROPBEAR_VERSION berhasil diinstall!${NC}"
echo -e "${BIWhite}──────────────────────────────────────────${NC}"
