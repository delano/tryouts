; https://tree-sitter.github.io/tree-sitter/syntax-highlighting#highlights

;; Highlight description lines (lines starting with '##') as comments
(description_line) @comment

;; Highlight code lines as functions (or use @function.call if you prefer)
(code_line) @function

;; Highlight expectation lines (lines starting with '#=>') as strings
(expectation_line) @string

;; Optionally, highlight setup and teardown sections differently if needed
(setup_section) @preproc
(teardown_section) @preproc
