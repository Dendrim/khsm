FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "someguy_#{n}@example.com" }

    name { "Жора_#{rand(999)}" }
    is_admin { false }
    balance { 0 }

    after(:build) { |u| u.password_confirmation = u.password = '123456' }
  end
end
