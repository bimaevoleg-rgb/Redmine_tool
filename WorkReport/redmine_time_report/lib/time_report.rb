# frozen_string_literal: true

require 'csv'

module TimeReport
  module_function

  def send_daily(dry_run: false)
    settings = Setting.plugin_redmine_time_report
    report = build(settings)
    recipients = settings['recipients'].to_s.split(/[\s,;]+/).reject(&:blank?)
    report[:recipients] = recipients.join(', ')

    if dry_run
      html = build_html(report)
      path = File.join(Rails.root, 'tmp', "time_report_#{Date.today.iso8601}.html")
      File.write(path, html)
      report[:file] = path
      report
    else
      raise 'Получатели не заданы' if recipients.empty?
      TimeReportMailer.daily_report(recipients, report).deliver
      report
    end
  end

  def build(settings)
    I18n.with_locale(:ru) do
      today = Date.today
      yesterday = today - 1
      week_from = today - 7
      month_start = today.beginning_of_month
      month_end = [yesterday, today.end_of_month].min

      users = parse_ids(settings['user_filter'])
      projects = parse_ids(settings['project_filter'])

      base = TimeEntry.joins(:user, :project)
      base = base.where(user_id: users) if users.present?
      base = base.where(project_id: projects) if projects.present?

      yesterday_rows = aggregate(base.where(spent_on: yesterday))
      week_rows = aggregate(base.where(spent_on: week_from..yesterday))

      month = if settings['period_month'] == '1'
                build_month(base, month_start, month_end, settings)
              else
                nil
              end

      csv = build_csv(yesterday, week_from, month_start, month_end,
                      yesterday_rows, week_rows, month)

      {
        generated: Time.now,
        settings: settings,
        yesterday: { label: yesterday.strftime('%d.%m.%Y'), rows: yesterday_rows, total: total(yesterday_rows) },
        week: { label: "#{week_from.strftime('%d.%m')}–#{yesterday.strftime('%d.%m.%Y')}", rows: week_rows, total: total(week_rows) },
        month: month,
        csv: csv,
        csv_attachment: settings['csv_attachment'] == '1'
      }
    end
  end

  def aggregate(scope)
    scope.group(:user_id, :project_id).sum(:hours).map do |(uid, pid), hours|
      u = User.find_by(id: uid)
      p = Project.find_by(id: pid)
      [u ? u.name : '—', u ? u.login : '', p ? p.name : '—', hours.to_f]
    end.sort_by { |r| [-r[3], r[0]] }
  end

  def total(rows)
    rows.sum { |r| r[3] }
  end

  def build_month(scope, month_start, month_end, settings)
    include_empty = settings['include_empty_days'] == '1'
    weeks = []
    week_idx = 1
    cur_week = []
    d = month_start
    while d <= month_end
      rows = aggregate(scope.where(spent_on: d))
      if rows.empty? && !include_empty
        if d.wday == 0
          weeks << week_struct(week_idx, d - 6, d, cur_week) unless cur_week.empty?
          week_idx += 1
          cur_week = []
        end
        d += 1
        next
      end
      day_label = "#{I18n.l(d, format: '%a')}, #{d.strftime('%d.%m')}"
      cur_week << { label: day_label, rows: rows, total: total(rows) }
      if d.wday == 0
        weeks << week_struct(week_idx, d - 6, d, cur_week) unless cur_week.empty?
        week_idx += 1
        cur_week = []
      end
      d += 1
    end
    unless cur_week.empty?
      weeks << week_struct(week_idx, d - cur_week.length, d - 1, cur_week)
    end
    {
      label: I18n.l(month_start, format: '%B %Y'),
      weeks: weeks,
      total: weeks.sum { |w| w[:total] }
    }
  end

  def week_struct(idx, from, to, days)
    { label: "Неделя #{idx} · #{from.strftime('%d.%m')}–#{to.strftime('%d.%m')}",
      days: days, total: days.sum { |day| day[:total] } }
  end

  def build_csv(yesterday, week_from, month_start, month_end, y_rows, w_rows, month)
    lines = [['Период', 'Пользователь', 'Логин', 'Проект', 'Часы']]
    y_rows.each { |r| lines << ["Вчера #{yesterday.iso8601}", *r] }
    w_rows.each { |r| lines << ["Неделя #{week_from.iso8601}..#{yesterday.iso8601}", *r] }
    if month
      month[:weeks].each do |week|
        week[:days].each do |day|
          day[:rows].each { |r| lines << ["Месяц #{day[:label]}", *r] }
        end
      end
    end
    "\xEF\xBB\xBF" + lines.map { |r| r.map { |c| c.to_s.gsub(/[\r\n]+/, ' ').gsub(';', ',') }.join(';') }.join("\r\n")
  end

  def parse_ids(str)
    str.to_s.split(',').map(&:strip).reject(&:blank?).map(&:to_i)
  end

  def h(s)
    CGI.escapeHTML(s.to_s)
  end

  def num(v)
    format('%.2f', v).tr('.', ',')
  end

  def rows_table(rows, total_row_label)
    html = +'<table border="0" cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;font-size:13px;font-family:Arial,sans-serif;">'
    html << '<tr style="background:#f4f7fa;"><th align="left" style="padding:6px 10px;border-bottom:2px solid #d9e2ec;color:#34495e;">Пользователь</th><th align="left" style="padding:6px 10px;border-bottom:2px solid #d9e2ec;color:#34495e;">Проект</th><th align="right" style="padding:6px 10px;border-bottom:2px solid #d9e2ec;color:#34495e;">Часы</th></tr>'
    rows.each do |r|
      html << "<tr><td style=\"padding:6px 10px;border-bottom:1px solid #eef2f6;\">#{h(r[0])}</td><td style=\"padding:6px 10px;border-bottom:1px solid #eef2f6;\">#{h(r[2])}</td><td align=\"right\" style=\"padding:6px 10px;border-bottom:1px solid #eef2f6;\">#{num(r[3])}</td></tr>"
    end
    html << "<tr style=\"font-weight:bold;\"><td colspan=\"2\" style=\"padding:6px 10px;border-top:2px solid #3d5a80;\">#{h(total_row_label)}</td><td align=\"right\" style=\"padding:6px 10px;border-top:2px solid #3d5a80;\">#{num(total(rows))}</td></tr>"
    html << '</table>'
    html
  end

  def build_html(report)
    s = report[:settings]
    periods = []
    periods << 'Вчера' if s['period_yesterday'] == '1'
    periods << 'Неделя' if s['period_week'] == '1'
    periods << 'Месяц' if s['period_month'] == '1'
    period_badges = periods.map { |p| "<span style=\"background:#3d5a80;color:#fff;border-radius:10px;padding:1px 10px;font-size:11px;\">#{p}</span>" }.join(' ')

    html = +'<!DOCTYPE html><html lang="ru"><head><meta charset="utf-8"></head><body style="margin:0;padding:0;background:#f2f2f2;font-family:Arial,sans-serif;">'
    html << '<div style="max-width:760px;margin:0 auto;background:#fff;border:1px solid #e0e0e0;">'
    html << '<div style="background:#3d5a80;color:#fff;padding:18px 24px;"><h1 style="margin:0;font-size:20px;">Отчёт по трудозатратам</h1><div style="margin-top:6px;font-size:12px;opacity:.9;">Автоматический отчёт · формируется ежедневно в 06:00</div></div>'
    html << '<div style="padding:20px 24px 28px;">'

    html << "<div style=\"background:#fbfcfe;border:1px dashed #c9d6e2;border-radius:6px;padding:10px 14px;font-size:12px;color:#556;\"><b>Сформировано:</b> #{report[:generated].strftime('%d.%m.%Y %H:%M')} &nbsp;·&nbsp; <b>Получатель:</b> #{h(report[:recipients])} &nbsp;·&nbsp; #{period_badges}</div>"

    if s['period_yesterday'] == '1'
      html << "<h2 style=\"font-size:15px;color:#2c3e50;border-bottom:2px solid #e8eef4;padding-bottom:8px;\">1. Вчера — #{report[:yesterday][:label]}</h2>"
      html << rows_table(report[:yesterday][:rows], 'Итого за вчера')
    end

    if s['period_week'] == '1'
      html << "<h2 style=\"font-size:15px;color:#2c3e50;border-bottom:2px solid #e8eef4;padding-bottom:8px;\">2. Неделя — #{report[:week][:label]} (7 дней)</h2>"
      html << rows_table(report[:week][:rows], 'Итого за неделю')
    end

    if s['period_month'] == '1' && report[:month]
      m = report[:month]
      html << "<h2 style=\"font-size:15px;color:#2c3e50;border-bottom:2px solid #e8eef4;padding-bottom:8px;\">3. Месяц — #{h(m[:label])} (календарный) <span style=\"float:right;font-size:12px;color:#3d5a80;\">Итого: #{num(m[:total])} ч</span></h2>"
      if s['month_expand'] == '1'
        m[:weeks].each do |week|
          html << "<div style=\"border:1px solid #e3e9f0;border-radius:6px;margin-bottom:8px;\"><div style=\"background:#eef3f9;padding:8px 12px;font-weight:bold;color:#2c3e50;font-size:13px;\">#{h(week[:label])} <span style=\"float:right;color:#3d5a80;\">#{num(week[:total])} ч</span></div>"
          week[:days].each do |day|
            html << "<div style=\"padding:6px 12px;\"><div style=\"font-weight:bold;color:#445;font-size:12.5px;\">#{h(day[:label])} <span style=\"float:right;color:#3d5a80;\">#{num(day[:total])} ч</span></div><div style=\"padding:4px 0 8px;\">#{rows_table(day[:rows], 'Итого за день')}</div></div>"
          end
          html << '</div>'
        end
      else
        month_rows = m[:weeks].flat_map { |w| w[:days] }.flat_map { |d| d[:rows] }
        html << rows_table(month_rows, 'Итого за месяц')
      end
    end

    if report[:csv_attachment]
      html << "<div style=\"margin-top:24px;padding:12px 14px;background:#f4f7fa;border-radius:6px;font-size:12px;color:#445;\">📎 Вложение: <b>time_report_#{Date.today.iso8601}.csv</b> — Период; Пользователь; Логин; Проект; Часы</div>"
    end

    html << '</div>'
    html << '<div style="font-size:11px;color:#999;padding:12px 24px;border-top:1px solid #eee;background:#fafafa;">Redmine · Автоматический отчёт по трудозатратам.</div>'
    html << '</div></body></html>'
    html
  end
end
