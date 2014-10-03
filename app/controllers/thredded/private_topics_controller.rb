module Thredded
  class PrivateTopicsController < Thredded::ApplicationController
    before_filter :ensure_messageboard_exists

    def index
      if cannot? :read, messageboard
        error = 'You are not authorized access to this messageboard.'
        redirect_to default_home, flash: { error: error }
      else
        @private_topics = private_topics
      end
    end

    def new
      @private_topic = messageboard.private_topics.build
      @private_topic.posts.build(filter: current_user.try(:post_filter))

      unless can? :create, @private_topic
        error = 'Sorry, you are not authorized to post on this messageboard.'
        redirect_to messageboard_topics_url(messageboard),
          flash: { error: error }
      end
    end

    def create
      params[:topic][:user_id] << current_user.id
      merge_default_topics_params
      @private_topic = PrivateTopic.create(params[:topic])
      redirect_to messageboard_topics_url(messageboard)
    end

    def private_topics
      PrivateTopic
        .for_messageboard(messageboard)
        .including_roles_for(current_user)
        .for_user(current_user)
        .order_by_stuck_and_updated_time
        .on_page(params[:page])
    end
  end
end
