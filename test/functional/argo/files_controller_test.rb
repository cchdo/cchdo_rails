require 'test_helper'

class Argo::FilesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:argo_files)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create file" do
    assert_difference('Argo::File.count') do
      post :create, :file => { }
    end

    assert_redirected_to file_path(assigns(:file))
  end

  test "should show file" do
    get :show, :id => argo_files(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => argo_files(:one).to_param
    assert_response :success
  end

  test "should update file" do
    put :update, :id => argo_files(:one).to_param, :file => { }
    assert_redirected_to file_path(assigns(:file))
  end

  test "should destroy file" do
    assert_difference('Argo::File.count', -1) do
      delete :destroy, :id => argo_files(:one).to_param
    end

    assert_redirected_to argo_files_path
  end
end
