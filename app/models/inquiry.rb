# frozen_string_literal: true

# == Schema Information
#
# Table name: inquiries
#
#  id          :bigint(8)        not null, primary key
#  message     :string
#  status      :integer          default("active"), not null
#  action_type :integer          default("no_action"), not null
#  user_id     :bigint(8)        not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Inquiry < ApplicationRecord
  belongs_to :user

  enum :status, { active: 0, resolved: 1 }
  enum :action_type, { no_action: 0, direct_message: 1, reply: 2, documentation: 3 }
end
