require 'spec_helper'

module Thredded
  describe NotifyMentionedUsers, '#run' do
    before do
      sam  = create(:user, name: 'sam')
      @joel = create(:user, name: 'joel', email: 'joel@example.com')
      @john = create(:user, name: 'john', email: 'john@example.com')
      @post = create(:post, user: sam, content: 'hey @joel and @john. - @sam')
      @messageboard = @post.messageboard

      @messageboard.add_member(@joel)
      @messageboard.add_member(@john)
      @messageboard.add_member(sam)
    end

    it 'returns 2 users mentioned, not including post author' do
      create(:messageboard_preference,
        user: @joel,
        notify_on_mention: true,
        messageboard: @messageboard,
      )
      create(:messageboard_preference,
        user: @john,
        notify_on_mention: true,
        messageboard: @messageboard,
      )

      notifier = NotifyMentionedUsers.new(@post)
      at_notifiable_members = notifier.at_notifiable_members

      at_notifiable_members.should have(2).items
      at_notifiable_members.should include @joel
      at_notifiable_members.should include @john
    end

    it 'does not return any users already emailed about this post' do
      create(:messageboard_preference,
        user: @john,
        messageboard: @messageboard,
        notify_on_mention: true,
      )
      create(:messageboard_preference,
        user: @joel,
        messageboard: @messageboard,
        notify_on_mention: true,
      )
      create(:post_notification,
        post: @post,
        email: 'joel@example.com',
      )
      notifier = NotifyMentionedUsers.new(@post)

      notifier.at_notifiable_members.should have(1).item
      notifier.at_notifiable_members.should include @john
    end

    it 'does not return users not included in a private topic' do
      create(
        :messageboard_preference,
        user: @joel,
        messageboard: @messageboard,
        notify_on_mention: true,
      )
      @post.postable = create(
        :private_topic,
        user: @post.user,
        last_user: @post.user,
        messageboard: @post.messageboard,
        users: [@joel]
      )
      notifier = NotifyMentionedUsers.new(@post)

      notifier.at_notifiable_members.should have(1).item
      notifier.at_notifiable_members.should include @joel
    end

    it 'does not return users that set their preference to "no @ notifications"' do
      create(:messageboard_preference,
        user: @john,
        messageboard: @messageboard,
        notify_on_mention: true,
      )
      create(:messageboard_preference,
        notify_on_mention: false,
        user: @joel,
        messageboard: @post.messageboard,
      )
      notifier = NotifyMentionedUsers.new(@post)
      at_notifiable_members = notifier.at_notifiable_members

      at_notifiable_members.should have(1).items
      at_notifiable_members.should include @john
      at_notifiable_members.should_not include @joel
    end
  end

  describe NotifyMentionedUsers, '#notifications_for_at_users' do
    before do
      sam  = create(:user, name: 'sam')
      @joel = create(:user, name: 'joel', email: 'joel@example.com')
      @john = create(:user, name: 'john', email: 'john@example.com')
      @post = create_post_by(sam)

      @messageboard = @post.messageboard
      @messageboard.add_member(@joel)
      @messageboard.add_member(@john)
      @messageboard.add_member(sam)
    end

    it 'does not notify any users already emailed about this post' do
      create(:messageboard_preference,
        user: @john,
        messageboard: @messageboard,
        notify_on_mention: true,
      )
      create(:messageboard_preference,
        user: @joel,
        messageboard: @messageboard,
        notify_on_mention: true,
      )
      NotifyMentionedUsers.new(@post).run
      notified_emails = @post.post_notifications.map(&:email)

      notified_emails.should have(2).items
      notified_emails.should include('joel@example.com')
      notified_emails.should include('john@example.com')
    end

    def create_post_by(user)
      messageboard = create(:messageboard)
      create(
        :post,
        user: user,
        content: 'hi @joel and @john. @sam',
        messageboard: messageboard
      )
    end
  end
end
