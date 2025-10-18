# frozen_string_literal: true

class RodauthApp < Rodauth::Rails::App
  configure RodauthMain, :main

  route do |r|
    r.rodauth(:main) # route rodauth requests
  end
end 