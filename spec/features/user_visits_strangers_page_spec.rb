require 'rails_helper'

RSpec.feature 'user views other profile', type: :feature do
  let!(:page_owner) { FactoryBot.create(:user, name: 'Page Owner') }
  let!(:viewer) { FactoryBot.create(:user, name: 'Viewer') }

  let!(:games) do
    [
      FactoryBot.create(
        :game,
        user_id: page_owner.id,
        is_failed: true,
        current_level: 13,
        prize: 1000,
        created_at: Time.parse('2023.01.1, 10:00'),
        finished_at: Time.parse('2023.01.1, 10:40')
      ),
      FactoryBot.create(
        :game,
        user_id: page_owner.id,
        is_failed: false,
        current_level: 14,
        prize: 2000,
        created_at: Time.parse('2023.01.1, 11:00'),
        finished_at: Time.parse('2023.01.1, 11:20')
      ),
      FactoryBot.create(
        :game,
        user_id: page_owner.id,
        is_failed: true,
        current_level: 8,
        prize: 3000,
        created_at: Time.parse('2023.01.1, 12:00'),
        finished_at: Time.parse('2023.01.1, 12:05')
      ),
      FactoryBot.create(
        :game,
        user_id: page_owner.id,
        current_level: 9,
        created_at: Time.parse('2023.01.1, 13:00')
      )
    ]
  end

  before { login_as viewer }

  scenario 'success' do
    visit user_path(page_owner)

    expect(page).not_to have_content 'Сменить имя и пароль'

    expect(page).to have_content 'Page Owner'

    expect(page).to have_content 'проигрыш'
    expect(page).to have_content 'деньги'
    expect(page).to have_content 'время'
    expect(page).to have_content 'в процессе'

    expect(page).to have_content '1 янв., 10:00'
    expect(page).to have_content '1 янв., 11:00'
    expect(page).to have_content '1 янв., 12:00'
    expect(page).to have_content '1 янв., 13:00'

    expect(page).to have_content '1 000 ₽'
    expect(page).to have_content '2 000 ₽'
    expect(page).to have_content '3 000 ₽'
    expect(page).to have_content ' 0 ₽'

    expect(page).to have_content '13'
    expect(page).to have_content '14'
    expect(page).to have_content '8'
    expect(page).to have_content '9'

    expect(page).to have_content '50/50'
  end
end
