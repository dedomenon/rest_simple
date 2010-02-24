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
    crosstab_result =  @entity.crosstab_query()
    if crosstab_result.nil?
      render :json => {} and return
    end

    @details = @entity.details_hash


    @list, @paginator = @entity.get_paginated_list(:filters =>  [crosstab_filter] , :format => params[:format], :highlight => params[:highlight], :default_page => params[list_id+"_page"] || ((params[:startIndex].to_i/list_length).ceil + 1) , :order_by => order_by, :direction => sort_direction, :list_length => list_length )



#    crosstab_query     = crosstab_result[:query]
#    crosstab_row =  CrosstabObject.connection.execute("select count(*) from #{crosstab_query} #{join_filters([crosstab_filter])}")[0]
#    crosstab_count = crosstab_row[0] ? crosstab_row[0] : crosstab_row['count']
#
#    @paginator = Paginator.new self, crosstab_count.to_i, list_length, page_number
#    limit, offset = @paginator.current.to_sql
#
#    query = "select * from #{crosstab_query}  #{join_filters([crosstab_filter])} order by \"#{order_by}\""
#    if params["format"]!="csv"
#      query += " limit #{limit} offset #{offset}"
#    end
#    @list = CrosstabObject.find_by_sql(query)

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



#copied from entity_controller
  def sort_direction
    CrosstabObject.connection.quote_string(params[:dir].to_s)
  end

# returns a quoted version of the requestion column sorting
   def order_by
    session["list_order"]||={}
    if params[:sort]
      order=CrosstabObject.connection.quote_string(params[:sort].to_s)
    elsif params[order_param] and ! params["highlight"] or params["highlight"]==""
      order=CrosstabObject.connection.quote_string(params[order_param].to_s)
      session["list_order"][list_id]=order
    elsif session["list_order"].has_key? [list_id]
      order = session["list_order"][list_id]
    else
      order = "id"
    end
    return order
  end
  def crosstab_filter
    if detail_filter.nil?
      return ""
    else
      detail = Detail.find detail_filter
      return "\"#{CrosstabObject.connection.quote_string(detail.name.downcase)}\"::text ilike '#{leading_wildcard}#{CrosstabObject.connection.quote_string(params["value_filter"].to_s)}#{trailing_wildcard}'"
    end
  end

end
