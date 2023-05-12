# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса,
# в идеале весь наш функционал (все методы) должны быть протестированы.
describe GameQuestion, type: :model do #
  let(:game_question) { FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  describe '.answer_correct?' do
    it 'correctly detects if answer is right ' do
      game_question = FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3)
      expect(game_question.answer_correct?('b')).to be_truthy
    end
  end

  describe '.variant' do
    it 'returns correct hash' do
      expect(game_question.variants).to eq({
                                             'a' => game_question.question.answer2,
                                             'b' => game_question.question.answer1,
                                             'c' => game_question.question.answer4,
                                             'd' => game_question.question.answer3
                                           })
    end
  end

  describe '.correct_answer_key' do
    it 'returns correct key' do
      expect(game_question.correct_answer_key).to eq('b')
    end
  end

  describe 'delegations' do
    it 'correcty delegates .text ' do
      expect(game_question.text).to eq(game_question.question.text)
    end

    it 'correcty delegates .level ' do
      expect(game_question.level).to eq(game_question.question.level)
    end
  end

end
