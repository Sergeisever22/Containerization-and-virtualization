# Отчёт по лабораторной работе  
## «Обслуживание сервера»

**Выполнил:** Severcenco Serghei  

---

## 1. Цель работы

Целью лабораторной работы является получение практических навыков работы с Docker и Docker Compose, создание и настройка контейнеров для Web-сервера, PHP, базы данных и планировщика Cron, а также настройка автоматического резервного копирования сайта и базы данных.

---

## 2. Используемые технологии

В лабораторной работе использовались:

- Docker Desktop;
- Docker Compose;
- Apache HTTPD;
- PHP-FPM;
- MariaDB;
- WordPress;
- Cron;
- Shell-скрипты;
- Windows PowerShell.

---

## 3. Структура проекта

Для выполнения лабораторной работы была подготовлена следующая структура каталогов:

```text
additional/
├── backups/
│   ├── mysql/
│   └── site/
├── database/
├── files/
│   ├── httpd/
│   │   └── httpd.conf
│   └── cron/
│       ├── crontab
│       └── scripts/
│           ├── 01_alive.sh
│           ├── 02_backupsite.sh
│           ├── 03_mysqldump.sh
│           ├── 04_clean.sh
│           └── environment.sh
├── site/
│   └── wordpress/
├── Dockerfile.httpd
├── Dockerfile.php-fpm
├── Dockerfile.mariadb
├── Dockerfile.cron
└── docker-compose.yml
```

### Скриншот 1 — структура проекта

> **Добавить сюда скриншот папки `additional` со всеми созданными файлами и каталогами.**

```md
![Структура проекта](images/01-project-structure.png)
```

---

## 4. Создание контейнера Apache HTTPD

Был создан файл `Dockerfile.httpd`:

```dockerfile
FROM httpd:2.4

RUN apt update && apt upgrade -y

COPY ./files/httpd/httpd.conf /usr/local/apache2/conf/httpd.conf
```

В конфигурационном файле Apache были включены необходимые модули:

```apache
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so
```

Также были добавлены настройки:

```apache
ServerName wordpress.localhost:80
ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://php-fpm:9000/var/www/html/$1
DirectoryIndex /index.php index.php
```

Корневой каталог сайта был изменён на:

```apache
DocumentRoot "/var/www/html"

<Directory "/var/www/html">
```

### Скриншот 2 — настройка Apache

> **Добавить сюда скриншот файла `httpd.conf` с настройками PHP-FPM и `DocumentRoot`.**

```md
![Настройка Apache](images/02-httpd-config.png)
```

---

## 5. Создание контейнера PHP-FPM

Исходный вариант лабораторной работы использовал образ:

```dockerfile
FROM php:7.4-fpm
```

При сборке возникла проблема с устаревшими Debian Bullseye репозиториями — команда `apt-get` возвращала ошибку `404 Not Found`.

Поэтому была выполнена дополнительная корректировка репозиториев Debian.

Использованный `Dockerfile.php-fpm`:

```dockerfile
FROM php:7.4-fpm

RUN sed -i '/bullseye-security/d' /etc/apt/sources.list \
    && sed -i '/bullseye-updates/d' /etc/apt/sources.list \
    && sed -i 's/deb.debian.org\/debian/archive.debian.org\/debian/g' /etc/apt/sources.list \
    && echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure pdo_mysql \
    && docker-php-ext-install -j$(nproc) gd mysqli
```

### Скриншот 3 — ошибка при первоначальной сборке PHP-FPM

> **Добавить сюда скриншот PowerShell с ошибкой `404 Not Found`.**

```md
![Ошибка PHP-FPM](images/03-php-fpm-error.png)
```

### Скриншот 4 — успешная сборка PHP-FPM

> **Добавить сюда скриншот успешной сборки контейнера PHP-FPM.**

```md
![Успешная сборка PHP-FPM](images/04-php-fpm-build.png)
```

---

## 6. Создание контейнера MariaDB

Был создан файл `Dockerfile.mariadb`:

```dockerfile
FROM mariadb:10.8

RUN apt-get update && apt-get upgrade -y
```

Для базы данных были использованы следующие параметры:

```yaml
MARIADB_DATABASE: sample
MARIADB_USER: sampleuser
MARIADB_PASSWORD: samplepassword
MARIADB_ROOT_PASSWORD: rootpassword
```

Данные MariaDB сохраняются на компьютере благодаря подключению каталога:

```yaml
volumes:
  - "./database/:/var/lib/mysql"
```

---

## 7. Создание контейнера Cron

Файл `Dockerfile.cron`:

```dockerfile
FROM debian:latest

RUN apt update && apt -y upgrade && apt install -y cron mariadb-client

COPY ./files/cron/crontab /etc/cron.d/crontab
COPY ./files/cron/scripts/ /scripts/

RUN crontab /etc/cron.d/crontab

ENTRYPOINT [ "/scripts/environment.sh" ]
CMD [ "cron", "-f" ]
```

Для обслуживания сервера были созданы четыре Shell-скрипта:

- `01_alive.sh` — проверка работы Cron;
- `02_backupsite.sh` — резервное копирование файлов сайта;
- `03_mysqldump.sh` — резервное копирование базы данных;
- `04_clean.sh` — удаление резервных копий старше 30 дней.

### Скриншот 5 — Cron-скрипты

> **Добавить сюда скриншот папки `files/cron/scripts` или открытых Shell-скриптов.**

```md
![Cron scripts](images/05-cron-scripts.png)
```

---

## 8. Настройка Docker Compose

Для одновременного запуска всех сервисов использовался файл `docker-compose.yml`.

Были созданы четыре сервиса:

- `httpd`;
- `php-fpm`;
- `mariadb`;
- `cron`.

Все контейнеры были подключены к общей внутренней сети:

```yaml
networks:
  internal: {}
```

Для Apache был открыт порт:

```yaml
ports:
  - "80:80"
```

Это позволило обращаться к WordPress через браузер.

### Скриншот 6 — файл Docker Compose

> **Добавить сюда скриншот файла `docker-compose.yml`.**

```md
![Docker Compose](images/06-docker-compose.png)
```

---

## 9. Сборка Docker-образов

Для сборки образов использовалась команда:

```powershell
docker-compose build
```

Время одной из выполненных сборок составило приблизительно:

```text
8.93 секунды
```

Для повторной сборки PHP-FPM без использования кэша использовалась команда:

```powershell
docker-compose build --no-cache php-fpm
```

### Скриншот 7 — сборка контейнеров

> **Добавить сюда скриншот PowerShell во время или после успешной сборки Docker-образов.**

```md
![Сборка Docker-образов](images/07-docker-build.png)
```

---

## 10. Запуск контейнеров

Для запуска проекта использовалась команда:

```powershell
docker-compose up
```

или запуск в фоновом режиме:

```powershell
docker-compose up -d
```

После запуска состояние контейнеров проверялось командой:

```powershell
docker ps
```

В результате были успешно запущены четыре контейнера:

```text
additional-mariadb-1
additional-php-fpm-1
additional-httpd-1
additional-cron-1
```

Контейнер Apache использовал порт:

```text
0.0.0.0:80->80/tcp
```

### Скриншот 8 — команда `docker ps`

> **Добавить сюда скриншот, на котором видно четыре работающих контейнера.**

```md
![Работающие контейнеры](images/08-docker-ps.png)
```

---

## 11. Установка WordPress

После запуска контейнеров сайт был открыт по адресу:

```text
http://wordpress.localhost
```

Для подключения WordPress к MariaDB были использованы следующие параметры:

| Параметр | Значение |
|---|---|
| Database Name | `sample` |
| Username | `sampleuser` |
| Password | `samplepassword` |
| Database Host | `mariadb` |
| Table Prefix | `wp_` |

После отправки данных WordPress успешно подключился к базе данных.

### Скриншот 9 — подключение WordPress к базе данных

> **Добавить сюда скриншот формы WordPress с параметрами подключения к MariaDB.**

```md
![Подключение WordPress к MariaDB](images/09-wordpress-db.png)
```

После этого была выполнена стандартная установка WordPress.

### Скриншот 10 — форма установки WordPress

> **Добавить сюда скриншот страницы `Welcome / Information needed`.**

```md
![Установка WordPress](images/10-wordpress-install.png)
```

После завершения установки главная страница WordPress успешно открылась.

### Скриншот 11 — работающий WordPress

> **Добавить сюда скриншот главной страницы сайта `Docker WordPress`.**

```md
![Работающий WordPress](images/11-wordpress-site.png)
```

---

## 12. Проверка работы Cron

Во время работы контейнеров в логах Cron были получены следующие сообщения:

```text
alive Severcenco Serghei

[backup] create mysql dump of sample database
[backup] sql dump created

[backup] create site backup
[backup] site backup done

[backup] remove old backups
[backup] done
```

Это подтверждает выполнение всех созданных Shell-скриптов.

### Скриншот 12 — логи Cron

> **Добавить сюда скриншот PowerShell, где видны строки `alive`, `sql dump created`, `site backup done` и `remove old backups`.**

```md
![Логи Cron](images/12-cron-logs.png)
```

---

## 13. Проверка резервных копий

Резервная копия базы данных сохраняется в:

```text
backups/mysql/
```

Резервная копия файлов WordPress сохраняется в:

```text
backups/site/
```

Скрипт очистки удаляет резервные копии, возраст которых превышает 30 дней.

### Скриншот 13 — резервная копия базы данных

> **Добавить сюда скриншот папки `backups/mysql`, где виден созданный `.sql.gz` файл.**

```md
![Резервная копия MariaDB](images/13-mysql-backup.png)
```

### Скриншот 14 — резервная копия сайта

> **Добавить сюда скриншот папки `backups/site`, где виден созданный `.tar.gz` архив.**

```md
![Резервная копия сайта](images/14-site-backup.png)
```

---

## 14. Итоговое расписание Cron

После проверки работы скриптов можно использовать следующее расписание:

```cron
* * * * * /scripts/01_alive.sh > /dev/null
0 1 * * * /scripts/03_mysqldump.sh > /dev/null
30 1 * * 1 /scripts/02_backupsite.sh > /dev/null
0 2 * * * /scripts/04_clean.sh > /dev/null
```

Расписание означает:

- каждую минуту выполняется проверка `01_alive.sh`;
- каждый день в `01:00` создаётся резервная копия базы данных;
- каждый понедельник в `01:30` создаётся резервная копия файлов сайта;
- каждый день в `02:00` удаляются старые резервные копии.

---

# 15. Ответы на контрольные вопросы

## 15.1. Зачем необходимо создавать пользователя системы для каждого сайта?

Создание отдельного системного пользователя для каждого сайта необходимо для обеспечения безопасности и разграничения прав доступа.

Если несколько сайтов работают от имени одного пользователя, то при взломе одного сайта злоумышленник потенциально может получить доступ к файлам других сайтов.

Использование отдельных пользователей позволяет:

- разделить права доступа;
- ограничить доступ одного сайта к файлам другого;
- назначить отдельного владельца файлов;
- применять принцип минимальных привилегий;
- повысить общую безопасность Web-сервера.

Таким образом, отдельный пользователь обеспечивает дополнительную изоляцию сайтов.

---

## 15.2. В каких случаях Web-сервер должен иметь полный доступ к папкам сайта?

Полный доступ Web-серверу следует предоставлять только к тем каталогам, в которые Web-приложение должно записывать или изменять данные.

Например:

- каталоги загрузки пользовательских файлов;
- каталоги кэша;
- временные каталоги;
- каталоги журналов;
- каталоги для автоматического обновления.

Для WordPress таким каталогом может быть:

```text
wp-content/uploads
```

Предоставлять полный доступ ко всему сайту без необходимости не рекомендуется, так как это снижает безопасность системы.

---

## 15.3. Что означает команда `chmod -R 0755 /home/www/anydir`?

Команда:

```bash
chmod -R 0755 /home/www/anydir
```

рекурсивно изменяет права доступа для каталога `/home/www/anydir` и всего его содержимого.

Параметр:

```text
-R
```

означает рекурсивное применение команды ко всем вложенным файлам и каталогам.

Права `0755` означают:

| Пользователь | Права |
|---|---|
| Владелец | `rwx` — чтение, запись, выполнение |
| Группа | `r-x` — чтение и выполнение |
| Остальные | `r-x` — чтение и выполнение |

В символьном виде:

```text
rwxr-xr-x
```

---

## 15.4. Что означает `> /proc/1/fd/1` в Shell-скриптах?

Конструкция:

```bash
> /proc/1/fd/1
```

перенаправляет стандартный вывод команды в стандартный вывод процесса с `PID 1`.

В Docker-контейнере процесс с `PID 1` обычно является главным процессом контейнера.

Файл:

```text
/proc/1/fd/1
```

соответствует файловому дескриптору `stdout`.

Например:

```bash
echo "alive Severcenco Serghei" > /proc/1/fd/1
```

отправляет сообщение в стандартный вывод главного процесса контейнера.

Благодаря этому сообщение становится доступно в Docker-логах:

```powershell
docker logs <имя_контейнера>
```

Аналогично:

```bash
2> /proc/1/fd/2
```

перенаправляет поток ошибок `stderr`.

---

# 16. Вывод

В ходе лабораторной работы была создана контейнеризированная среда для запуска WordPress.

Были созданы и настроены четыре Docker-контейнера:

- Apache HTTPD;
- PHP-FPM;
- MariaDB;
- Cron.

Была настроена внутренняя сеть Docker, обеспечено взаимодействие Apache с PHP-FPM и WordPress с MariaDB.

WordPress был успешно установлен и запущен по адресу:

```text
http://wordpress.localhost
```

Также были реализованы Shell-скрипты для:

- проверки работы Cron;
- резервного копирования базы данных;
- резервного копирования файлов сайта;
- автоматического удаления старых резервных копий.

Работа всех контейнеров и Cron-заданий была успешно проверена.

---

## Рекомендуемая структура папки со скриншотами

Для удобства можно создать рядом с `README.md` папку:

```text
images/
```

и хранить скриншоты с такими именами:

```text
images/
├── 01-project-structure.png
├── 02-httpd-config.png
├── 03-php-fpm-error.png
├── 04-php-fpm-build.png
├── 05-cron-scripts.png
├── 06-docker-compose.png
├── 07-docker-build.png
├── 08-docker-ps.png
├── 09-wordpress-db.png
├── 10-wordpress-install.png
├── 11-wordpress-site.png
├── 12-cron-logs.png
├── 13-mysql-backup.png
└── 14-site-backup.png
```

После добавления изображений GitHub или другой Markdown-просмотрщик автоматически покажет их в соответствующих местах отчёта.
