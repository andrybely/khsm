require 'rails_helper'

RSpec.describe 'users/_game', type: :view do
  let(:game) do
    FactoryGirl.build_stubbed(
                 :game, id: 15, created_at: Time.parse('2016.10.09, 13:00'), current_level: 10, prize: 1000
    )
  end

  before(:each) do
    allow(game).to receive(:status).and_return(:in_progress)

    render partial: 'users/game', object: game
  end

  it 'renders game id' do
    expect(rendered).to match '15'
  end

  it 'renders game start time' do
    expect(rendered).to match '09 окт., 13:00'
  end

  it 'renders game current question' do
    expect(rendered).to match '10'
  end

  it 'renders game status' do
    expect(rendered).to match 'в процессе'
  end

  it 'renders game prize' do
    expect(rendered).to match '1 000 ₽'
  end
end