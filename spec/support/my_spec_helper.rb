module MySpecHelper

  #хэлпер для создания в базе нужного количества рандомных вопросов
  def generate_questions(number)
    number.times do
      FactoryGirl.create(:question)
    end
  end
end

RSpec.configure do |c|
  c.include MySpecHelper
end