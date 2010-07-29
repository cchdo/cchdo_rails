require File.dirname(__FILE__) + '/../test_helper'
require 'bulk_search_controller'

# Re-raise errors caught by the controller.
class BulkSearchController; def rescue_action(e) raise e end; end

class BulkSearchControllerTest < Test::Unit::TestCase
  def setup
    @controller = BulkSearchController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
