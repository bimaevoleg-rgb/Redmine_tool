Redmine::Plugin.register :redmine_time_report do
  name 'Redmine Time Report'
  author 'RMS'
  description 'Ежедневный отчёт по трудозатратам: вчера, неделя, календарный месяц'
  version '0.1.0'
  requires_redmine version_or_higher: '7.0'

  settings :default => {
    'recipients' => 'it@regionms.ru',
    'send_time' => '06:00',
    'period_yesterday' => '1',
    'period_week' => '1',
    'period_month' => '1',
    'month_expand' => '1',
    'include_empty_days' => '0',
    'csv_attachment' => '1',
    'user_filter' => '',
    'project_filter' => ''
  }, :partial => 'settings/time_report'
end
