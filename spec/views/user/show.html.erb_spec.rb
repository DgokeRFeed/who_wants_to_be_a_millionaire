require "rails_helper"

RSpec.describe "users/show", type: :view do
  context "shows common elements" do
    before do
      assign(:user, FactoryBot.build_stubbed(:user, name: "Володя"))
      assign(:games, stub_template("users/_game.html.erb" => "It is games statistic, true story"))
      render
    end

    it "renders user name" do
      expect(rendered).to match "Володя"
    end

    it "renders game statistic" do
      expect(rendered).to match "It is games statistic, true story"
    end
  end

  context "when anonymous views profile" do
    before do
      assign(:user, FactoryBot.build_stubbed(:user, name: "Володя"))
      render
    end

    it "not renders update link" do
      expect(rendered).not_to match "Сменить имя и пароль"
    end
  end

  context "when registered user" do
    context "views owned profile" do
      before do
        user = FactoryBot.create(:user)
        sign_in user
        assign(:user, user)
        render
      end

      it "renders update link" do
        expect(rendered).to match "Сменить имя и пароль"
      end
    end

    context "views not owned profile" do
      before do
        user = FactoryBot.create(:user)
        sign_in user
        assign(:user, FactoryBot.build_stubbed(:user, name: "Володя"))
        render
      end

      it "not renders update link" do
        expect(rendered).not_to match "Сменить имя и пароль"
      end
    end
  end
end
