# Plesk Panel Hosting Kurtarma Aracı

Bu yazılım, lisans süresi dolduğu için arayüzüne erişemediğiniz Linux Plesk Panel sunucularından websitelerinizi (dosyalar ve veritabanları) kurtarmanızı sağlar.

## Özellikleri
- Plesk'in kendi iç veritabanını (`psa`) okuyarak her bir domainin tam ana dizinini (`httpdocs`, `public_html` vs.) tespit eder.
- Tespit ettiği dizinin içindeki dosyaları `.zip` formatında sıkıştırır.
- İlgili domaine bağlı olan tüm veritabanlarını bulur, `.sql` olarak dışarı aktarır (dump) ve ardından onları da `.zip` ile sıkıştırır.
- İşlem sonucunda `/root/plesk_kurtarma_YILAYGUN_SAAT` adında bir klasör oluşturur ve içindeki tüm domainleri ayrı klasörler halinde derler.

## Nasıl Kullanılır?

1. `plesk_recovery.sh` dosyasını Linux (Plesk) sunucunuza yükleyin.
2. Sunucuya SSH ile bağlanın ve root kullanıcısına geçiş yapın:
   ```bash
   sudo su
   ```
3. Dosyaya çalışma izni verin:
   ```bash
   chmod +x plesk_recovery.sh
   ```
4. Aracı çalıştırın:
   ```bash
   ./plesk_recovery.sh
   ```

## Çıktı Yapısı
Çalıştırma işlemi bittiğinde oluşturulan yedek klasörünün yapısı şu şekildedir:

```text
/root/plesk_kurtarma_20231015_120000/
├── domain1.com/
│   ├── domain1.com_dosyalar.zip
│   └── veritabani_adi1.sql.zip
├── domain2.net/
│   ├── domain2.net_dosyalar.zip
│   ├── veritabani_adi2.sql.zip
│   └── veritabani_adi3.sql.zip
...
```

Bu klasörü işlemin ardından FileZilla veya WinSCP kullanarak SFTP üzerinden bilgisayarınıza kolayca indirebilirsiniz.
