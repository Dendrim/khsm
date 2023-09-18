require 'rails_helper'
require 'rspec/expectations'

describe 'users/show.html.erb', type: :view do
  before do
    assign(:user, user)
    assign(:stranger_user, stranger_user)
    assign(:games, [FactoryBot.build(:game)])

    stub_template('users/_game.html.erb' => 'game info is here')
  end

  let(:user) { FactoryBot.create(:user, name: 'owner') }
  let(:stranger_user) { FactoryBot.create(:user, name: 'not owner') }

  context 'always shows' do
    before { render }

    it 'renders user name' do
      expect(rendered).to match 'owner'
    end

    it 'renders game partial' do
      expect(rendered).to match 'game info is here'
    end
  end

  context 'on owners page' do
    before do
      sign_in user
      render
    end

    it 'renders password/name reset link' do
      expect(rendered).to match 'Сменить имя и пароль'
    end
  end

  context "on stranger's page" do
    before do
      sign_in stranger_user
      render
    end

    it 'does not render password/name reset link' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end
  end
end
