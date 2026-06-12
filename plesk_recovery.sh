#!/bin/bash

# ==============================================================================
# Plesk Panel Hosting Kurtarma Aracı
# Lisans süresi dolmuş Plesk panellerden web dosyalarını ve veritabanlarını kurtarır.
# ==============================================================================

set -e

echo "=============================================="
echo " Plesk Hosting Kurtarma Aracina Hos Geldiniz "
echo "=============================================="

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo "Hata: Lutfen bu betigi root kullanicisi olarak calistirin (sudo su)."
  exit 1
fi

# Plesk sunucusu kontrolü
if [ ! -f "/etc/psa/.psa.shadow" ]; then
  echo "Hata: /etc/psa/.psa.shadow bulunamadi. Bu bir Plesk sunucusu mu?"
  exit 1
fi

# Zip komutu kontrolü ve kurulumu
if ! command -v zip &> /dev/null; then
    echo "Sistemde 'zip' komutu bulunamadi. Kurulum deneniyor..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y zip
    elif command -v yum &> /dev/null; then
        yum install -y zip
    else
        echo "Hata: 'zip' paketi kurulamadi. Lutfen manuel olarak kurup tekrar deneyin."
        exit 1
    fi
fi

DB_USER="admin"
DB_PASS=$(cat /etc/psa/.psa.shadow)

# Ana yedek klasörünü oluştur
BACKUP_BASE="/root/plesk_kurtarma_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_BASE"
echo "=> Yedek klasoru olusturuldu: $BACKUP_BASE"

# MySQL sorgu fonksiyonu
query_db() {
    local query="$1"
    MYSQL_PWD="$DB_PASS" mysql -u "$DB_USER" -sN -e "$query" psa
}

echo "=> Plesk veritabanindan domainler ve bagli veritabanlari cekiliyor..."

# Domainleri ve dosya yollarını (document root) çekiyoruz
# h.www_root genelde /var/www/vhosts/domain.com/httpdocs gibi tam yolu barındırır.
DOMAINS=$(query_db "SELECT d.name, h.www_root FROM domains d JOIN hosting h ON d.id = h.dom_id;")

if [ -z "$DOMAINS" ]; then
    echo "Sistemde barindirilan (hosting) herhangi bir domain bulunamadi."
    exit 0
fi

echo "$DOMAINS" | while read -r DOMAIN DOC_ROOT; do
    echo "----------------------------------------------"
    echo "Isleme aliniyor: $DOMAIN"
    
    DOMAIN_DIR="$BACKUP_BASE/$DOMAIN"
    mkdir -p "$DOMAIN_DIR"
    
    # 1. Dosyaları Zip'leme
    if [ -d "$DOC_ROOT" ]; then
        echo "   -> Web dosyalari (Document Root) zippleniyor: $DOC_ROOT"
        # Klasör içine girip zipleyerek gereksiz dizin ağacını engelliyoruz
        (cd "$DOC_ROOT" && zip -rq "$DOMAIN_DIR/${DOMAIN}_dosyalar.zip" .)
        echo "   -> Dosyalar basariyla zipplendi: ${DOMAIN}_dosyalar.zip"
    else
        echo "   -> Uyari: Dosya dizini bulunamadi ($DOC_ROOT)."
    fi
    
    # 2. Veritabanlarını Dump edip Zip'leme
    DBS=$(query_db "SELECT db.name FROM data_bases db JOIN domains d ON db.dom_id = d.id WHERE d.name = '$DOMAIN';")
    
    if [ -n "$DBS" ]; then
        for DB_NAME in $DBS; do
            echo "   -> Veritabani disari aktariliyor (dump): $DB_NAME"
            DUMP_FILE="$DOMAIN_DIR/${DB_NAME}.sql"
            MYSQL_PWD="$DB_PASS" mysqldump -u "$DB_USER" "$DB_NAME" > "$DUMP_FILE"
            
            echo "   -> Veritabani zippleniyor: $DB_NAME"
            (cd "$DOMAIN_DIR" && zip -rmq "${DB_NAME}.sql.zip" "${DB_NAME}.sql")
            echo "   -> Veritabani yedegi hazir: ${DB_NAME}.sql.zip"
        done
    else
        echo "   -> Bu domaine bagli veritabani bulunmuyor."
    fi
    
done

echo "=============================================="
echo "Kurtarma Islemi Tamamlandi!"
echo "Tum dosyalar ve veritabanlari suraya kaydedildi:"
echo " -> $BACKUP_BASE"
echo "Bu klasoru FileZilla (SFTP) veya SCP ile bilgisayariniza indirebilirsiniz."
echo "=============================================="
