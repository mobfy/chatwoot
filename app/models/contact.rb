# == Schema Information
#
# Table name: contacts
#
#  id                    :integer          not null, primary key
#  additional_attributes :jsonb
#  email                 :string
#  identifier            :string
#  name                  :string
#  phone_number          :string
#  pubsub_token          :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#
# Indexes
#
#  index_contacts_on_account_id         (account_id)
#  index_contacts_on_pubsub_token       (pubsub_token) UNIQUE
#  uniq_email_per_account_contact       (email,account_id) UNIQUE
#  uniq_identifier_per_account_contact  (identifier,account_id) UNIQUE
#

class Contact < ApplicationRecord
  include Pubsubable
  include Avatarable
  include AvailabilityStatusable
  validates :account_id, presence: true
  validates :email, allow_blank: true, uniqueness: { scope: [:account_id], case_sensitive: false }
  validates :identifier, allow_blank: true, uniqueness: { scope: [:account_id] }

  belongs_to :account
  has_many :conversations, dependent: :destroy
  has_many :contact_inboxes, dependent: :destroy
  has_many :inboxes, through: :contact_inboxes
  has_many :messages, dependent: :destroy

  before_validation :downcase_email

  def get_source_id(inbox_id)
    contact_inboxes.find_by!(inbox_id: inbox_id).source_id
  end

  def push_event_data
    {
      id: id,
      name: name,
      thumbnail: avatar_url,
      pubsub_token: pubsub_token
    }
  end

  def webhook_data
    {
      id: id,
      name: name
    }
  end

  def downcase_email
    email.downcase! if email.present?
  end
end
