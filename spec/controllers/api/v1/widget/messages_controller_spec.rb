require 'rails_helper'

RSpec.describe '/api/v1/widget/messages', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account, email: nil) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:conversation) { create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { ::Widget::TokenService.new(payload: payload).generate_token }

  before do
    2.times.each { create(:message, account: account, inbox: web_widget.inbox, conversation: conversation) }
  end

  describe 'GET /api/v1/widget/messages' do
    context 'when get request is made' do
      it 'returns messages in conversation' do
        get api_v1_widget_messages_url,
            params: { website_token: web_widget.website_token },
            headers: { 'X-Auth-Token' => token },
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)

        # 2 messages created + 3 messages by the template hook
        expect(json_response.length).to eq(5)
      end
    end
  end

  describe 'POST /api/v1/widget/messages' do
    context 'when post request is made' do
      it 'creates message in conversation' do
        conversation.destroy # Test all params
        message_params = { content: 'hello world', timestamp: Time.current }
        post api_v1_widget_messages_url,
             params: { website_token: web_widget.website_token, message: message_params },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['content']).to eq(message_params[:content])
      end

      it 'creates attachment message in conversation' do
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
        message_params = { content: 'hello world', timestamp: Time.current, attachment: { file: file } }
        post api_v1_widget_messages_url,
             params: { website_token: web_widget.website_token, message: message_params },
             headers: { 'X-Auth-Token' => token }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['content']).to eq(message_params[:content])

        expect(conversation.messages.last.attachment.file.present?).to eq(true)
        expect(conversation.messages.last.attachment.file_type).to eq('image')
      end
    end
  end

  describe 'PUT /api/v1/widget/messages' do
    context 'when put request is made with non existing email' do
      it 'updates message in conversation and creates a new contact' do
        message = create(:message, content_type: 'input_email', account: account, inbox: web_widget.inbox, conversation: conversation)
        email = Faker::Internet.email
        contact_params = { email: email }
        put api_v1_widget_message_url(message.id),
            params: { website_token: web_widget.website_token, contact: contact_params },
            headers: { 'X-Auth-Token' => token },
            as: :json

        expect(response).to have_http_status(:success)
        message.reload
        expect(message.submitted_email).to eq(email)
        expect(message.conversation.contact.email).to eq(email)
      end
    end

    context 'when put request is made with invalid email' do
      it 'rescues the error' do
        message = create(:message, account: account, content_type: 'input_email', inbox: web_widget.inbox, conversation: conversation)
        contact_params = { email: nil }
        put api_v1_widget_message_url(message.id),
            params: { website_token: web_widget.website_token, contact: contact_params },
            headers: { 'X-Auth-Token' => token },
            as: :json

        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context 'when put request is made with existing email' do
      it 'updates message in conversation and deletes the current contact' do
        message = create(:message, account: account, content_type: 'input_email', inbox: web_widget.inbox, conversation: conversation)
        email = Faker::Internet.email
        create(:contact, account: account, email: email)
        contact_params = { email: email }
        put api_v1_widget_message_url(message.id),
            params: { website_token: web_widget.website_token, contact: contact_params },
            headers: { 'X-Auth-Token' => token },
            as: :json

        expect(response).to have_http_status(:success)
        message.reload
        expect { contact.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'ignores the casing of email, updates message in conversation and deletes the current contact' do
        message = create(:message, content_type: 'input_email', account: account, inbox: web_widget.inbox, conversation: conversation)
        email = Faker::Internet.email
        create(:contact, account: account, email: email)
        contact_params = { email: email.upcase }
        put api_v1_widget_message_url(message.id),
            params: { website_token: web_widget.website_token, contact: contact_params },
            headers: { 'X-Auth-Token' => token },
            as: :json

        expect(response).to have_http_status(:success)
        message.reload
        expect { contact.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
