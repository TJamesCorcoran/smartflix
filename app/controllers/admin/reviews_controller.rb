class Admin::ReviewsController < Admin::Base


  def index
    if request.put?
      review = Rating.find_by_rating_id(params[:rating][:id])
      if (review)
        review.review = params[:rating][:review]
        if (params[:commit] == 'Approve')
          review.approved = true
        elsif (params[:commit] == 'Delete')
          review.approved = false
        end
        unless review.save
          flash.now[:message] = "Save failed: #{review.errors.full_messages.join(',')}"
        end
      end
    end
    @reviews = Rating.unapproved_reviews()
  end

end
