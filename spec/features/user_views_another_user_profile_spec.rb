require "rails_helper"

RSpec.feature "USER views another users profile", type: :feature do
  let(:user) { FactoryBot.create :user, id: 69, name: "Володя" }
  let(:current_user) { FactoryBot.create :user }
  let!(:game_1) do
    FactoryBot.create(:game,
                      user: user,
                      id: 15,
                      created_at: Time.parse("2021.11.25, 13:37"),
                      current_level: 10,
                      prize: 1000
    )
  end 
  let!(:game_2) do
    FactoryBot.create(:game,
                      user: user,
                      id: 16,
                      created_at: Time.parse("2021.11.25, 18:25"),
                      current_level: 7,
                      prize: 10000
    )
  end

  before do
    login_as current_user
  end

  scenario "successfully" do
    visit "/"

    click_link "Володя"

    expect(page).to have_current_path "/users/69"

    expect(page).to have_content "Володя"
    expect(page).not_to have_content "Сменить имя и пароль"

    expect(page).to have_content "15"
    expect(page).to have_content "16"

    expect(page).to have_content "в процессе"

    expect(page).to have_content "25 нояб., 13:37"
    expect(page).to have_content "25 нояб., 18:25"

    expect(page).to have_content "10"
    expect(page).to have_content "7"

    expect(page).to have_content "1 000 ₽"
    expect(page).to have_content "10 000 ₽"
  end
end
