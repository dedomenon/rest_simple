class Rest::Simple::V1::InstancesController < ApplicationController
  accept_auth :api_key ,:http_basic_auth 
  require 'entities_module'
  include EntitiesHelpers
  
  before_filter :login_required
  before_filter :check_data_is_public
  before_filter :set_search_value_param_name

  def list_length
    RestSimpleSettings.list_length
  end
  def list_id
    ''
  end
  
  # rename the detault order by params as the default used in the app is more complicated to accept multiple lists on one page
  def order_param
    "order_by"
  end

  # our filters match the start by default
  def match_start?
    params[:starts_with] ? params[:starts_with]!='no' : true
  end
  def match_end?
    params[:ends_with] ? params[:ends_with]=='yes' : false
  end

  def index

    @entity ||= Entity.find params["id"]
    crosstab_result =  crosstab_query_for_entity(params["id"])
    if crosstab_result.nil?
      render :json => {} and return
    end

    @details = build_details_hash
    crosstab_query     = crosstab_result[:query]
    crosstab_row =  CrosstabObject.connection.execute("select count(*) from #{crosstab_query} #{join_filters([crosstab_filter])}")[0]
    crosstab_count = crosstab_row[0] ? crosstab_row[0] : crosstab_row['count']

    @paginator = Paginator.new self, crosstab_count.to_i, list_length, page_number
    limit, offset = @paginator.current.to_sql

    query = "select * from #{crosstab_query}  #{join_filters([crosstab_filter])} order by \"#{order_by}\""
    if params["format"]!="csv"
      query += " limit #{limit} offset #{offset}"
    end
    @list = CrosstabObject.find_by_sql(query)

    respond_to do |format|
      format.json { 
        if params[:callback]
          r = "#{params[:callback]}("
          r+= @list.to_json
          r+= ")"
        else
          r=@list.to_json
        end
        render :json => r }
    end
  end

  private

  def check_data_is_public
    @entity ||= Entity.find params["id"]
    if  @entity.has_public_data?
      # if data public for account only, check account of requestor
      if @entity.public_to_all?
        return true 
      else
        return true if @entity.database.account==current_user.account
      end
    end
    #if we get here, reject the request
    respond_to do |format|
      format.html { render :status => 403, :text => "Data not publicly available" }
      format.json { render :status => 403, :json => { :message => "Unauthorized: data not publicly available"} }
    end
  end

  def set_search_value_param_name
    if params[:value_filter].nil? and params[:value_filter_parameter_name]
      params[:value_filter]= params[params[:value_filter_parameter_name]]
    end
  end
end
