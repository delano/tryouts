# rspec_class_based_syntax.rb

class RSFCDemoSpec < RSpec::Core::ExampleGroup
  include RSpec::Matchers

  # `before` runs before each example (test), similar to Minitest's `setup`
  before(:each) do
    @array = [1, 2, 3]
    @hash = { name: 'Ruby', type: 'Language' }
    @value = 42
    @string = 'Hello, RSpec!'
  end

  # `after` runs after each example (test), similar to Minitest's `teardown`
  after(:each) do
    # Clean up resources if needed
    @array = nil
    @hash = nil
  end

  # Basic assertions are called "expectations" in RSpec
  it 'handles basic expectations' do
    expect(true).to be(true)
    expect(@value).to eq(41) # This will fail, like in the Minitest example
    expect(nil).to be_nil
    expect(false).not_to be(true)
    expect(@value).not_to eq(43)
  end

  # ... other tests ...

  # You can also define helper methods within the class
  def custom_helper
    'I am a helper'
  end

  it 'can use helper methods' do
    expect(custom_helper).to eq('I am a helper')
  end
end
