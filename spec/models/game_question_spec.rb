require 'rails_helper'

describe GameQuestion, type: :model do
  let(:game_question) { FactoryBot.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  describe '#answer_correct?' do
    it 'correctly detects if answer is right' do
      expect(game_question.answer_correct?('b')).to be true
    end
  end

  describe '#variants' do
    it 'returns correct hash' do
      expect(game_question.variants).to eq({
                                             'a' => game_question.question.answer2,
                                             'b' => game_question.question.answer1,
                                             'c' => game_question.question.answer4,
                                             'd' => game_question.question.answer3
                                           })
    end
  end

  describe '#correct_answer_key' do
    it 'returns correct answer key' do
      expect(game_question.correct_answer_key).to eq('b')
    end
  end

  describe '#help_hash' do
    let!(:game_q_before_save) { game_question }

    context 'fresh question' do
      it 'starts with empty hash' do
        expect(game_q_before_save.help_hash).to eq({})
      end
    end

    context 'modified hash' do
      before do
        game_question.help_hash[:some_key1] = 'blabla1'
        game_question.help_hash['some_key2'] = 'blabla2'
      end

      it 'saves new keys normally' do
        expect(game_question.save).to be true
      end

      it 'correctly returns new hash' do
        game_question.save
        expect(game_question.help_hash).to eq({ :some_key1 => 'blabla1', 'some_key2' => 'blabla2' })
      end
    end
  end

  describe '#add_fifty_fifty' do
    context 'before using 50/50' do
      it 'has no 50/50 key' do
        expect(game_question.help_hash).not_to have_key(:fifty_fifty)
      end
    end

    context 'after using 50/50' do
      before { game_question.add_fifty_fifty }

      it 'has 50/50 key' do
        expect(game_question.help_hash).to have_key(:fifty_fifty)
      end

      it 'includes correct answer key' do
        expect(game_question.help_hash[:fifty_fifty]).to include(game_question.correct_answer_key)
      end

      it 'contains 2 keys' do
        expect(game_question.help_hash[:fifty_fifty].size).to eq 2
      end
    end
  end

  describe '#add_friend_call' do
    context 'before call' do
      it 'help_hash includes friend_call' do
        expect(game_question.help_hash).not_to have_key(:friend_call)
      end
    end

    context 'after call' do
      before do
        game_question.add_friend_call
      end
      let(:suggested_key) { call.last.downcase }
      let(:call) { game_question.help_hash[:friend_call] }

      it 'help_hash includes friend_call' do
        expect(game_question.help_hash).to have_key(:friend_call)
      end

      it 'returns string' do
        expect(call).to be_a(String)
      end

      it 'contains friend answer' do
        expect(call).to include('считает, что это вариант')
      end

      it 'contains answer key' do
        expect(game_question.variants.keys).to include suggested_key
      end
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
