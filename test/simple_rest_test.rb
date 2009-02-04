require 'test/unit'
require File.dirname(__FILE__)+'/../../../../test/test_helper.rb'
class SimpleRestTest < Test::Unit::TestCase
  # Replace this with your real tests.
  fixtures    :account_types, 
              :accounts, 
              :databases, 
              :data_types, 
              :detail_status, 
              :details, 
              :detail_value_propositions, 
              :entities, 
              :entities2details, 
              :relation_side_types, 
              :relations, 
              :instances, 
              :detail_values, 
              :integer_detail_values, 
              :date_detail_values, 
              :ddl_detail_values, 
              :links, 
              :user_types, 
              :users
  def setup
    @controller = Rest::Simple::InstancesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  def test_get_unfiltered_list
    get :index, {'id'=> 12}
    assert_response :success

    assert_equal 15, assigns["list"].length
    assert_equal @response.body, json_file('all_entities')
  end

  def test_filtered
    # ----------------------------------
    # Filter on start of value (default)
    # ----------------------------------
    get :index, {:id=> 12, :detail_filter => 'prenom', :value_filter => 'incent' }
    assert_response :success
    assert_equal 0, assigns["list"].length
    assert_equal @response.body, %{[]}

    get :index, {:id=> 12, :detail_filter => 'nom', :value_filter => 'b' }
    assert_response :success
    assert_equal 5, assigns["list"].length
    assert_equal @response.body, json_file('persons_name_start_with_b_unordered')


    get :index, {:id=> 12, :detail_filter => 'nom', :value_filter => 'b', :order_by => 'nom' }
    assert_response :success
    assert_equal 5, assigns["list"].length
    assert_equal @response.body, json_file('persons_name_start_with_b_ordered_by_nom')
    
    get :index, {:id=> 12, :detail_filter => 'nom', :value_filter => 'b', :order_by => 'prenom' }
    assert_response :success
    assert_equal 5, assigns["list"].length
    assert_equal @response.body, json_file('persons_name_start_with_b_ordered_by_prenom')


    
    # ------------------------------
    # Don't filter on start of value 
    # ------------------------------
    get :index, {:id=> 12, :detail_filter => 'prenom', :value_filter => 'incent', :starts_with => "no" }
    assert_response :success
    assert_equal 1, assigns["list"].length
    assert_equal @response.body, %{[{"fonction":"Chief","nom":"Luyckx","prenom":"Vincent","service":"","coordonees_specifiques":"chambre de commerce namur, trucksharing, b2a, b2i","company_email":"valtech@broebel.net","id":70}]}



    get :index, {:id=> 12, :detail_filter => 'prenom', :value_filter => 'a' , :starts_with => "no"}
    assert_response :success
    assert_equal 6, assigns["list"].length
    assert_equal @response.body, json_file('entities_with_prenom_containing_a')


    get :index, {:id=> 12, :detail_filter => 'prenom', :value_filter => 'a', :order_by => 'nom' , :starts_with => "no"}
    assert_response :success
    assert_equal 6, assigns["list"].length
    assert_equal @response.body, json_file('entities_with_prenom_containing_a_order_by_nom')

    # ------------------------------
    # Check a filter on end of value
    # ------------------------------

    get :index, {:id=> 12, :detail_filter => 'nom', :value_filter => 'in'}
    assert_response :success
    assert_equal 0, assigns["list"].length

    get :index, {:id=> 12, :detail_filter => 'nom', :value_filter => 'in', :starts_with => "no", :ends_with => "yes"}
    assert_response :success
    assert_equal 2, assigns["list"].length
    assert_equal @response.body, json_file('persons_name_ends_with_in')
  end


  def json_file(f)
    File.read(File.dirname(__FILE__)+'/json/'+f+'.json').chomp
  end
end
