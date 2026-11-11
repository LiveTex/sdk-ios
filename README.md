# LivetexCore

A description of this package.

## Настройка

Параметры интеграции задаются в `Info.plist` приложения, в словаре `Livetex`:

```xml
<key>Livetex</key>
<dict>
    <key>LivetexAppID</key>
    <string>touchPoint</string>
    <key>LivetexAuthPath</key>
    <string>https://visitor-api.example.ru/v1/auth</string>
</dict>
```

`LivetexAuthPath` необязателен: если ключа нет, используется `https://visitor-api.livetex.ru/v1/auth`. Значение, переданное в `LivetexAuthService(authPath:)`, имеет приоритет над `Info.plist`.

## Корневой сертификат сервера

Если сервер использует сертификат, которому iOS не доверяет по умолчанию (например, НУЦ Минцифры), корневой сертификат задаётся в том же словаре `Livetex`:

```xml
<key>Livetex</key>
<dict>
    <key>LivetexAppID</key>
    <string>touchPoint</string>
    <key>LivetexRootCertificate</key>
    <string>mincifry_root.cer</string>
</dict>
```

`LivetexRootCertificate` — имя файла сертификата в бандле приложения. Поддерживаются DER и PEM; в PEM-файле может быть цепочка (корень и промежуточный сертификат). Сертификаты добавляются к системным якорям доверия и применяются к авторизации, загрузке файлов и WebSocket; без ключа используется системное доверие.

Кастомный корень работает на iOS 12 и новее, для WebSocket — на iOS 13 и новее. Проверка цепочки и имени хоста не отключается.
