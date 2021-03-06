# frozen_string_literal: true

#
# Document
#
module Barong
  class Document
    include ActiveModel::Model
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming

    TYPES = ["Passport", "Identity card", "Driver license", "Bank Statement", "Card Statement", "Utility Bill"].freeze
    STATES = %w[verified pending rejected].freeze

    validates :doc_type, :doc_number, :doc_expire, :upload, presence: true
    validates :doc_type, inclusion: { in: TYPES }

    validates :doc_number, length: { maximum: 128 },
                           format: {
                             with: /\A[A-Za-z0-9\-\s]+\z/,
                             message: "only allows letters and digits",
                           }, if: proc { |a| a.doc_number.present? }
    validates_format_of :doc_expire,
                        with: /\A\d{4}\-\d{2}\-\d{2}\z/,
                        message: "Date must be in the following format: yyyy-mm-dd"
    validate :doc_expire_not_in_the_past

    def persisted?
      false
    end

    attr_accessor :doc_type, :doc_number, :doc_expire, :upload, :errors

    def initialize(doc_type = "", doc_number = "", doc_expire = "", upload = nil)
      @doc_type = doc_type
      @doc_number = doc_number
      @doc_expire = doc_expire
      @upload = upload
      @errors = ActiveModel::Errors.new(self)
    end

    private

    def doc_expire_not_in_the_past
      return if doc_expire.blank?
      errors.add(:doc_expire, :invalid) if doc_expire < Date.current
    end

    def create_or_update_document_label
      account_document_label = account.labels.find_by(key: :document)
      if account_document_label.nil?
        account.labels.create(key: :document, value: :pending, scope: :private)
      elsif account_document_label.value != "verified"
        account_document_label.update(value: :pending)
      end
    end
  end
end

# == Schema Information
# Schema version: 20180507095118
#
# Table name: documents
#
#  id         :integer          not null, primary key
#  account_id :integer
#  upload     :string(255)
#  doc_type   :string(255)
#  doc_number :string(255)
#  doc_expire :date
#  metadata   :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_documents_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
