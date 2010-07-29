require File.dirname(__FILE__) + '/../test_helper'
require 'seahunt_controller'

# Re-raise errors caught by the controller.
class SeahuntController; def rescue_action(e) raise e end; end

class SeahuntControllerTest < Test::Unit::TestCase
  def setup
    @controller = SeahuntController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
