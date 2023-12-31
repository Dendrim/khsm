require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }
  let(:stranger) { FactoryBot.create(:user) }
  let(:stranger_game_w_questions) { FactoryBot.create(:game_with_questions, user: stranger) }

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
      before do
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
        put(
          :answer,
          id: game_w_questions.id,
          letter: game_w_questions.current_game_question.correct_answer_key
        )
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
      before { sign_in user }
      let(:game) { assigns :game }
      context 'answers correctly' do
        before do
          put(
            :answer,
            id: game_w_questions.id,
            letter: game_w_questions.current_game_question.correct_answer_key
          )
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
          expect(flash.empty?).to be true
        end
      end

      context 'answers incorrectly' do
        before do
          put(
            :answer,
            id: game_w_questions.id,
            letter: 'c'
          )
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
    context 'anonimous user' do
      before { put :help, id: game_w_questions.id, help_type: :fifty_fifty }

      it 'return status is not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to authorization' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'it must be flash alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'authorized stranger user' do
      before do
        sign_in user

        put(
          :help,
          id: stranger_game_w_questions.id,
          help_type: :fifty_fifty
        )
      end

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

    context 'authorized owner user' do
      before { sign_in game_w_questions.user }
      let(:game) { assigns :game }

      context 'using 50/50' do
        context 'not used' do
          context 'before use' do
            it 'has no help used before' do
              expect(game_w_questions.fifty_fifty_used).to be false
            end

            it 'operates with unfinished game' do
              expect(game_w_questions).not_to be_finished
            end

            it 'has no 50/50 key' do
              expect(game_w_questions.current_game_question.help_hash).not_to have_key(:fifty_fifty)
            end
          end

          context 'after use' do
            before do
              put(
                :help,
                id: game_w_questions.id,
                help_type: :fifty_fifty
              )
            end

            it 'doesnt finish game' do
              expect(game).not_to be_finished
            end

            it 'marks help type as used' do
              expect(game.fifty_fifty_used).to be true
            end

            it 'fifty_fifty return 2 answers' do
              expect(game.current_game_question.help_hash[:fifty_fifty].size).to eq(2)
            end

            it 'fifty_fifty return an array' do
              expect(game.current_game_question.help_hash[:fifty_fifty]).to be_an(Array)
            end

            it 'contains answer key' do
              expect(game.current_game_question.help_hash[:fifty_fifty])
                .to include(game.current_game_question.correct_answer_key)
            end

            it 'redirects back to game' do
              expect(response).to redirect_to(game_path(game))
            end

            it 'throws flash message' do
              expect(flash[:info]).to be
            end
          end
        end

        context 'already used' do
          before do
            game_w_questions.update(fifty_fifty_used: true)
          end

          context 'before use' do
            it 'operates with unfinished game' do
              expect(game_w_questions).not_to be_finished
            end

            it 'help was used before' do
              expect(game_w_questions.fifty_fifty_used).to be true
            end
          end

          context 'after use' do
            before do
              put(
                :help,
                id: game_w_questions.id,
                help_type: :fifty_fifty
              )
            end

            it 'redirects back to game' do
              expect(response).to redirect_to(game_path(game))
            end

            it 'throws alert' do
              expect(flash[:alert]).to be
            end
          end
        end

        context 'finished game' do
          before do
            game_w_questions.update(finished_at: Time.now)

            put(
              :help,
              id: game_w_questions.id,
              help_type: :fifty_fifty
            )
          end

          it 'operates with finished game' do
            expect(game_w_questions).to be_finished
          end

          it 'redirects to user page' do
            expect(response).to redirect_to user_path(user)
          end

          it 'throws alert' do
            expect(flash[:alert]).to be
          end
        end
      end
    end
  end

  # группа тестов на экшены контроллера, доступных залогиненным юзерам
  context 'Usual user' do
    # перед каждым тестом в группе
    before { sign_in user } # логиним юзера user с помощью спец. Devise метода sign_in

    # тест на отработку "помощи зала"
    it 'uses audience help' do
      # сперва проверяем что в подсказках текущего вопроса пусто
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      expect(game_w_questions.audience_help_used).to be false

      # фигачим запрос в контроллен с нужным типом
      put :help, id: game_w_questions.id, help_type: :audience_help
      game = assigns(:game)

      # проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be false
      expect(game.audience_help_used).to be true
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game))
    end
  end
end
