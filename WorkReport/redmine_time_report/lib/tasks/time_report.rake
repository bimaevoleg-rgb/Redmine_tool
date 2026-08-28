# frozen_string_literal: true

require_relative '../time_report'

namespace :redmine do
  namespace :time_report do
    desc 'Send daily time report (yesterday, week, calendar month)'
    task :send => :environment do
      dry = ENV['dry_run'] == '1'
      report = TimeReport.send_daily(dry_run: dry)
      if dry
        puts "Dry-run: отчёт сохранён в #{report[:file]}"
      else
        puts "Отчёт отправлен: #{report[:recipients]}"
      end
    end
  end
end
