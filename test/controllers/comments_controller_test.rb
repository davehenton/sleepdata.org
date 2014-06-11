require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  setup do
    @comment = comments(:one)
    @topic = topics(:one)
  end

  # test "should get index" do
  #   get :index
  #   assert_response :success
  #   assert_not_nil assigns(:comments)
  # end

  # test "should get new" do
  #   get :new
  #   assert_response :success
  # end

  test "should create comment" do
    login(users(:valid))
    assert_difference('Comment.count') do
      post :create, topic_id: @topic, comment: { description: "This is my contribution to the discussion." }
    end

    assert_equal "This is my contribution to the discussion.", assigns(:topic).comments.last.description

    assert_redirected_to topic_path(assigns(:topic))
  end

  test "should not create comment as anonymous user" do
    assert_difference('Comment.count', 0) do
      post :create, topic_id: @topic, comment: { description: "I'm not logged in." }
    end

    assert_redirected_to new_user_session_path
  end

  # test "should show comment" do
  #   get :show, id: @comment
  #   assert_response :success
  # end

  # test "should get edit" do
  #   get :edit, id: @comment
  #   assert_response :success
  # end

  # test "should update comment" do
  #   patch :update, id: @comment, comment: { deleted: @comment.deleted, description: @comment.description, topic_id: @comment.topic_id, user_id: @comment.user_id }
  #   assert_redirected_to comment_path(assigns(:comment))
  # end

  # test "should destroy comment" do
  #   assert_difference('Comment.count', -1) do
  #     delete :destroy, id: @comment
  #   end

  #   assert_redirected_to comments_path
  # end
end
