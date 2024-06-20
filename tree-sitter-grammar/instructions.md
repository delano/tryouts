

Draft a tree-sitter grammar for the selected code, where:

1. A new line followed by one or more lines starting with `##` is the title of the test.
2. The trailing lines beginning with `#=>` are the test expectations. Expectations are valid ruby expressions.
3. All of the code in between is valid Ruby.


### Tryout Definitions

#### 1. Example with multiple expectations

```ruby
## TEST 2: comments, tests, and expectations can
## contain multiple lines
a = 1
b = 2
a + b
#=> 3
#=> 2 + 1
```
