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
  end
end
