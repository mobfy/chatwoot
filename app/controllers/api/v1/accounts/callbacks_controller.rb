class Api::V1::Accounts::CallbacksController < Api::BaseController
  before_action :inbox, only: [:reauthorize_page]

  def register_facebook_page
    user_access_token = params[:user_access_token]
    page_access_token = params[:page_access_token]
    page_name = params[:page_name]
    page_id = params[:page_id]
    inbox_name = params[:inbox_name]
    facebook_channel = current_account.facebook_pages.create!(
      name: page_name, page_id: page_id, user_access_token: user_access_token,
      page_access_token: page_access_token
    )
    set_avatar(facebook_channel, page_id)
    inbox = current_account.inboxes.create!(name: inbox_name, channel: facebook_channel)
    render json: inbox
  end

  def facebook_pages
    @page_details = mark_already_existing_facebook_pages(fb_object.get_connections('me', 'accounts'))
  end

  # get params[:inbox_id], current_account, params[:omniauth_token]
  def reauthorize_page
    if @inbox&.facebook?
      fb_page_id = @inbox.channel.page_id
      page_details = fb_object.get_connections('me', 'accounts')

      if (page_detail = (page_details || []).detect { |page| fb_page_id == page['id'] })
        update_fb_page(fb_page_id, page_detail['access_token'])
        return head :ok
      end
    end

    head :unprocessable_entity
  end

  private

  def inbox
    @inbox = current_account.inboxes.find_by(id: params[:inbox_id])
  end

  def update_fb_page(fb_page_id, access_token)
    get_fb_page(fb_page_id)&.update!(
      user_access_token: @user_access_token, page_access_token: access_token
    )
  end

  def get_fb_page(fb_page_id)
    current_account.facebook_pages.find_by(page_id: fb_page_id)
  end

  def fb_object
    @user_access_token = long_lived_token(params[:omniauth_token])
    Koala::Facebook::API.new(@user_access_token)
  end

  def long_lived_token(omniauth_token)
    koala = Koala::Facebook::OAuth.new(ENV['FB_APP_ID'], ENV['FB_APP_SECRET'])
    koala.exchange_access_token_info(omniauth_token)['access_token']
  rescue StandardError => e
    Rails.logger e
  end

  def mark_already_existing_facebook_pages(data)
    return [] if data.empty?

    data.inject([]) do |result, page_detail|
      page_detail[:exists] = current_account.facebook_pages.exists?(page_id: page_detail['id']) ? true : false
      result << page_detail
    end
  end

  def set_avatar(facebook_channel, page_id)
    uri = get_avatar_url(page_id)

    return unless uri

    avatar_resource = LocalResource.new(uri)
    facebook_channel.avatar.attach(io: avatar_resource.file, filename: avatar_resource.tmp_filename, content_type: avatar_resource.encoding)
  end

  def get_avatar_url(page_id)
    begin
      url = 'http://graph.facebook.com/' << page_id << '/picture?type=large'
      uri = URI.parse(url)
      tries = 3
      begin
        response = uri.open(redirect: false)
      rescue OpenURI::HTTPRedirect => e
        uri = e.uri # assigned from the "Location" response header
        retry if (tries -= 1).positive?
        raise
      end
      pic_url = response.base_uri.to_s
    rescue StandardError => e
      Rails.logger.debug "Rescued: #{e.inspect}"
      pic_url = nil
    end
    pic_url
  end
end
