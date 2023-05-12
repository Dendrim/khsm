# (c) goodprogrammer.ru
# Объявление фабрики для создания нужных в тестах объектов
# см. другие примеры на
# http://www.rubydoc.info/gems/factory_girl/file/GETTING_STARTED.md

FactoryGirl.define do
  factory :user do
    name { "Жора_#{rand(999)}" }

    sequence(:email) { |n| "someguy_#{n}@example.com" }

    is_admin false
    balance 0

    after(:build)  {|u| u.password_confirmation = u.password = "123456"}
  end
end
