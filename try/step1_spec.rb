# Generated rspec code for try/step1_try.rb
# Generated RSpec test from try/step1_try.rb
# Generated at: 2025-07-01 15:27:13 -0700

RSpec.describe 'step1_try' do
  before(:all) do
    puts 'If you see this the setup ran correctly.'
    1
  end

  it 'test matches result with expectation' do
    result = begin
      2
    end
    expect(result).to eq(2)
  end

  it 'contain multiple lines' do
    result = begin
      3
    end
    expect(result).to eq(3)
    expect(result).to eq(2 + 1)
  end

  it 'test expectation type matters' do
    result = begin
      'foo'.class
    end
    expect(result).to eq(String)
  end

  it 'instance variables can be used in expectations' do
    result = begin
      @a = 1
    end
    expect(result).to eq(@a)
  end

  it 'test ignores blank lines before expectations' do
    result = begin
      @a += 1

    end
    expect(result).to eq('foo')
  end

  it 'test allows whiny expectation markers for textmate users *sigh*' do
    result = begin
      'foo'
    end
    expect(result).to eq('foo')
  end

  after(:all) do
    x = begin
      raise
    rescue StandardError
      'if you can see this, teardown succeeded'
    end
    puts x
  end
end
