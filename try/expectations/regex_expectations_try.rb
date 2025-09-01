# try/expectations/regex_expectations_try.rb

## TEST: Simple regex pattern match
"hello world"
#=~> /hello/

## TEST: Email pattern match
"user@example.com"
#=~> /\A[^@]+@[^@]+\.[^@]+\z/

## TEST: Number pattern in string
"Phone: 555-1234"
#=~> /\d{3}-\d{4}/

## TEST: Should fail with non-matching pattern
"hello world"
#=~> /goodbye/

## TEST: Case insensitive match
"HELLO WORLD"
#=~> /hello/i
