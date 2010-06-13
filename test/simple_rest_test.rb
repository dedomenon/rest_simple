require 'test/unit'
require File.dirname(__FILE__)+'/../../../../test/test_helper.rb'
#require File.dirname(__FILE__)+'/../../../../vendor/rails/railties/test/plugin_test_helper.rb'

#FIXME : the first get of a test has to specify the :format => 'json' option, the other not. I do not know what's happening
class SimpleRestTest < ActionController::TestCase
  # Replace this with your real tests.
   self.fixture_path=File.dirname(__FILE__)+'/fixtures'
  
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
    @controller = Rest::Simple::V1::InstancesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  def test_unauthorized_get_unfiltered_list
    #no api key provided, return 401
    get :index, {'id'=> 12}
    assert_response 401

    #data is not available publicly, return 403 status
    #same account
    get :index, {'id'=> 12, 'format'=> 'json',  :api_key=> "ArgsfgDFGesgsf"  }
    assert_response 403
    #other account
    get :index, {'id'=> 12,  :api_key=> "56HGRhdfY4"  }
    assert_response 403
  end

  def test_account_only_data
    #data is not available publicly, return 403 status
    publish_entity(12, false)
    #same account
    get :index, {'id'=> 12, 'format' => 'json', :api_key=> "ArgsfgDFGesgsf"  }
    assert_response :success
    get :index, {'id'=> 12, 'format' => 'json', :api_key=> "56HGRhdfY4"  }
    assert_response 403
  end 

  def test_authorized_get_unfiltered_list
    publish_entity(12)
    get :index, {'id'=> 12, 'format' => 'json', :api_key=> "56HGRhdfY4"  }
    assert_response :success
    assert_equal 15, assigns["list"].length
    assert_equal JSON.parse(@response.body), JSON.parse(json_file('all_entities'))
  end

  def test_filtered
    publish_entity(12)

    # ----------------------------------
    # Filter on start of value (default)
    # ----------------------------------
    get :index, {:id=> 12, :format => 'json',   :detail_filter => 'prenom', :value_filter => 'incent' , :api_key=> "56HGRhdfY4"  }
    assert_response :success
    assert_equal 0, assigns["list"].length
    assert_equal @response.body, %{[]}

    get :index, {:id=> 12, :detail_filter => 'nom', :value_filter => 'b' , :api_key=> "56HGRhdfY4"  }
    assert_response :success
    assert_equal 5, assigns["list"].length
    assert_equal JSON.parse(@response.body), JSON.parse(json_file('persons_name_start_with_b_unordered'))


    get :index, {:id=> 12, :detail_filter => 'nom', :value_filter => 'b', :order_by => 'nom' , :api_key=> "56HGRhdfY4"  }
    assert_response :success
    assert_equal 5, assigns["list"].length
    assert_equal JSON.parse(@response.body), JSON.parse(json_file('persons_name_start_with_b_ordered_by_nom'))
    
    get :index, {:id=> 12, :detail_filter => 'nom', :value_filter => 'b', :order_by => 'prenom' , :api_key=> "56HGRhdfY4"  }
    assert_response :success
    assert_equal 5, assigns["list"].length
    assert_equal JSON.parse(@response.body) , JSON.parse(json_file('persons_name_start_with_b_ordered_by_prenom'))

    get :index, {:id=> 12, :detail_filter => 'nom', :value_filter => 'b', :order_by => 'prenom' , :api_key=> "56HGRhdfY4", :callback=> "my_callback"  }
    assert_response :success
    assert_equal 5, assigns["list"].length
    # skip this test, order of json fields changes when upgrading
    #assert_equal @response.body, json_file('persons_name_start_with_b_ordered_by_prenom_in_callback')
    assert_match Regexp.new('my_callback(.*)'), @response.body

    
    # ------------------------------
    # Don't filter on start of value 
    # ------------------------------
    get :index, {:id=> 12, :detail_filter => 'prenom', :value_filter => 'incent', :starts_with => "no" , :api_key=> "56HGRhdfY4"  }
    assert_response :success
    assert_equal 1, assigns["list"].length
    assert_equal JSON.parse(@response.body), JSON.parse(%{[{"fonction":"Chief","nom":"Luyckx","prenom":"Vincent","service":"","coordonees_specifiques":"chambre de commerce namur, trucksharing, b2a, b2i","company_email":"valtech@broebel.net","id":70}]})



    get :index, {:id=> 12, :detail_filter => 'prenom', :value_filter => 'a' , :starts_with => "no", :api_key=> "56HGRhdfY4"  }
    assert_response :success
    assert_equal 6, assigns["list"].length
    assert_equal JSON.parse(@response.body), JSON.parse(json_file('entities_with_prenom_containing_a'))


    get :index, {:id=> 12, :detail_filter => 'prenom', :value_filter => 'a', :order_by => 'nom' , :starts_with => "no", :api_key=> "56HGRhdfY4"  }
    assert_response :success
    assert_equal 6, assigns["list"].length
    assert_equal JSON.parse(@response.body), JSON.parse(json_file('entities_with_prenom_containing_a_order_by_nom'))

    # ------------------------------
    # Check a filter on end of value
    # ------------------------------

    get :index, {:id=> 12, :detail_filter => 'nom', :value_filter => 'in', :api_key=> "56HGRhdfY4"  }
    assert_response :success
    assert_equal 0, assigns["list"].length

    get :index, {:id=> 12, :detail_filter => 'nom', :value_filter => 'in', :starts_with => "no", :ends_with => "yes", :api_key=> "56HGRhdfY4"  }
    assert_response :success
    assert_equal 2, assigns["list"].length
    assert_equal JSON.parse(@response.body),JSON.parse( json_file('persons_name_ends_with_in'))
  end


  def json_file(f)
    File.read(File.dirname(__FILE__)+'/json/'+f+'.json').chomp
  end

  def publish_entity(id, public_to_all =true )
    entity= Entity.find(id)
    entity.has_public_data = true
    entity.public_to_all = public_to_all
    entity.save
  end
end
