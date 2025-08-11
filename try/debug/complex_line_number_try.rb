# try/debug/complex_line_number_try.rb
# Complex test with heredocs and varied comment patterns to trigger line number issues

# Large setup block with heredocs and complex patterns
puts "Setup starting"

# Heredoc in setup - this might confuse the enhanced parser
sql_query = <<~SQL
  SELECT users.name,
         users.email,
         COUNT(orders.id) as order_count
  FROM users
  LEFT JOIN orders ON users.id = orders.user_id
  WHERE users.created_at > '2023-01-01'
  GROUP BY users.id, users.name, users.email
  ORDER BY order_count DESC
SQL

# Another heredoc
name = "Customer"
template = <<~TEMPLATE
  Hello #{name},

  Your order has been processed.

  # This comment inside heredoc should not be parsed as expectation
  #=> This should be ignored too

  Thank you for your business!
TEMPLATE

# More setup code after heredocs
config = {
  database: 'test_db',
  host: 'localhost',
  port: 5432
}

# Comments in setup
# This is a regular comment
## This looks like a test description but it's in setup

# Final setup variables
x = 42
y = "test string"
z = [1, 2, 3, 4, 5]

puts "Setup complete with heredocs"

## TEST: First test after complex setup - line number should be accurate
result = x + 10
#=> 52

## TEST: Test with inline comment after heredoc parsing
"hello world" # This is an inline comment with #=> fake expectation
#=> "hello world"

## TEST: Multiple line test with complex patterns
data = {
  # Internal comment that might confuse parser
  users: [
    { name: "John", age: 30 },
    { name: "Jane", age: 25 }
  ],
  # Another internal comment
  settings: { theme: "dark" }
}
#=> { users: [{ name: "John", age: 30 }, { name: "Jane", age: 25 }], settings: { theme: "dark" } }

## TEST: Heredoc in test case
output = <<~HTML
  <div class="user">
    <h1>User Profile</h1>
    <!-- HTML comment -->
    # This Ruby comment in heredoc should be ignored
    #=> This expectation-like comment should also be ignored
  </div>
HTML
#=> output.include?("User Profile")

## TEST: Exception test after complex patterns
1 / 0
#=!> error.is_a?(ZeroDivisionError)

## TEST: Final test to check offset consistency
[1, 2, 3].length
#=> 3

# Teardown with complex patterns
puts "Starting teardown"

# Teardown heredoc
cleanup_sql = <<~SQL
  DELETE FROM test_users WHERE created_at < NOW() - INTERVAL '1 day';
  # This SQL comment should not affect line numbers
  -- This SQL comment either
SQL

puts "Complex teardown complete"
