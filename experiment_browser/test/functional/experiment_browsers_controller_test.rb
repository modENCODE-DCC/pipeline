require File.dirname(__FILE__) + '/../test_helper'

class ExperimentBrowsersControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:experiment_browsers)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_experiment_browser
    assert_difference('ExperimentBrowser.count') do
      post :create, :experiment_browser => { }
    end

    assert_redirected_to experiment_browser_path(assigns(:experiment_browser))
  end

  def test_should_show_experiment_browser
    get :show, :id => experiment_browsers(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => experiment_browsers(:one).id
    assert_response :success
  end

  def test_should_update_experiment_browser
    put :update, :id => experiment_browsers(:one).id, :experiment_browser => { }
    assert_redirected_to experiment_browser_path(assigns(:experiment_browser))
  end

  def test_should_destroy_experiment_browser
    assert_difference('ExperimentBrowser.count', -1) do
      delete :destroy, :id => experiment_browsers(:one).id
    end

    assert_redirected_to experiment_browsers_path
  end
end
