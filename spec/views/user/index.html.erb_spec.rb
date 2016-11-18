require 'rails_helper'

RSpec.describe 'users/index', type: :view do
  before(:each) do
    assign(:users, [
      FactoryGirl.build_stubbed(:user, name: 'Vadik', balance: 5000),
      FactoryGirl.build_stubbed(:user, name: 'Andry', balance: 3000),
    ])

    render
  end

  it 'renders player names' do
    expect(rendered).to match 'Vadik'
    expect(rendered).to match 'Andry'
  end

  it 'renders players balances' do
    expect(rendered).to match '5 000 ₽'
    expect(rendered).to match '3 000 ₽'
  end

  it 'renders player names in right order' do
    expect(rendered).to match /Vadik.*Andry/m
  end
end