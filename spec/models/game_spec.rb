require 'rails_helper'
require 'support/my_spec_helper'

describe Game, type: :model do
  let(:user) { FactoryBot.create(:user) }

  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  describe 'Game Factory' do
    it 'correctly creates new game' do
      generate_questions(60)

      game = nil
      expect { game = Game.create_game_for_user!(user) }
        .to change(Game, :count).by(1).and(change(GameQuestion, :count).by(15))

      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  context 'game mechanics' do
    describe '#current_game_question' do
      it 'correctly returns current question' do
        expect(game_w_questions.current_game_question).to(
          eq(game_w_questions.game_questions.includes(:question).order('questions.level')[0])
        )
      end
    end

    describe '#previous_level' do
      it 'returns correct level' do
        expect(game_w_questions.previous_level).to eq(-1)
      end
    end

    describe '#status' do
      before do
        game_w_questions.update(finished_at: Time.now)
      end

      context 'user won' do
        before { game_w_questions.update(current_level: Question::QUESTION_LEVELS.max + 1) }

        it 'correctly returns status' do
          expect(game_w_questions.status).to eq(:won)
        end
      end

      context 'user failed' do
        before { game_w_questions.update(is_failed: true) }

        it 'correctly returns status' do
          expect(game_w_questions.status).to eq(:fail)
        end
      end

      context 'user timed out' do
        before do
          game_w_questions.update(created_at: Time.now - Game::TIME_LIMIT - 1.minutes)
          game_w_questions.is_failed = true
        end

        it 'correctly returns status' do
          expect(game_w_questions.status).to eq(:timeout)
        end
      end

      context 'user desided to take money' do
        it 'correctly returns status' do
          expect(game_w_questions.status).to eq(:money)
        end
      end
    end

    describe '#answer_current_question!' do
      let!(:answer_key) { game_w_questions.current_game_question.correct_answer_key }

      context 'correct answer' do
        before { game_w_questions.answer_current_question!(answer_key) }

        it 'correctly increments level' do
          expect(game_w_questions.current_level).to eq(1)
        end

        it 'correctly shows new status' do
          expect(game_w_questions.status).to eq(:in_progress)
        end

        it 'doesnt finish game' do
          expect(game_w_questions).not_to be_finished
        end
      end

      context 'last answer' do
        before do
          game_w_questions.update(current_level: Question::QUESTION_LEVELS.last)
          game_w_questions.answer_current_question!(answer_key)
        end

        it 'correctly increments level' do
          expect(game_w_questions.current_level).to eq(Question::QUESTION_LEVELS.last + 1)
        end

        it 'wins the game with correct status' do
          expect(game_w_questions.status).to eq(:won)
        end

        it 'finishes the game' do
          expect(game_w_questions).to be_finished
        end
      end

      context 'answered after time limit' do
        before do
          game_w_questions.update(created_at: Time.now - Game::TIME_LIMIT - 1.minutes)
          game_w_questions.answer_current_question!(answer_key)
        end

        it 'ends game with timeout' do
          expect(game_w_questions.status).to eq(:timeout)
        end

        it 'finishes the game' do
          expect(game_w_questions).to be_finished
        end

        it 'fails the game with correct status' do
          expect(game_w_questions.is_failed).to be true
        end
      end

      context 'wrong answer' do
        before { game_w_questions.answer_current_question!('c') }

        it 'loses the game with correct status' do
          expect(game_w_questions.status).to eq(:fail)
        end

        it 'finishes the game' do
          expect(game_w_questions).to be_finished
        end

        it 'fails the game' do
          expect(game_w_questions.is_failed).to be true
        end
      end
    end

    describe "#take_money!" do
      before do
        game_w_questions.answer_current_question!(game_w_questions.current_game_question.correct_answer_key)
        game_w_questions.take_money!
      end

      let(:prize) { game_w_questions.prize }

      it 'correctly sets prize' do
        expect(prize).to eq(100)
      end

      it 'correctly finishes game' do
        expect(game_w_questions).to be_finished
      end

      it 'correctly sets status' do
        expect(game_w_questions.status).to eq :money
      end

      it 'correctly changes user balance' do
        expect(user.balance).to eq prize
      end
    end
  end
end
