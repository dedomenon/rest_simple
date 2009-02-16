class Rest::Simple::Admin::EntitiesController < ApplicationController
  before_filter :login_required
  def toggle_public_data
    entity = Entity.find params['id']
    entity.has_public_data=params["value"]||false
    entity.save
    render :nothing => true
  end

end
