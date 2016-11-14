# Игровой вопрос — при создании новой игры формируется массив
# из 15 игровых вопросов для конкретной игры и игрока.
class GameQuestion < ActiveRecord::Base

  belongs_to :game

  # вопрос из которого берется вся информация
  belongs_to :question

  # создаем в этой модели виртуальные геттеры text, level, значения которых
  # автоматически берутся из связанной модели question
  delegate :text, :level, to: :question, allow_nil: true

  # без игры и вопроса - игровой вопрос не имеет смысла
  validates :game, :question, presence: true

  # в полях a,b,c,d прячутся индексы ответов из объекта :game
  validates :a, :b, :c, :d, inclusion: {in: 1..4}

  # Автоматическая сериализация поля в базу (мы юзаем как обычный хэш,
  # а рельсы в базе хранят как строчку)
  # см. ссылки в материалах урока
  serialize :help_hash, Hash

  # help_hash имеет такой формат:
  # {
  #   fifty_fifty: ['a', 'b'], # При использовании подсказски остались варианты a и b
  #   audience_help: {'a' => 42, 'c' => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #   friend_call: 'Василий Петрович считает, что правильный ответ A'
  # }
  #

  # ----- Основные методы для доступа к данным в шаблонах и контроллерах -----------

  # Возвращает хэш, отсортированный по ключам:
  # {'a' => 'Текст ответа Х', 'b' => 'Текст ответа У', ... }
  def variants
    {
      'a' => question.read_attribute("answer#{a}"),
      'b' => question.read_attribute("answer#{b}"),
      'c' => question.read_attribute("answer#{c}"),
      'd' => question.read_attribute("answer#{d}")
    }
  end

  # Возвращает истину, если переданная буква (строка или символ) содержит верный ответ
  def answer_correct?(letter)
    correct_answer_key == letter.to_s.downcase
  end

  # ключ правильного ответа 'a', 'b', 'c', или 'd'
  def correct_answer_key
    {a => 'a', b => 'b', c => 'c', d => 'd'}[1]
  end

  # текст правильного ответа
  def correct_answer
    variants[correct_answer_key]
  end

  def add_audience_help
    self.help_hash[:audience_help] = {
      'a' => rand(100),
      'b' => rand(100),
      'c' => rand(100),
      'd' => rand(100)
    }
    save
  end

end
