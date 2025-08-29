# Simple agent mode functionality test

require_relative '../../lib/tryouts/cli/formatters/agent'
require_relative '../../lib/tryouts/cli/formatters/token_budget'

## Test TokenBudget initialization
@budget = Tryouts::CLI::TokenBudget.new(100)
@budget.limit
#=> 100

@budget.used
#=> 0

## Test token estimation
@budget.estimate_tokens("hello")
#=> 2

## Test consumption
@budget.consume("hi")
#=> true

@budget.used > 0
#=> true

## Test AgentFormatter initialization
@formatter = Tryouts::CLI::AgentFormatter.new
@formatter.class.name
#=> "Tryouts::CLI::AgentFormatter"

## Test AgentFormatter options
@opts_formatter = Tryouts::CLI::AgentFormatter.new({
  agent_limit: 2000,
  agent_focus: :summary
})
@opts_formatter.class
#=> Tryouts::CLI::AgentFormatter

## Test no colors in agent mode
@formatter.instance_variable_get(:@use_colors)
#=> false

puts "Simple agent tests completed successfully"
