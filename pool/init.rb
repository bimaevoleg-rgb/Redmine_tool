Redmine::Plugin.register :redmine_polls do
  name 'Redmine Polls'
  author 'RMS'
  description 'Опросы в проектах Redmine: голосование, несколько вариантов, свой вариант, отмена голоса, выгрузка отчёта'
  version '0.2.0'
  requires_redmine version_or_higher: '7.0'

  project_module :polls do
    permission :view_polls, { polls: [:index, :show] }, require: :member
    permission :vote_polls, { polls: [:vote, :cancel_vote] }, require: :member
    permission :manage_polls, { polls: [:new, :create, :edit, :update, :destroy, :report] }, require: :member
  end

  menu :project_menu, :polls, { controller: 'polls', action: 'index' },
       caption: :label_polls, after: :activity, param: :project_id
end
