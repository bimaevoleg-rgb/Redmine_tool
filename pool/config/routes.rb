RedmineApp::Application.routes.draw do
  match 'projects/:project_id/polls', to: 'polls#index', via: :get, as: 'project_polls'
  match 'projects/:project_id/polls/new', to: 'polls#new', via: :get, as: 'new_project_poll'
  match 'projects/:project_id/polls', to: 'polls#create', via: :post
  match 'projects/:project_id/polls/:id', to: 'polls#show', via: :get, as: 'project_poll'
  match 'projects/:project_id/polls/:id/edit', to: 'polls#edit', via: :get, as: 'edit_project_poll'
  match 'projects/:project_id/polls/:id', to: 'polls#update', via: :patch
  match 'projects/:project_id/polls/:id', to: 'polls#destroy', via: :delete
  match 'projects/:project_id/polls/:id/vote', to: 'polls#vote', via: :post, as: 'vote_project_poll'
  match 'projects/:project_id/polls/:id/cancel_vote', to: 'polls#cancel_vote', via: :delete, as: 'cancel_vote_project_poll'
  match 'projects/:project_id/polls/:id/report', to: 'polls#report', via: :get, as: 'report_project_poll'
end
