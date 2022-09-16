# (c) goodprogrammer.ru

require "rails_helper"
require "support/my_spec_helper" # наш собственный класс с вспомогательными методами

# Тестовый сценарий для игрового контроллера
# Самые важные здесь тесты:
#   1. на авторизацию (чтобы к чужим юзерам не утекли не их данные)
#   2. на четкое выполнение самых важных сценариев (требований) приложения
#   3. на передачу граничных/неправильных данных в попытке сломать контроллер
#
RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { FactoryBot.create(:user) }
  # админ
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # группа тестов для незалогиненного юзера (Анонимус)
  context "Anon" do
    let(:game) { assigns(:game) }
    # из экшена show анона посылаем
    it "kick from #show" do
      # вызываем экшен
      get :show, id: game_w_questions.id
      # проверяем ответ
      expect(response.status).not_to eq(200) # статус не 200 ОК
      expect(response).to redirect_to(new_user_session_path) # devise должен отправить на логин
      expect(flash[:alert]).to be # во flash должен быть прописана ошибка
    end

    context "when try create new game" do
      before do
        generate_questions(15)
        post :create
      end

      it "instance variable game is nil" do
        expect(game).to be_nil
      end

      it "game doesn't created" do
        expect { post :create }.to change(Game, :count).by(0)
      end

      it "return not 200 status" do
        expect(response.status).not_to eq(200)
      end

      it "redirect to sign_in page" do
        expect(response).to redirect_to(new_user_session_path)
      end

      it "adds alert message in flash" do
        expect(flash[:alert]).to be
      end
    end

    context "when try answer to question" do
      before {  put :answer, id: game_w_questions.id }

      it "instance variable game is nil" do
        expect(game).to be_nil
      end

      it "return not 200 status" do
        expect(response.status).not_to eq(200)
      end

      it "redirect to sign_in page" do
        expect(response).to redirect_to(new_user_session_path)
      end

      it "adds alert message in flash" do
        expect(flash[:alert]).to be
      end
    end

    context "when try take money" do
      before {  put :take_money, id: game_w_questions.id }

      it "instance variable game is nil" do
        expect(game).to be_nil
      end

      it "return not 200 status" do
        expect(response.status).not_to eq(200)
      end

      it "redirect to sign_in page" do
        expect(response).to redirect_to(new_user_session_path)
      end

      it "adds alert message in flash" do
        expect(flash[:alert]).to be
      end
    end

    context "when try use hint" do
      before {  put :help, id: game_w_questions.id }

      it "instance variable game is nil" do
        expect(game).to be_nil
      end

      it "return not 200 status" do
        expect(response.status).not_to eq(200)
      end

      it "redirect to sign_in page" do
        expect(response).to redirect_to(new_user_session_path)
      end

      it "adds alert message in flash" do
        expect(flash[:alert]).to be
      end
    end
  end

  # группа тестов на экшены контроллера, доступных залогиненным юзерам
  context "Usual user" do
    # перед каждым тестом в группе
    before(:each) { sign_in user } # логиним юзера user с помощью спец. Devise метода sign_in

    # юзер может создать новую игру
    it "creates game" do
      # сперва накидаем вопросов, из чего собирать новую игру
      generate_questions(15)

      post :create
      game = assigns(:game) # вытаскиваем из контроллера поле @game

      # проверяем состояние этой игры
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)
      # и редирект на страницу этой игры
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to be
    end

    # юзер видит свою игру
    it "#show game" do
      get :show, id: game_w_questions.id
      game = assigns(:game) # вытаскиваем из контроллера поле @game
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response.status).to eq(200) # должен быть ответ HTTP 200
      expect(response).to render_template("show") # и отрендерить шаблон show
    end

    # юзер отвечает на игру корректно - игра продолжается
    it "answers correct" do
      # передаем параметр params[:letter]
      put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.current_level).to be > 0
      expect(response).to redirect_to(game_path(game))
      expect(flash.empty?).to be_truthy # удачный ответ не заполняет flash
    end

    context "answer wrong" do
      before do
        letter = %w[a b c d] - [game_w_questions.current_game_question.correct_answer_key]
        put :answer, id: game_w_questions.id, letter: letter
      end

      let(:game) { assigns(:game) }
      let(:level) { game.current_level }

      it "game is finished" do
        expect(game.finished?).to be true
      end

      it "game status is fail" do
        expect(game.status).to eq(:fail)
      end

      it "game doesn't progress to the next level" do
        expect(game.current_level).not_to eq(level + 1)
      end

      it "redirect to user profile" do
        expect(response).to redirect_to(user_path(user))
      end

      it "error message appeared in flash" do
        expect(flash[:alert]).to be
      end
    end

    # тест на отработку "помощи зала"
    it "uses audience help" do
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
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly("a", "b", "c", "d")
      expect(response).to redirect_to(game_path(game))
    end

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
  end

  describe "#show" do
    before do
      sign_in user
      get :show, id: alien_game.id
    end

    context "when user check alien game" do
      let!(:alien_game) { FactoryBot.create(:game_with_questions) }

      it "response return status not 200" do
        expect(response.status).not_to eq(200)
      end

      it "redirect to root_path" do
        expect(response).to redirect_to(root_path)
      end

      it "error message will appear in flash" do
        expect(flash[:alert]).to be
      end
    end
  end

  describe "#take_money" do
    before do
      sign_in user
      game_w_questions.update_attribute(:current_level, 1)
      put :take_money, id: game_w_questions.id
      user.reload
    end

    context "when user takes money" do
      let!(:game) { assigns(:game) }

      it "finishes game" do
        expect(game.finished?).to be true
      end

      it "assigns prize" do
        expect(game.prize).to eq(100)
      end

      it "updates user balance" do
        expect(user.balance).to eq(100)
      end

      it "redirects to user profile" do
        expect(response).to redirect_to(user_path(user))
      end

      it "adds message in flash" do
        expect(flash[:warning]).to be
      end
    end
  end
end
