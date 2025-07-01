# Generated rspec code for try/step1_try.rb
# Generated RSpec test from try/step1_try.rb
# Generated at: 2025-07-01 14:53:35 -0700

RSpec.describe 'step1_try' do
  it 'test expectation type matters' do
    result = 'foo'.class

    expect(result).to eq(String)
  end

  it 'instance variables can be used in expectations' do
    result = @a = 1

    expect(result).to eq(@a)
  end

  it 'test ignores blank lines before expectations' do
    result = @a += 1

    expect(result).to eq('foo')
  end
end
