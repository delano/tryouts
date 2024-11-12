module Tryouts
  module Queries
    # Environment Setup Query
    ENVIRONMENT = <<~QUERY
      (source_file
        (metadata_declaration
          type: (_)  @config.type
          value: (_) @config.value) @config

        (setup_section) @setup)
    QUERY

    # Test Structure Query
    STRUCTURE = <<~QUERY
      (test_case
        (description
          text: (_) @test.desc.text) @test.desc

        code_block: (code_block) @test.code

        [(expectation) @test.expect
         (expected_failure) @test.expect.fail]) @test
    QUERY

    # Expectation Details Query
    EXPECTATIONS = <<~QUERY
      (expectation
        value: (_) @expect.value) @expect

      (expected_failure
        error_type: (_) @error.type
        message: (_)? @error.message) @error
    QUERY

    # Variable Tracking Query
    VARIABLES = <<~QUERY
      (instance_var_declaration
        (identifier) @var.name) @var.decl

      (instance_var_reference
        (identifier) @var.name) @var.ref
    QUERY

    # Code Analysis Query - Known Working
    CODE = <<~QUERY
      (code_block
        (code_line) @code.line
        (comment)? @code.comment) @code.block

      (code_line) @code.statement
    QUERY
  end
end
