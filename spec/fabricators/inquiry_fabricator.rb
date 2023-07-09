# frozen_string_literal: true

Fabricator(:inquiry) do
  message     'MyString'
  status      1
  action_type 1
  user        { Fabricate.build(:user) }
end
