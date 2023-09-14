require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }

  let(:admin) { FactoryGirl.create(:user, is_admin: true) }
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  describe '#show' do
    context 'anonymous user' do
      before { get :show, id: game_w_questions.id }

      it 'returns redirect status' do
        expect(response.status).to eq(302)
      end

      it 'redirects to authorization' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'throws alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'logged in user' do
      before(:each) do
        sign_in user
      end

      let(:game) { assigns(:game) }

      context 'looks at own game' do
        before { get :show, id: game_w_questions.id }

        let(:game) { assigns(:game) }

        it 'operates with unfinished game' do
          expect(game).not_to be_finished
        end

        it 'responds to game owner' do
          expect(game.user).to eq(user)
        end

        it 'returns correct status' do
          expect(response.status).to eq(200)
        end

        it 'renders correct template' do
          expect(response).to render_template('show')
        end

        it 'doesnt throw alert' do
          expect(flash[:alert]).not_to be
        end
      end

      context 'looks at stranger game' do
        let(:stranger) { FactoryGirl.create(:user) }
        let(:stranger_game_w_questions) { FactoryGirl.create(:game_with_questions, user: stranger) }
        before { get :show, id: stranger_game_w_questions.id }

        it 'responds not to game owner' do
          expect(stranger_game_w_questions.user).not_to eq(user)
        end

        it 'responds with redirect status' do
          expect(response.status).not_to eq(200)
        end

        it 'redirects to main page' do
          expect(response).to redirect_to(root_path)
        end

        it 'throws alert' do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#take_money' do
    context 'when anonymous user' do
      before { put :take_money, id: game_w_questions.id }

      it 'return redirect status' do
        expect(response.status).to eq(302)
      end

      it 'redirect to authorization' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'return flash alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when authorized users' do
      before do
        sign_in user
        game_w_questions.update(current_level: 2)
        put :take_money, id: game_w_questions.id
      end

      let(:game) { assigns(:game) }

      it 'finishes game' do
        expect(game).to be_finished
      end

      it 'assigns correct prize' do
        expect(game.prize).to eq 200
      end

      it 'correctly increments user balance' do
        expect { user.reload }.to change(user, :balance).by game.prize
      end

      it 'redirects to user path' do
        expect(response).to redirect_to(user_path(user))
      end

      it 'has flash warning' do
        expect(flash[:warning]).to be
      end
    end
  end

  describe '#create' do
    context 'anonymous user' do
      before { post :create }

      it 'returns redirect status' do
        expect(response.status).to eq(302)
      end

      it 'redirects to sign in page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'throws alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'authorized user' do
      before { sign_in user }

      let(:game) { assigns(:game) }

      context 'no games in progress' do
        before do
          generate_questions(15)
          post :create
        end

        it 'creates unfinished game' do
          expect(game).not_to be_finished
        end

        it 'correctly assigns game owner' do
          expect(game.user).to eq(user)
        end

        it 'returns redirect status' do
          expect(response.status).to eq(302)
        end

        it 'redirects to game page' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'shows notice' do
          expect(flash[:notice]).to be
        end
      end

      context 'game already exists' do
        before do
          sign_in game_w_questions.user
          post :create
        end

        it 'has game in progess' do
          expect(game_w_questions).not_to be_finished
        end

        it 'doesnt create game' do
          expect(game).to be_nil
        end

        it 'returns redirect status' do
          expect(response.status).to eq(302)
        end

        it 'redirects to game page' do
          expect(response).to redirect_to(game_path(game_w_questions))
        end

        it 'shows alert' do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#answer' do
    context 'anonymous user' do
      before do
        put(:answer,
            id: game_w_questions.id,
            letter: game_w_questions.current_game_question.correct_answer_key)
      end

      it 'returns redirect status' do
        expect(response.status).to eq(302)
      end

      it 'redirects to sign in page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'throws alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'authorized user' do
      before(:each) { sign_in user } # логиним юзера user с помощью спец. Devise метода sign_in
      let(:game) { assigns :game }
      context 'answers correctly' do
        before do
          put(:answer,
              id: game_w_questions.id,
              letter: game_w_questions.current_game_question.correct_answer_key)
        end

        it 'operates with game in progress' do
          expect(game).not_to be_finished
        end

        it 'correctly increments level' do
          expect(game.current_level).to be > 0
        end

        it 'redirects to game' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'doesnt throw any messages' do
          expect(flash.empty?).to be_truthy # удачный ответ не заполняет flash
        end
      end

      context 'answers incorrectly' do
        before do
          put(:answer,
              id: game_w_questions.id,
              letter: 'c')
        end

        it 'finishes game' do
          expect(game).to be_finished
        end

        it 'redirects to current user' do
          expect(response).to redirect_to(user_path(user))
        end

        it 'throws alert' do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#help' do
    context 'anonymous user' do
      before { put(:help, id: game_w_questions.id, help_type: :audience_help) }

      it 'returns redirect status' do
        expect(response.status).to eq(302)
      end

      it 'redirects to sign in page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'throws alert' do
        expect(flash[:alert]).to be
      end
    end
  end

  # группа тестов на экшены контроллера, доступных залогиненным юзерам
  context 'Usual user' do
    # перед каждым тестом в группе
    before(:each) { sign_in user } # логиним юзера user с помощью спец. Devise метода sign_in

    # тест на отработку "помощи зала"
    it 'uses audience help' do
      # сперва проверяем что в подсказках текущего вопроса пусто
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      expect(game_w_questions.audience_help_used).to be_falsey

      # фигачим запрос в контроллен с нужным типом
      put :help, id: game_w_questions.id, help_type: :audience_help
      game = assigns(:game)

      # проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be_falsey
      expect(game.audience_help_used).to be_truthy
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game))
    end
  end
end
