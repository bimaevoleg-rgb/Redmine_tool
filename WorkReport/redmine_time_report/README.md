# Redmine Time Report

Плагин **отчётов по трудозатратам** для Redmine: ежедневный отчёт на почту (вчера / неделя / календарный месяц) и виджет «Моя страница».

Распространяется свободно по лицензии **MIT** (см. `LICENSE`).

## Возможности

- **Ежедневный email-отчёт** (по расписанию, по умолчанию 06:00): разделы **Вчера**, **Неделя (7 дней)**, **Месяц (календарный)**.
- **Месяц** раскрывается по неделям и дням → записи списания по пользователям и проектам.
- **CSV-вложение** (`time_report_YYYY-MM-DD.csv`) для Excel.
- **Фильтры** по исполнителям и проектам, опция «показывать пустые дни».
- **Виджет «Моя страница»** — сводка вчера/неделя/месяц прямо в дашборде пользователя.
- Русская и английская локали.

## Требования

- Redmine **7.0** и выше (Rails 8).
- Настроенная **исходящая почта** (SMTP в `config/configuration.yml`) — иначе отчёт не уйдёт.

## Установка

```bash
cp -r redmine_time_report /opt/redmine/plugins/
cd /opt/redmine && RAILS_ENV=production bin/rails redmine:time_report:send  # проверка без отправки: dry_run=1
touch /opt/redmine/tmp/restart.txt
```

## Настройка

**Администрирование → Плагины → Redmine Time Report:**

| Параметр | Назначение |
|---|---|
| Получатели | email через запятую/построчно |
| Время отправки | время запуска (задаётся и в cron) |
| CSV-вложение | включать/выключать вложение |
| Периоды | Вчера / Неделя / Месяц (флаги) |
| Раздел «Месяц» | раскрывать по неделям и дням |
| Пустые дни | показывать дни без списаний |
| Исполнители (ID) | ограничить отчёт (пусто = все) |
| Проекты (ID) | ограничить отчёт (пусто = все) |

## Расписание (cron)

Пример для `/etc/cron.d/redmine`:

```
0 6 * * * admin cd /opt/redmine && RAILS_ENV=production /opt/redmine/bin/rails redmine:time_report:send >> log/time_report.log 2>&1
```

## Виджет «Моя страница»

Блок **«Трудозатраты»** доступен для «Моей страницы» (Настроить эту страницу). Показывает сводку вчера/неделя/месяц и топ записей за вчера.

## SMTP

Отчёт отправляется через стандартную почту Redmine (`config/configuration.yml` → `email_delivery`). Пример:

```yaml
production:
  email_delivery:
    delivery_method: :smtp
    smtp_settings:
      address: mail.example.ru
      port: 25
      domain: example.ru
      authentication: :login
      user_name: user@example.ru
      password: 'пароль'
      enable_starttls_auto: true
      openssl_verify_mode: none
```

## Структура

```
redmine_time_report/
├── init.rb
├── LICENSE
├── README.md
├── app/
│   ├── mailers/time_report_mailer.rb
│   └── views/{settings,my/blocks}/
├── config/locales/{ru,en}.yml
└── lib/
    ├── time_report.rb          # сборка отчёта, HTML, CSV
    └── tasks/time_report.rake  # redmine:time_report:send
```

## Команды

```bash
# проверка формирования (сохраняет HTML в tmp/, не отправляет)
cd /opt/redmine && RAILS_ENV=production dry_run=1 bin/rails redmine:time_report:send

# отправка получателям
cd /opt/redmine && RAILS_ENV=production bin/rails redmine:time_report:send
```
