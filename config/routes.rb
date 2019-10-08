MozillaGCM::Engine.routes.draw do
  defaults format: :json do
    resources :groups, only: [:create, :show, :update, :destroy]
    patch "/groups/:id/users", to: "groups#modify_users"

    resources :categories, only: [:create, :show, :update, :destroy]
    resources :users, only: [:show]
  end
end
