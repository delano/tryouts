# Generated rspec code for try/step2_try.rb
# Generated RSpec test from try/step2_try.rb
# Generated at: 2025-07-01 14:53:41 -0700

RSpec.describe 'step2_try' do
  before(:all) do
    puts 'if you can see this, step2 setup succeeded'
    def example_of_an_inline_test_helper_method
      'I am helping'
    end
  end

  it 'some addition' do
    result = begin
      # => 4

      # multiple expectations

      # test ignores comments before expectations
      # ignored comment
      # ignored comment
    end
    expect(result).to eq('foobar')
    expect(result).to eq(:foobar.to_s)
    expect(result).to eq('foo')
  end

  it 'test uses a helper method defined at the top of this file.' do
    result = example_of_an_inline_test_helper_method

    expect(result).to eq('I am helping')
  end

  it 'Example of handling exceptions' do
    result = begin
        raise 'foo'
    rescue StandardError => ex
        [ex.class, 'foo']
    end

    expect(result).to eq([RuntimeError, 'foo'])
  end

  it 'line is treated as an expectation.' do
    result = begin
      phrase_template = '%s %d %s'
      # inline comment
      format(phrase_template, 'foo', 1, 'bar')

      # another comment
    end
    expect(result).to eq('foo 1 bar')
  end
end
