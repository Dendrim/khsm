module MySpecHelper
  # наш хелпер, для населения базы нужным количеством рандомных вопросов
  def generate_questions(number)
    number.times do
      FactoryBot.create(:question)
    end
  end
end

RSpec.configure do |c|
  c.include MySpecHelper
end

# rvm\ebenv не дает скачивать старые версии руби
# на версии из бандла, которая уже не поддерживается ломаются тесты контроллеров
# исправляем таким вот образом
if RUBY_VERSION >= '2.6.0'
  if Rails.version < '5'
    class ActionController::TestResponse < ActionDispatch::TestResponse
      def recycle!
        # hack to avoid MonitorMixin double-initialize error:
        @mon_mutex_owner_object_id = nil
        @mon_mutex = nil
        initialize
      end
    end
  else
    puts "Monkeypatch for ActionController::TestResponse no longer needed"
  end
end
