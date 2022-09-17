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
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  describe "#show" do
    context "when anonymous" do
      before { get :show, id: game_w_questions.id }

      it "status not 200" do
        expect(response.status).not_to eq(200)
      end

      it "redirect to login" do
        expect(response).to redirect_to(new_user_session_path)
      end

      it "shows alert message" do
        expect(flash[:alert]).to be
      end
    end

    context "when registered user" do
      before { sign_in user }

      context "and game owner" do
        before { get :show, id: game_w_questions.id }

        let(:game) { assigns(:game) }

        it "continues game" do
          expect(game.finished?).to be false
        end

        it "games user is user" do
          expect(game.user).to eq(user)
        end

        it "status 200" do
          expect(response.status).to eq(200)
        end

        it "renders show template" do
          expect(response).to render_template("show")
        end
      end

      context "and game not owner" do
        before do
          get :show, id: alien_game.id
        end

        let!(:alien_game) { FactoryBot.create(:game_with_questions) }

        it "status not 200" do
          expect(response.status).not_to eq(200)
        end

        it "redirect to root_path" do
          expect(response).to redirect_to(root_path)
        end

        it "show alert message" do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe "#create" do
    context "when anonymous" do
      before do
        generate_questions(15)
        post :create
      end

      let(:game) { assigns(:game) }

      it "game not exist" do
        expect(game).to be_nil
      end

      it "game doesn't created" do
        expect { post :create }.to change(Game, :count).by(0)
      end

      it "status not 200" do
        expect(response.status).not_to eq(200)
      end

      it "redirect to login" do
        expect(response).to redirect_to(new_user_session_path)
      end

      it "shows alert message" do
        expect(flash[:alert]).to be
      end
    end

    context "when registered user" do
      before do
        sign_in user
        generate_questions(15)
        post :create
      end

      let!(:created_game) { assigns(:game) }

      context "creates new game" do
        it "game exist" do
          expect(created_game.finished?).to be false
        end

        it "games user is user" do
          expect(created_game.user).to eq(user)
        end

        it "redirect to game" do
          expect(response).to redirect_to(game_path(created_game))
        end

        it "shows notics message" do
          expect(flash[:notice]).to be
        end
      end

      context "creates second game in the row" do
        before do
          generate_questions(15)
          post :create
        end

        it "continues first game" do
          expect(created_game.finished?).to be false
        end

        it "second game doesn't created" do
          expect { post :create }.to change(Game, :count).by(0)
        end

        it "redirect to first game" do
          expect(response).to redirect_to(game_path(created_game))
        end

        it "shows alert message" do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe "#answer" do
    let(:game) { assigns(:game) }

    context "when anonymous" do
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

    context "when registered user" do
      before { sign_in user }

      context "and answers correct" do
        before { put :answer,
                     id: game_w_questions.id,
                     letter: game_w_questions.current_game_question.correct_answer_key }

        it "continues game" do
          expect(game.finished?).to be false
        end

        it "level not 0" do
          expect(game.current_level).to be > 0
        end

        it "redirect to game" do
          expect(response).to redirect_to(game_path(game))
        end

        it "doesn't shows any messages" do
          expect(flash.empty?).to be true
        end
      end

      context "and answer wrong" do
        before do
          letter = %w[a b c d] - [game_w_questions.current_game_question.correct_answer_key]
          put :answer, id: game_w_questions.id, letter: letter
        end

        let(:answer_is_correct) { assigns(:answer_is_correct) }

        it "answer is wrong" do
          expect(answer_is_correct).to be false
        end

        it "game finished" do
          expect(game.finished?).to be true
        end

        it "game failed" do
          expect(game.status).to eq(:fail)
        end

        it "redirect to user profile" do
          expect(response).to redirect_to(user_path(user))
        end

        it "shows error message" do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe "#take_money" do
    let(:game) { assigns(:game) }

    context "when anonymous" do
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

    context "when registered user" do
      before do
        sign_in user
        game_w_questions.update_attribute(:current_level, 1)
        put :take_money, id: game_w_questions.id
        user.reload
      end

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

      it "shows warning message" do
        expect(flash[:warning]).to be
      end
    end
  end

  describe "#help" do
    let(:game) { assigns(:game) }

    context "when anonymous" do
      before {  put :help, id: game_w_questions.id }

      let(:game) { assigns(:game) }

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

    context "when registered user" do
      before { sign_in user }

      context "doesn't use any hint" do
        it "doesn't use audience help" do
          expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
        end
      end

      context "use audience help" do
        before { put :help, id: game_w_questions.id, help_type: :audience_help }

        it "continues game" do
          expect(game.finished?).to be false
        end

        it "uses hint" do
          expect(game.audience_help_used).to be true
        end

        it "hint exist in hash" do
          expect(game.current_game_question.help_hash[:audience_help]).to be
        end

        it "variants is right" do
          expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly("a", "b", "c", "d")
        end

        it "redirect to game" do
          expect(response).to redirect_to(game_path(game))
        end
      end
    end
  end
end
