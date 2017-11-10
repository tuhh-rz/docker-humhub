# Probleme beim aktivieren von Modulen

- Löschen der Datei `/usr/share/nginx/html/protected/runtime/cache/hu/humhubenabledModuleIds.bin`
- Korrektur der Berechtigungen `chown -R www-data:www-data /usr/share/nginx/html/protected/runtime/cache`