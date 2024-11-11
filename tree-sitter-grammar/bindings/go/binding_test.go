package tree_sitter_grammar_test

import (
	"testing"

	tree_sitter "github.com/smacker/go-tree-sitter"
	"github.com/tree-sitter/tree-sitter-grammar"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_grammar.Language())
	if language == nil {
		t.Errorf("Error loading Grammar grammar")
	}
}
