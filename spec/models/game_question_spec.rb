# (c) goodprogrammer.ru

require "rails_helper"

# Тестовый сценарий для модели игрового вопроса,
RSpec.describe GameQuestion, type: :model do
  let(:game_question) { FactoryBot.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  # группа тестов на игровое состояние объекта вопроса

  describe "#variants" do
    it "return correct hash" do
      expect(game_question.variants).to eq({"a" => game_question.question.answer2,
                                            "b" => game_question.question.answer1,
                                            "c" => game_question.question.answer4,
                                            "d" => game_question.question.answer3})
    end
  end

  describe "#answer_correct?" do
    context "when answer correct" do
      it "return true" do
        expect(game_question.answer_correct?("b")).to be true
      end
    end
  end

  describe "#text" do
    it "delegates correctly" do
      expect(game_question.text).to eq(game_question.question.text)
    end
  end

  describe "#level" do
    it "delegates correctly" do
      expect(game_question.level).to eq(game_question.question.level)
    end
  end

  describe "#correct_answer_key" do
    it "return right answers key" do
      expect(game_question.correct_answer_key).to eq("b")
    end
  end

  describe "#help_hash" do
    context "when game question creates" do
      it "help hash is empty" do
        expect(game_question.help_hash).to eq({})
      end
    end

    context "when adds keys in help hash" do
      before do
        game_question.help_hash[:some_key1] = "blabla1"
        game_question.help_hash[:some_key2] = "blabla2"
      end

      it "game question saved" do
        expect(game_question.save).to be true
      end

      it "help hash have keys" do
        expect(game_question.help_hash).to eq({ some_key1: "blabla1", some_key2: "blabla2" })
      end
    end
  end

  # help_hash у нас имеет такой формат:
  # {
  #   fifty_fifty: ["a", "b"], # При использовании подсказски остались варианты a и b
  #   audience_help: {"a" => 42, "c" => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #   friend_call: "Василий Петрович считает, что правильный ответ A"
  # }
  #

  describe "#add_audience_help" do
    context "when game question creates" do
      it "help hash do not include :audience_help" do
        expect(game_question.help_hash).not_to include(:audience_help)
      end
    end

    context "when uses audience help" do
      before { game_question.add_audience_help }

      let(:ah) { game_question.help_hash[:audience_help] }

      it "help hash include :audience_help" do
        expect(game_question.help_hash).to include(:audience_help)
      end

      it "audience variants is correct" do
        expect(ah.keys).to contain_exactly("a", "b", "c", "d")
      end
    end
  end

  describe "#add_fifty_fifty" do
    context "when game question creates" do
      it "help hash do not include fifty_fifty" do
        expect(game_question.help_hash).not_to include(:fifty_fifty)
      end
    end

    context "when uses fifty_fifty" do
      before { game_question.add_fifty_fifty }

      let(:ff) { game_question.help_hash[:fifty_fifty] }

      it "help hash include fifty_fifty" do
        expect(game_question.help_hash).to include(:fifty_fifty)
      end

      it "correct variant still included" do
        expect(ff).to include('b')
      end

      it "remained two variants" do
        expect(ff.size).to eq 2
      end
    end
  end

  describe "#add_friend_call" do
    context "when game question creates" do
      it "help hash do not include friend_call" do
        expect(game_question.help_hash).not_to include(:friend_call)
      end
    end

    context "when uses friend_call" do
      before { game_question.add_friend_call }

      let(:fc) { game_question.help_hash[:friend_call] }

      it "help hash include fifty_fifty" do
        expect(game_question.help_hash).to include(:friend_call)
      end

      it "return string" do
        expect(fc).to be_instance_of String
      end

      it "one of variants included" do
        expect(fc).to match /[A-D]/
      end
    end
  end
end
