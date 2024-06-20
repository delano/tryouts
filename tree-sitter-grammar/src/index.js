const Parser = require('tree-sitter');
const TryoutsGrammar = require('grammar');  // Kendrick Grammar

const parser = new Parser();
parser.setLanguage(TryoutsGrammar);

module.exports = {
  parser: parser,
  // Any other exports related to the grammar
};
