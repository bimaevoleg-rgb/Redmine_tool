# frozen_string_literal: true

class TimeReportMailer < ActionMailer::Base
  def daily_report(recipients, report)
    @report = report
    if report[:csv_attachment]
      attachments["time_report_#{Date.today.iso8601}.csv"] = { mime_type: 'text/csv', content: report[:csv] }
    end
    mail to: recipients,
         subject: "Отчёт по трудозатратам #{Date.today.strftime('%d.%m.%Y')}",
         body: TimeReport.build_html(report),
         content_type: 'text/html'
  end
end
