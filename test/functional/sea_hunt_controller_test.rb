require File.dirname(__FILE__) + '/../test_helper'
require 'sea_hunt_controller'

# Re-raise errors caught by the controller.
class SeaHuntController; def rescue_action(e) raise e end; end

class SeaHuntControllerTest < Test::Unit::TestCase
  def setup
    @controller = SeaHuntController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
