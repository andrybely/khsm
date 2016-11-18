require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do

  # обычный пользователь
  let(:user) {FactoryGirl.create(:user)}
  # админ
  let(:admin) {FactoryGirl.create(:user, is_admin: true)}
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) {FactoryGirl.create(:game_with_questions, user: user)}

  context 'Anon' do
    it  'kick from #show' do
      get :show, id: game_w_questions.id

      expect(response.status).not_to eq 200
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it  'kick from #answer' do
      put :answer, id: game_w_questions.id, letter: 'a'

      expect(response.status).not_to eq 200
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it  'kick from #take_money' do
      put :take_money, id: game_w_questions.id

      expect(response.status).not_to eq 200
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it  'kick from #create' do
      post :create

      expect(response.status).not_to eq 200
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

  end

  # группа тестов для залогиненого пользователя
  context 'Usual user' do

    before(:each) do
      sign_in user
    end

  it 'creates game' do
    generate_questions(60)

    post :create

    game = assigns(:game)

    #проверка состояния игры
    expect(game.finished?).to be_falsey
    expect(game.user).to eq(user)

    expect(response).to redirect_to game_path(game)
    expect(flash[:notice]).to be
  end

    #юзер видит свою игру
    it '#show game' do
      get :show, id: game_w_questions.id
      game = assigns(:game) # берем из контроллера поле @game
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response.status).to eq(200) #должен возвращать HTTP 200
      expect(response).to render_template('show')
    end

    it 'answer correct' do
      put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key

      game = assigns(:game)

      #проверка состояния игры
      expect(game.finished?).to be_falsey
      expect(game.current_level).to be > 0
      expect(response).to redirect_to game_path(game)
      expect(flash.empty?).to be_truthy # удачный ответ не заполняет flash
    end

    # проверка, что пользовтеля посылают из чужой игры
    it '#show alien game' do
      # создаем новую игру
      alien_game = FactoryGirl.create(:game_with_questions)

      # пробуем зайти на эту игру текущий залогиненным user
      get :show, id: alien_game.id

      expect(response.status).not_to eq(200) # статус не 200
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be # во flash должна быть прописана ошибка
    end

    #Проверка, когда пользователь берет деньги до конца игры
    it 'takes money' do
      # вручную поднимем уровень вопроса до выигрыша 200
      game_w_questions.update_attribute(:current_level, 2)

      put :take_money, id: game_w_questions.id
      game = assigns(:game)
      expect(game.finished?).to be_truthy
      expect(game.prize).to eq(200)

      # пользователь изменился в базе, надо в коде перезагрузить!
      user.reload
      expect(user.balance).to eq(200)

      expect(response).to redirect_to(user_path(user))
      expect(flash[:warning]).to be
    end

    # Проверяем, что пользователь не может начать 2 игры одновременно
    it 'try to create second game' do
      # убедились что есть игра в работе
      expect(game_w_questions.finished?).to be_falsey

      # отправляем запрос на создание, убеждаемся что новых Game не создалось
      expect { post :create }.to change(Game, :count).by(0)

      game = assigns(:game) # вытаскиваем из контроллера поле @game
      expect(game).to be_nil

      # и редирект на страницу старой игры
      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be
    end

    #тест на неправильный ответ игрока
    it 'wrong answer' do
      answers = ['a', 'b', 'c', 'd']
      answers.delete(game_w_questions.current_game_question.correct_answer_key)
      answer = answers[rand(answers.size)]

      put :answer, id: game_w_questions.id, letter: answer

      game = assigns(:game)

      #проверка состояния игры
      expect(game.finished?).to be_truthy #игра окончена?
      expect(response).to redirect_to (user_path(user)) #проверка перенаправления
      expect(flash.empty?).to be_falsey # неверный ответ, flash должен быть заполнен
    end

    #тест на обработку "помощи зала"
    it 'uses audience help' do
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      expect(game_w_questions.audience_help_used).to be_falsey

      put :help, id: game_w_questions.id, help_type: :audience_help
      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.audience_help_used).to be_truthy
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game))
    end
  end
end
