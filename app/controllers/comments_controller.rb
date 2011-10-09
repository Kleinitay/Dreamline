class CommentsController < ApplicationController

  def create
    unless !signed_in? || !params[:comment]
      more_params = {:user_id => current_user.id } #temp duration
      @comment = Comment.new(params[:comment].merge(more_params))
      if @comment.save
        flash[:notice] = 'Comment has been published'
        redirect_to "/"
      else
        puts "no"
      end
    else
      redirect_to "/"
    end
  end

end