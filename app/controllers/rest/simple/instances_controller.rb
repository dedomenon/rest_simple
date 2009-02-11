class Rest::Simple::InstancesController < ApplicationController
  accept_auth :api_key ,:http_basic_auth 
  require 'entities_module'
  include EntitiesHelpers
  
  before_filter :login_required

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

    @entity = Entity.find params["id"]
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
      format.json { render :json => @list.to_json }
    end
  end
end
