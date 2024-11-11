#include "tree_sitter/parser.h"

#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif

#define LANGUAGE_VERSION 14
#define STATE_COUNT 48
#define LARGE_STATE_COUNT 2
#define SYMBOL_COUNT 36
#define ALIAS_COUNT 0
#define TOKEN_COUNT 16
#define EXTERNAL_TOKEN_COUNT 0
#define FIELD_COUNT 0
#define MAX_ALIAS_SEQUENCE_LENGTH 4
#define PRODUCTION_ID_COUNT 1

enum ts_symbol_identifiers {
  anon_sym_POUND_POUND = 1,
  aux_sym_tryout_description_token1 = 2,
  anon_sym_POUND_EQ_GT = 3,
  anon_sym_POUND = 4,
  aux_sym_comment_token1 = 5,
  anon_sym_require = 6,
  anon_sym_AT = 7,
  aux_sym_assignment_statement_token1 = 8,
  anon_sym_EQ = 9,
  aux_sym_configuration_statement_token1 = 10,
  sym_code_line = 11,
  anon_sym_SQUOTE = 12,
  aux_sym_string_literal_token1 = 13,
  anon_sym_DQUOTE = 14,
  aux_sym_string_literal_token2 = 15,
  sym_source_file = 16,
  sym_setup_section = 17,
  sym_teardown_section = 18,
  sym_tryout_block = 19,
  sym_tryout_description = 20,
  sym_expectation = 21,
  sym_comment = 22,
  sym_require_statement = 23,
  sym_assignment_statement = 24,
  sym_configuration_statement = 25,
  sym_string_literal = 26,
  sym_any_value = 27,
  sym_any_statement = 28,
  aux_sym_source_file_repeat1 = 29,
  aux_sym_setup_section_repeat1 = 30,
  aux_sym_setup_section_repeat2 = 31,
  aux_sym_setup_section_repeat3 = 32,
  aux_sym_teardown_section_repeat1 = 33,
  aux_sym_tryout_block_repeat1 = 34,
  aux_sym_tryout_block_repeat2 = 35,
};

static const char * const ts_symbol_names[] = {
  [ts_builtin_sym_end] = "end",
  [anon_sym_POUND_POUND] = "##",
  [aux_sym_tryout_description_token1] = "tryout_description_token1",
  [anon_sym_POUND_EQ_GT] = "#=>",
  [anon_sym_POUND] = "#",
  [aux_sym_comment_token1] = "comment_token1",
  [anon_sym_require] = "require",
  [anon_sym_AT] = "@",
  [aux_sym_assignment_statement_token1] = "assignment_statement_token1",
  [anon_sym_EQ] = "=",
  [aux_sym_configuration_statement_token1] = "configuration_statement_token1",
  [sym_code_line] = "code_line",
  [anon_sym_SQUOTE] = "'",
  [aux_sym_string_literal_token1] = "string_literal_token1",
  [anon_sym_DQUOTE] = "\"",
  [aux_sym_string_literal_token2] = "string_literal_token2",
  [sym_source_file] = "source_file",
  [sym_setup_section] = "setup_section",
  [sym_teardown_section] = "teardown_section",
  [sym_tryout_block] = "tryout_block",
  [sym_tryout_description] = "tryout_description",
  [sym_expectation] = "expectation",
  [sym_comment] = "comment",
  [sym_require_statement] = "require_statement",
  [sym_assignment_statement] = "assignment_statement",
  [sym_configuration_statement] = "configuration_statement",
  [sym_string_literal] = "string_literal",
  [sym_any_value] = "any_value",
  [sym_any_statement] = "any_statement",
  [aux_sym_source_file_repeat1] = "source_file_repeat1",
  [aux_sym_setup_section_repeat1] = "setup_section_repeat1",
  [aux_sym_setup_section_repeat2] = "setup_section_repeat2",
  [aux_sym_setup_section_repeat3] = "setup_section_repeat3",
  [aux_sym_teardown_section_repeat1] = "teardown_section_repeat1",
  [aux_sym_tryout_block_repeat1] = "tryout_block_repeat1",
  [aux_sym_tryout_block_repeat2] = "tryout_block_repeat2",
};

static const TSSymbol ts_symbol_map[] = {
  [ts_builtin_sym_end] = ts_builtin_sym_end,
  [anon_sym_POUND_POUND] = anon_sym_POUND_POUND,
  [aux_sym_tryout_description_token1] = aux_sym_tryout_description_token1,
  [anon_sym_POUND_EQ_GT] = anon_sym_POUND_EQ_GT,
  [anon_sym_POUND] = anon_sym_POUND,
  [aux_sym_comment_token1] = aux_sym_comment_token1,
  [anon_sym_require] = anon_sym_require,
  [anon_sym_AT] = anon_sym_AT,
  [aux_sym_assignment_statement_token1] = aux_sym_assignment_statement_token1,
  [anon_sym_EQ] = anon_sym_EQ,
  [aux_sym_configuration_statement_token1] = aux_sym_configuration_statement_token1,
  [sym_code_line] = sym_code_line,
  [anon_sym_SQUOTE] = anon_sym_SQUOTE,
  [aux_sym_string_literal_token1] = aux_sym_string_literal_token1,
  [anon_sym_DQUOTE] = anon_sym_DQUOTE,
  [aux_sym_string_literal_token2] = aux_sym_string_literal_token2,
  [sym_source_file] = sym_source_file,
  [sym_setup_section] = sym_setup_section,
  [sym_teardown_section] = sym_teardown_section,
  [sym_tryout_block] = sym_tryout_block,
  [sym_tryout_description] = sym_tryout_description,
  [sym_expectation] = sym_expectation,
  [sym_comment] = sym_comment,
  [sym_require_statement] = sym_require_statement,
  [sym_assignment_statement] = sym_assignment_statement,
  [sym_configuration_statement] = sym_configuration_statement,
  [sym_string_literal] = sym_string_literal,
  [sym_any_value] = sym_any_value,
  [sym_any_statement] = sym_any_statement,
  [aux_sym_source_file_repeat1] = aux_sym_source_file_repeat1,
  [aux_sym_setup_section_repeat1] = aux_sym_setup_section_repeat1,
  [aux_sym_setup_section_repeat2] = aux_sym_setup_section_repeat2,
  [aux_sym_setup_section_repeat3] = aux_sym_setup_section_repeat3,
  [aux_sym_teardown_section_repeat1] = aux_sym_teardown_section_repeat1,
  [aux_sym_tryout_block_repeat1] = aux_sym_tryout_block_repeat1,
  [aux_sym_tryout_block_repeat2] = aux_sym_tryout_block_repeat2,
};

static const TSSymbolMetadata ts_symbol_metadata[] = {
  [ts_builtin_sym_end] = {
    .visible = false,
    .named = true,
  },
  [anon_sym_POUND_POUND] = {
    .visible = true,
    .named = false,
  },
  [aux_sym_tryout_description_token1] = {
    .visible = false,
    .named = false,
  },
  [anon_sym_POUND_EQ_GT] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_POUND] = {
    .visible = true,
    .named = false,
  },
  [aux_sym_comment_token1] = {
    .visible = false,
    .named = false,
  },
  [anon_sym_require] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_AT] = {
    .visible = true,
    .named = false,
  },
  [aux_sym_assignment_statement_token1] = {
    .visible = false,
    .named = false,
  },
  [anon_sym_EQ] = {
    .visible = true,
    .named = false,
  },
  [aux_sym_configuration_statement_token1] = {
    .visible = false,
    .named = false,
  },
  [sym_code_line] = {
    .visible = true,
    .named = true,
  },
  [anon_sym_SQUOTE] = {
    .visible = true,
    .named = false,
  },
  [aux_sym_string_literal_token1] = {
    .visible = false,
    .named = false,
  },
  [anon_sym_DQUOTE] = {
    .visible = true,
    .named = false,
  },
  [aux_sym_string_literal_token2] = {
    .visible = false,
    .named = false,
  },
  [sym_source_file] = {
    .visible = true,
    .named = true,
  },
  [sym_setup_section] = {
    .visible = true,
    .named = true,
  },
  [sym_teardown_section] = {
    .visible = true,
    .named = true,
  },
  [sym_tryout_block] = {
    .visible = true,
    .named = true,
  },
  [sym_tryout_description] = {
    .visible = true,
    .named = true,
  },
  [sym_expectation] = {
    .visible = true,
    .named = true,
  },
  [sym_comment] = {
    .visible = true,
    .named = true,
  },
  [sym_require_statement] = {
    .visible = true,
    .named = true,
  },
  [sym_assignment_statement] = {
    .visible = true,
    .named = true,
  },
  [sym_configuration_statement] = {
    .visible = true,
    .named = true,
  },
  [sym_string_literal] = {
    .visible = true,
    .named = true,
  },
  [sym_any_value] = {
    .visible = true,
    .named = true,
  },
  [sym_any_statement] = {
    .visible = true,
    .named = true,
  },
  [aux_sym_source_file_repeat1] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_setup_section_repeat1] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_setup_section_repeat2] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_setup_section_repeat3] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_teardown_section_repeat1] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_tryout_block_repeat1] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_tryout_block_repeat2] = {
    .visible = false,
    .named = false,
  },
};

static const TSSymbol ts_alias_sequences[PRODUCTION_ID_COUNT][MAX_ALIAS_SEQUENCE_LENGTH] = {
  [0] = {0},
};

static const uint16_t ts_non_terminal_alias_map[] = {
  0,
};

static const TSStateId ts_primary_state_ids[STATE_COUNT] = {
  [0] = 0,
  [1] = 1,
  [2] = 2,
  [3] = 3,
  [4] = 4,
  [5] = 5,
  [6] = 6,
  [7] = 7,
  [8] = 8,
  [9] = 9,
  [10] = 10,
  [11] = 11,
  [12] = 12,
  [13] = 13,
  [14] = 14,
  [15] = 15,
  [16] = 16,
  [17] = 17,
  [18] = 18,
  [19] = 19,
  [20] = 20,
  [21] = 21,
  [22] = 22,
  [23] = 23,
  [24] = 24,
  [25] = 25,
  [26] = 26,
  [27] = 27,
  [28] = 28,
  [29] = 29,
  [30] = 30,
  [31] = 31,
  [32] = 32,
  [33] = 33,
  [34] = 24,
  [35] = 35,
  [36] = 36,
  [37] = 37,
  [38] = 38,
  [39] = 39,
  [40] = 40,
  [41] = 41,
  [42] = 42,
  [43] = 43,
  [44] = 44,
  [45] = 45,
  [46] = 46,
  [47] = 47,
};

static bool ts_lex(TSLexer *lexer, TSStateId state) {
  START_LEXER();
  eof = lexer->eof(lexer);
  switch (state) {
    case 0:
      if (eof) ADVANCE(29);
      if (lookahead == '"') ADVANCE(93);
      if (lookahead == '#') ADVANCE(65);
      if (lookahead == '\'') ADVANCE(90);
      if (lookahead == '=') ADVANCE(82);
      if (lookahead == '@') ADVANCE(72);
      if (lookahead == 'r') ADVANCE(75);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(0);
      if (lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(81);
      if (('A' <= lookahead && lookahead <= 'Z')) ADVANCE(74);
      END_STATE();
    case 1:
      if (lookahead == '\n') SKIP(1);
      if (lookahead == '#') ADVANCE(66);
      if (lookahead == '@') ADVANCE(73);
      if (lookahead == 'r') ADVANCE(43);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(33);
      if (('A' <= lookahead && lookahead <= 'Z')) ADVANCE(38);
      if (lookahead != 0) ADVANCE(62);
      END_STATE();
    case 2:
      if (lookahead == '\n') SKIP(2);
      if (lookahead == '@') ADVANCE(73);
      if (lookahead == 'r') ADVANCE(43);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(39);
      if (('A' <= lookahead && lookahead <= 'Z')) ADVANCE(38);
      if (lookahead != 0) ADVANCE(62);
      END_STATE();
    case 3:
      if (lookahead == '\n') SKIP(3);
      if (lookahead == '#') ADVANCE(34);
      if (lookahead == '@') ADVANCE(73);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(36);
      if (('A' <= lookahead && lookahead <= 'Z')) ADVANCE(38);
      if (lookahead != 0) ADVANCE(62);
      END_STATE();
    case 4:
      if (lookahead == '\n') SKIP(4);
      if (lookahead == '#') ADVANCE(67);
      if (lookahead == '@') ADVANCE(73);
      if (lookahead == 'r') ADVANCE(43);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(35);
      if (('A' <= lookahead && lookahead <= 'Z')) ADVANCE(38);
      if (lookahead != 0) ADVANCE(62);
      END_STATE();
    case 5:
      if (lookahead == '#') ADVANCE(30);
      if (lookahead == '=') ADVANCE(10);
      END_STATE();
    case 6:
      if (lookahead == '#') ADVANCE(5);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(84);
      if (lookahead != 0) ADVANCE(89);
      END_STATE();
    case 7:
      if (lookahead == '#') ADVANCE(9);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(85);
      if (lookahead != 0) ADVANCE(89);
      END_STATE();
    case 8:
      if (lookahead == '.') ADVANCE(12);
      if (('0' <= lookahead && lookahead <= ':') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(8);
      END_STATE();
    case 9:
      if (lookahead == '=') ADVANCE(10);
      END_STATE();
    case 10:
      if (lookahead == '>') ADVANCE(63);
      END_STATE();
    case 11:
      if (lookahead == 'a') ADVANCE(23);
      END_STATE();
    case 12:
      if (lookahead == 'b') ADVANCE(21);
      if (lookahead == 'c') ADVANCE(19);
      if (lookahead == 'p') ADVANCE(11);
      END_STATE();
    case 13:
      if (lookahead == 'e') ADVANCE(83);
      END_STATE();
    case 14:
      if (lookahead == 'f') ADVANCE(17);
      END_STATE();
    case 15:
      if (lookahead == 'g') ADVANCE(25);
      END_STATE();
    case 16:
      if (lookahead == 'h') ADVANCE(83);
      END_STATE();
    case 17:
      if (lookahead == 'i') ADVANCE(15);
      END_STATE();
    case 18:
      if (lookahead == 'n') ADVANCE(14);
      END_STATE();
    case 19:
      if (lookahead == 'o') ADVANCE(18);
      END_STATE();
    case 20:
      if (lookahead == 'o') ADVANCE(24);
      END_STATE();
    case 21:
      if (lookahead == 'o') ADVANCE(20);
      END_STATE();
    case 22:
      if (lookahead == 'r') ADVANCE(13);
      END_STATE();
    case 23:
      if (lookahead == 't') ADVANCE(16);
      END_STATE();
    case 24:
      if (lookahead == 't') ADVANCE(83);
      END_STATE();
    case 25:
      if (lookahead == 'u') ADVANCE(22);
      END_STATE();
    case 26:
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(26);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(81);
      END_STATE();
    case 27:
      if (eof) ADVANCE(29);
      if (lookahead == '\n') SKIP(27);
      if (lookahead == '#') ADVANCE(34);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(37);
      if (lookahead != 0) ADVANCE(62);
      END_STATE();
    case 28:
      if (eof) ADVANCE(29);
      if (lookahead == '\n') SKIP(28);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(61);
      if (lookahead != 0) ADVANCE(62);
      END_STATE();
    case 29:
      ACCEPT_TOKEN(ts_builtin_sym_end);
      END_STATE();
    case 30:
      ACCEPT_TOKEN(anon_sym_POUND_POUND);
      END_STATE();
    case 31:
      ACCEPT_TOKEN(anon_sym_POUND_POUND);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 32:
      ACCEPT_TOKEN(anon_sym_POUND_POUND);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(89);
      END_STATE();
    case 33:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == '#') ADVANCE(66);
      if (lookahead == '@') ADVANCE(73);
      if (lookahead == 'r') ADVANCE(43);
      if (lookahead == '\t' ||
          (0x0b <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(33);
      if (('A' <= lookahead && lookahead <= 'Z')) ADVANCE(38);
      if (lookahead != 0 &&
          (lookahead < '\t' || '\r' < lookahead)) ADVANCE(62);
      END_STATE();
    case 34:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == '#') ADVANCE(31);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 35:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == '#') ADVANCE(67);
      if (lookahead == '@') ADVANCE(73);
      if (lookahead == 'r') ADVANCE(43);
      if (lookahead == '\t' ||
          (0x0b <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(35);
      if (('A' <= lookahead && lookahead <= 'Z')) ADVANCE(38);
      if (lookahead != 0 &&
          (lookahead < '\t' || '\r' < lookahead)) ADVANCE(62);
      END_STATE();
    case 36:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == '#') ADVANCE(34);
      if (lookahead == '@') ADVANCE(73);
      if (lookahead == '\t' ||
          (0x0b <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(36);
      if (('A' <= lookahead && lookahead <= 'Z')) ADVANCE(38);
      if (lookahead != 0 &&
          (lookahead < '\t' || '\r' < lookahead)) ADVANCE(62);
      END_STATE();
    case 37:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == '#') ADVANCE(34);
      if (lookahead == '\t' ||
          (0x0b <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(37);
      if (lookahead != 0 &&
          (lookahead < '\t' || '\r' < lookahead)) ADVANCE(62);
      END_STATE();
    case 38:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == '.') ADVANCE(41);
      if (('0' <= lookahead && lookahead <= ':') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(38);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 39:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == '@') ADVANCE(73);
      if (lookahead == 'r') ADVANCE(43);
      if (lookahead == '\t' ||
          (0x0b <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(39);
      if (('A' <= lookahead && lookahead <= 'Z')) ADVANCE(38);
      if (lookahead != 0 &&
          (lookahead < '\t' || '\r' < lookahead)) ADVANCE(62);
      END_STATE();
    case 40:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'a') ADVANCE(58);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 41:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'b') ADVANCE(53);
      if (lookahead == 'c') ADVANCE(51);
      if (lookahead == 'p') ADVANCE(40);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 42:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'e') ADVANCE(62);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 43:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'e') ADVANCE(54);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 44:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'e') ADVANCE(71);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 45:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'f') ADVANCE(49);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 46:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'g') ADVANCE(60);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 47:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'h') ADVANCE(62);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 48:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'i') ADVANCE(55);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 49:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'i') ADVANCE(46);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 50:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'n') ADVANCE(45);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 51:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'o') ADVANCE(50);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 52:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'o') ADVANCE(57);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 53:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'o') ADVANCE(52);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 54:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'q') ADVANCE(59);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 55:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'r') ADVANCE(44);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 56:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'r') ADVANCE(42);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 57:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 't') ADVANCE(62);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 58:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 't') ADVANCE(47);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 59:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'u') ADVANCE(48);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 60:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == 'u') ADVANCE(56);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 61:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead == '\t' ||
          (0x0b <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(61);
      if (lookahead != 0 &&
          (lookahead < '\t' || '\r' < lookahead)) ADVANCE(62);
      END_STATE();
    case 62:
      ACCEPT_TOKEN(aux_sym_tryout_description_token1);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 63:
      ACCEPT_TOKEN(anon_sym_POUND_EQ_GT);
      END_STATE();
    case 64:
      ACCEPT_TOKEN(anon_sym_POUND_EQ_GT);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(89);
      END_STATE();
    case 65:
      ACCEPT_TOKEN(anon_sym_POUND);
      if (lookahead == '#') ADVANCE(30);
      END_STATE();
    case 66:
      ACCEPT_TOKEN(anon_sym_POUND);
      if (lookahead == '#') ADVANCE(31);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 67:
      ACCEPT_TOKEN(anon_sym_POUND);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 68:
      ACCEPT_TOKEN(aux_sym_comment_token1);
      if (lookahead == '\t' ||
          (0x0b <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(68);
      if (lookahead != 0 &&
          (lookahead < '\t' || '\r' < lookahead)) ADVANCE(69);
      END_STATE();
    case 69:
      ACCEPT_TOKEN(aux_sym_comment_token1);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(69);
      END_STATE();
    case 70:
      ACCEPT_TOKEN(anon_sym_require);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(81);
      END_STATE();
    case 71:
      ACCEPT_TOKEN(anon_sym_require);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 72:
      ACCEPT_TOKEN(anon_sym_AT);
      END_STATE();
    case 73:
      ACCEPT_TOKEN(anon_sym_AT);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(62);
      END_STATE();
    case 74:
      ACCEPT_TOKEN(aux_sym_assignment_statement_token1);
      if (lookahead == '.') ADVANCE(12);
      if (lookahead == ':') ADVANCE(8);
      if (lookahead == '_') ADVANCE(81);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(74);
      END_STATE();
    case 75:
      ACCEPT_TOKEN(aux_sym_assignment_statement_token1);
      if (lookahead == 'e') ADVANCE(78);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(81);
      END_STATE();
    case 76:
      ACCEPT_TOKEN(aux_sym_assignment_statement_token1);
      if (lookahead == 'e') ADVANCE(70);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(81);
      END_STATE();
    case 77:
      ACCEPT_TOKEN(aux_sym_assignment_statement_token1);
      if (lookahead == 'i') ADVANCE(79);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(81);
      END_STATE();
    case 78:
      ACCEPT_TOKEN(aux_sym_assignment_statement_token1);
      if (lookahead == 'q') ADVANCE(80);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(81);
      END_STATE();
    case 79:
      ACCEPT_TOKEN(aux_sym_assignment_statement_token1);
      if (lookahead == 'r') ADVANCE(76);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(81);
      END_STATE();
    case 80:
      ACCEPT_TOKEN(aux_sym_assignment_statement_token1);
      if (lookahead == 'u') ADVANCE(77);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(81);
      END_STATE();
    case 81:
      ACCEPT_TOKEN(aux_sym_assignment_statement_token1);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(81);
      END_STATE();
    case 82:
      ACCEPT_TOKEN(anon_sym_EQ);
      END_STATE();
    case 83:
      ACCEPT_TOKEN(aux_sym_configuration_statement_token1);
      END_STATE();
    case 84:
      ACCEPT_TOKEN(sym_code_line);
      if (lookahead == '\n') ADVANCE(84);
      if (lookahead == '#') ADVANCE(86);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(84);
      if (lookahead != 0) ADVANCE(89);
      END_STATE();
    case 85:
      ACCEPT_TOKEN(sym_code_line);
      if (lookahead == '\n') ADVANCE(85);
      if (lookahead == '#') ADVANCE(87);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(85);
      if (lookahead != 0) ADVANCE(89);
      END_STATE();
    case 86:
      ACCEPT_TOKEN(sym_code_line);
      if (lookahead == '#') ADVANCE(32);
      if (lookahead == '=') ADVANCE(88);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(89);
      END_STATE();
    case 87:
      ACCEPT_TOKEN(sym_code_line);
      if (lookahead == '=') ADVANCE(88);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(89);
      END_STATE();
    case 88:
      ACCEPT_TOKEN(sym_code_line);
      if (lookahead == '>') ADVANCE(64);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(89);
      END_STATE();
    case 89:
      ACCEPT_TOKEN(sym_code_line);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(89);
      END_STATE();
    case 90:
      ACCEPT_TOKEN(anon_sym_SQUOTE);
      END_STATE();
    case 91:
      ACCEPT_TOKEN(aux_sym_string_literal_token1);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(91);
      if (lookahead != 0 &&
          lookahead != '\'') ADVANCE(92);
      END_STATE();
    case 92:
      ACCEPT_TOKEN(aux_sym_string_literal_token1);
      if (lookahead != 0 &&
          lookahead != '\'') ADVANCE(92);
      END_STATE();
    case 93:
      ACCEPT_TOKEN(anon_sym_DQUOTE);
      END_STATE();
    case 94:
      ACCEPT_TOKEN(aux_sym_string_literal_token2);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(94);
      if (lookahead != 0 &&
          lookahead != '"') ADVANCE(95);
      END_STATE();
    case 95:
      ACCEPT_TOKEN(aux_sym_string_literal_token2);
      if (lookahead != 0 &&
          lookahead != '"') ADVANCE(95);
      END_STATE();
    default:
      return false;
  }
}

static const TSLexMode ts_lex_modes[STATE_COUNT] = {
  [0] = {.lex_state = 0},
  [1] = {.lex_state = 1},
  [2] = {.lex_state = 4},
  [3] = {.lex_state = 2},
  [4] = {.lex_state = 27},
  [5] = {.lex_state = 2},
  [6] = {.lex_state = 27},
  [7] = {.lex_state = 3},
  [8] = {.lex_state = 3},
  [9] = {.lex_state = 3},
  [10] = {.lex_state = 3},
  [11] = {.lex_state = 27},
  [12] = {.lex_state = 4},
  [13] = {.lex_state = 6},
  [14] = {.lex_state = 2},
  [15] = {.lex_state = 0},
  [16] = {.lex_state = 6},
  [17] = {.lex_state = 4},
  [18] = {.lex_state = 28},
  [19] = {.lex_state = 7},
  [20] = {.lex_state = 3},
  [21] = {.lex_state = 3},
  [22] = {.lex_state = 3},
  [23] = {.lex_state = 2},
  [24] = {.lex_state = 3},
  [25] = {.lex_state = 28},
  [26] = {.lex_state = 2},
  [27] = {.lex_state = 6},
  [28] = {.lex_state = 0},
  [29] = {.lex_state = 27},
  [30] = {.lex_state = 27},
  [31] = {.lex_state = 27},
  [32] = {.lex_state = 7},
  [33] = {.lex_state = 28},
  [34] = {.lex_state = 28},
  [35] = {.lex_state = 94},
  [36] = {.lex_state = 68},
  [37] = {.lex_state = 28},
  [38] = {.lex_state = 91},
  [39] = {.lex_state = 0},
  [40] = {.lex_state = 0},
  [41] = {.lex_state = 0},
  [42] = {.lex_state = 0},
  [43] = {.lex_state = 0},
  [44] = {.lex_state = 26},
  [45] = {.lex_state = 28},
  [46] = {.lex_state = 0},
  [47] = {.lex_state = 28},
};

static const uint16_t ts_parse_table[LARGE_STATE_COUNT][SYMBOL_COUNT] = {
  [0] = {
    [ts_builtin_sym_end] = ACTIONS(1),
    [anon_sym_POUND_POUND] = ACTIONS(1),
    [anon_sym_POUND] = ACTIONS(1),
    [anon_sym_require] = ACTIONS(1),
    [anon_sym_AT] = ACTIONS(1),
    [aux_sym_assignment_statement_token1] = ACTIONS(1),
    [anon_sym_EQ] = ACTIONS(1),
    [aux_sym_configuration_statement_token1] = ACTIONS(1),
    [anon_sym_SQUOTE] = ACTIONS(1),
    [anon_sym_DQUOTE] = ACTIONS(1),
  },
  [1] = {
    [sym_source_file] = STATE(43),
    [sym_setup_section] = STATE(15),
    [sym_tryout_block] = STATE(6),
    [sym_tryout_description] = STATE(13),
    [sym_comment] = STATE(2),
    [sym_require_statement] = STATE(5),
    [sym_assignment_statement] = STATE(10),
    [sym_configuration_statement] = STATE(10),
    [sym_any_statement] = STATE(10),
    [aux_sym_source_file_repeat1] = STATE(6),
    [aux_sym_setup_section_repeat1] = STATE(2),
    [aux_sym_setup_section_repeat2] = STATE(5),
    [aux_sym_setup_section_repeat3] = STATE(10),
    [aux_sym_tryout_block_repeat1] = STATE(13),
    [anon_sym_POUND_POUND] = ACTIONS(3),
    [aux_sym_tryout_description_token1] = ACTIONS(5),
    [anon_sym_POUND] = ACTIONS(7),
    [anon_sym_require] = ACTIONS(9),
    [anon_sym_AT] = ACTIONS(11),
    [aux_sym_configuration_statement_token1] = ACTIONS(13),
  },
};

static const uint16_t ts_small_parse_table[] = {
  [0] = 8,
    ACTIONS(5), 1,
      aux_sym_tryout_description_token1,
    ACTIONS(7), 1,
      anon_sym_POUND,
    ACTIONS(9), 1,
      anon_sym_require,
    ACTIONS(11), 1,
      anon_sym_AT,
    ACTIONS(13), 1,
      aux_sym_configuration_statement_token1,
    STATE(3), 2,
      sym_require_statement,
      aux_sym_setup_section_repeat2,
    STATE(12), 2,
      sym_comment,
      aux_sym_setup_section_repeat1,
    STATE(9), 4,
      sym_assignment_statement,
      sym_configuration_statement,
      sym_any_statement,
      aux_sym_setup_section_repeat3,
  [30] = 6,
    ACTIONS(5), 1,
      aux_sym_tryout_description_token1,
    ACTIONS(9), 1,
      anon_sym_require,
    ACTIONS(11), 1,
      anon_sym_AT,
    ACTIONS(13), 1,
      aux_sym_configuration_statement_token1,
    STATE(14), 2,
      sym_require_statement,
      aux_sym_setup_section_repeat2,
    STATE(7), 4,
      sym_assignment_statement,
      sym_configuration_statement,
      sym_any_statement,
      aux_sym_setup_section_repeat3,
  [53] = 7,
    ACTIONS(3), 1,
      anon_sym_POUND_POUND,
    ACTIONS(15), 1,
      ts_builtin_sym_end,
    ACTIONS(17), 1,
      aux_sym_tryout_description_token1,
    STATE(42), 1,
      sym_teardown_section,
    STATE(11), 2,
      sym_tryout_block,
      aux_sym_source_file_repeat1,
    STATE(13), 2,
      sym_tryout_description,
      aux_sym_tryout_block_repeat1,
    STATE(25), 2,
      sym_any_statement,
      aux_sym_teardown_section_repeat1,
  [78] = 6,
    ACTIONS(5), 1,
      aux_sym_tryout_description_token1,
    ACTIONS(9), 1,
      anon_sym_require,
    ACTIONS(11), 1,
      anon_sym_AT,
    ACTIONS(13), 1,
      aux_sym_configuration_statement_token1,
    STATE(14), 2,
      sym_require_statement,
      aux_sym_setup_section_repeat2,
    STATE(9), 4,
      sym_assignment_statement,
      sym_configuration_statement,
      sym_any_statement,
      aux_sym_setup_section_repeat3,
  [101] = 7,
    ACTIONS(3), 1,
      anon_sym_POUND_POUND,
    ACTIONS(17), 1,
      aux_sym_tryout_description_token1,
    ACTIONS(19), 1,
      ts_builtin_sym_end,
    STATE(46), 1,
      sym_teardown_section,
    STATE(11), 2,
      sym_tryout_block,
      aux_sym_source_file_repeat1,
    STATE(13), 2,
      sym_tryout_description,
      aux_sym_tryout_block_repeat1,
    STATE(25), 2,
      sym_any_statement,
      aux_sym_teardown_section_repeat1,
  [126] = 5,
    ACTIONS(5), 1,
      aux_sym_tryout_description_token1,
    ACTIONS(11), 1,
      anon_sym_AT,
    ACTIONS(13), 1,
      aux_sym_configuration_statement_token1,
    ACTIONS(21), 1,
      anon_sym_POUND_POUND,
    STATE(8), 4,
      sym_assignment_statement,
      sym_configuration_statement,
      sym_any_statement,
      aux_sym_setup_section_repeat3,
  [145] = 5,
    ACTIONS(23), 1,
      anon_sym_POUND_POUND,
    ACTIONS(25), 1,
      aux_sym_tryout_description_token1,
    ACTIONS(28), 1,
      anon_sym_AT,
    ACTIONS(31), 1,
      aux_sym_configuration_statement_token1,
    STATE(8), 4,
      sym_assignment_statement,
      sym_configuration_statement,
      sym_any_statement,
      aux_sym_setup_section_repeat3,
  [164] = 5,
    ACTIONS(5), 1,
      aux_sym_tryout_description_token1,
    ACTIONS(11), 1,
      anon_sym_AT,
    ACTIONS(13), 1,
      aux_sym_configuration_statement_token1,
    ACTIONS(34), 1,
      anon_sym_POUND_POUND,
    STATE(8), 4,
      sym_assignment_statement,
      sym_configuration_statement,
      sym_any_statement,
      aux_sym_setup_section_repeat3,
  [183] = 5,
    ACTIONS(5), 1,
      aux_sym_tryout_description_token1,
    ACTIONS(11), 1,
      anon_sym_AT,
    ACTIONS(13), 1,
      aux_sym_configuration_statement_token1,
    ACTIONS(36), 1,
      anon_sym_POUND_POUND,
    STATE(8), 4,
      sym_assignment_statement,
      sym_configuration_statement,
      sym_any_statement,
      aux_sym_setup_section_repeat3,
  [202] = 5,
    ACTIONS(38), 1,
      ts_builtin_sym_end,
    ACTIONS(40), 1,
      anon_sym_POUND_POUND,
    ACTIONS(43), 1,
      aux_sym_tryout_description_token1,
    STATE(11), 2,
      sym_tryout_block,
      aux_sym_source_file_repeat1,
    STATE(13), 2,
      sym_tryout_description,
      aux_sym_tryout_block_repeat1,
  [220] = 3,
    ACTIONS(47), 1,
      anon_sym_POUND,
    STATE(12), 2,
      sym_comment,
      aux_sym_setup_section_repeat1,
    ACTIONS(45), 4,
      aux_sym_tryout_description_token1,
      anon_sym_require,
      anon_sym_AT,
      aux_sym_configuration_statement_token1,
  [234] = 6,
    ACTIONS(3), 1,
      anon_sym_POUND_POUND,
    ACTIONS(50), 1,
      anon_sym_POUND_EQ_GT,
    ACTIONS(52), 1,
      sym_code_line,
    STATE(19), 1,
      aux_sym_tryout_block_repeat2,
    STATE(29), 1,
      sym_expectation,
    STATE(16), 2,
      sym_tryout_description,
      aux_sym_tryout_block_repeat1,
  [254] = 3,
    ACTIONS(56), 1,
      anon_sym_require,
    STATE(14), 2,
      sym_require_statement,
      aux_sym_setup_section_repeat2,
    ACTIONS(54), 3,
      aux_sym_tryout_description_token1,
      anon_sym_AT,
      aux_sym_configuration_statement_token1,
  [267] = 3,
    ACTIONS(59), 1,
      anon_sym_POUND_POUND,
    STATE(4), 2,
      sym_tryout_block,
      aux_sym_source_file_repeat1,
    STATE(13), 2,
      sym_tryout_description,
      aux_sym_tryout_block_repeat1,
  [279] = 3,
    ACTIONS(61), 1,
      anon_sym_POUND_POUND,
    ACTIONS(64), 2,
      anon_sym_POUND_EQ_GT,
      sym_code_line,
    STATE(16), 2,
      sym_tryout_description,
      aux_sym_tryout_block_repeat1,
  [291] = 1,
    ACTIONS(66), 5,
      aux_sym_tryout_description_token1,
      anon_sym_POUND,
      anon_sym_require,
      anon_sym_AT,
      aux_sym_configuration_statement_token1,
  [299] = 3,
    ACTIONS(68), 1,
      ts_builtin_sym_end,
    ACTIONS(70), 1,
      aux_sym_tryout_description_token1,
    STATE(18), 2,
      sym_any_statement,
      aux_sym_teardown_section_repeat1,
  [310] = 4,
    ACTIONS(50), 1,
      anon_sym_POUND_EQ_GT,
    ACTIONS(73), 1,
      sym_code_line,
    STATE(31), 1,
      sym_expectation,
    STATE(32), 1,
      aux_sym_tryout_block_repeat2,
  [323] = 1,
    ACTIONS(75), 4,
      anon_sym_POUND_POUND,
      aux_sym_tryout_description_token1,
      anon_sym_AT,
      aux_sym_configuration_statement_token1,
  [330] = 1,
    ACTIONS(77), 4,
      anon_sym_POUND_POUND,
      aux_sym_tryout_description_token1,
      anon_sym_AT,
      aux_sym_configuration_statement_token1,
  [337] = 1,
    ACTIONS(79), 4,
      anon_sym_POUND_POUND,
      aux_sym_tryout_description_token1,
      anon_sym_AT,
      aux_sym_configuration_statement_token1,
  [344] = 1,
    ACTIONS(81), 4,
      aux_sym_tryout_description_token1,
      anon_sym_require,
      anon_sym_AT,
      aux_sym_configuration_statement_token1,
  [351] = 1,
    ACTIONS(83), 4,
      anon_sym_POUND_POUND,
      aux_sym_tryout_description_token1,
      anon_sym_AT,
      aux_sym_configuration_statement_token1,
  [358] = 3,
    ACTIONS(85), 1,
      ts_builtin_sym_end,
    ACTIONS(87), 1,
      aux_sym_tryout_description_token1,
    STATE(18), 2,
      sym_any_statement,
      aux_sym_teardown_section_repeat1,
  [369] = 1,
    ACTIONS(89), 4,
      aux_sym_tryout_description_token1,
      anon_sym_require,
      anon_sym_AT,
      aux_sym_configuration_statement_token1,
  [376] = 1,
    ACTIONS(91), 3,
      anon_sym_POUND_POUND,
      anon_sym_POUND_EQ_GT,
      sym_code_line,
  [382] = 3,
    ACTIONS(93), 1,
      anon_sym_SQUOTE,
    ACTIONS(95), 1,
      anon_sym_DQUOTE,
    STATE(26), 1,
      sym_string_literal,
  [392] = 2,
    ACTIONS(97), 1,
      ts_builtin_sym_end,
    ACTIONS(99), 2,
      anon_sym_POUND_POUND,
      aux_sym_tryout_description_token1,
  [400] = 2,
    ACTIONS(101), 1,
      ts_builtin_sym_end,
    ACTIONS(103), 2,
      anon_sym_POUND_POUND,
      aux_sym_tryout_description_token1,
  [408] = 2,
    ACTIONS(105), 1,
      ts_builtin_sym_end,
    ACTIONS(107), 2,
      anon_sym_POUND_POUND,
      aux_sym_tryout_description_token1,
  [416] = 3,
    ACTIONS(109), 1,
      anon_sym_POUND_EQ_GT,
    ACTIONS(111), 1,
      sym_code_line,
    STATE(32), 1,
      aux_sym_tryout_block_repeat2,
  [426] = 2,
    ACTIONS(114), 1,
      aux_sym_tryout_description_token1,
    STATE(20), 1,
      sym_any_value,
  [433] = 1,
    ACTIONS(116), 2,
      ts_builtin_sym_end,
      aux_sym_tryout_description_token1,
  [438] = 1,
    ACTIONS(118), 1,
      aux_sym_string_literal_token2,
  [442] = 1,
    ACTIONS(120), 1,
      aux_sym_comment_token1,
  [446] = 1,
    ACTIONS(122), 1,
      aux_sym_tryout_description_token1,
  [450] = 1,
    ACTIONS(124), 1,
      aux_sym_string_literal_token1,
  [454] = 1,
    ACTIONS(126), 1,
      anon_sym_EQ,
  [458] = 1,
    ACTIONS(128), 1,
      anon_sym_SQUOTE,
  [462] = 1,
    ACTIONS(128), 1,
      anon_sym_DQUOTE,
  [466] = 1,
    ACTIONS(130), 1,
      ts_builtin_sym_end,
  [470] = 1,
    ACTIONS(132), 1,
      ts_builtin_sym_end,
  [474] = 1,
    ACTIONS(134), 1,
      aux_sym_assignment_statement_token1,
  [478] = 1,
    ACTIONS(136), 1,
      aux_sym_tryout_description_token1,
  [482] = 1,
    ACTIONS(15), 1,
      ts_builtin_sym_end,
  [486] = 1,
    ACTIONS(138), 1,
      aux_sym_tryout_description_token1,
};

static const uint32_t ts_small_parse_table_map[] = {
  [SMALL_STATE(2)] = 0,
  [SMALL_STATE(3)] = 30,
  [SMALL_STATE(4)] = 53,
  [SMALL_STATE(5)] = 78,
  [SMALL_STATE(6)] = 101,
  [SMALL_STATE(7)] = 126,
  [SMALL_STATE(8)] = 145,
  [SMALL_STATE(9)] = 164,
  [SMALL_STATE(10)] = 183,
  [SMALL_STATE(11)] = 202,
  [SMALL_STATE(12)] = 220,
  [SMALL_STATE(13)] = 234,
  [SMALL_STATE(14)] = 254,
  [SMALL_STATE(15)] = 267,
  [SMALL_STATE(16)] = 279,
  [SMALL_STATE(17)] = 291,
  [SMALL_STATE(18)] = 299,
  [SMALL_STATE(19)] = 310,
  [SMALL_STATE(20)] = 323,
  [SMALL_STATE(21)] = 330,
  [SMALL_STATE(22)] = 337,
  [SMALL_STATE(23)] = 344,
  [SMALL_STATE(24)] = 351,
  [SMALL_STATE(25)] = 358,
  [SMALL_STATE(26)] = 369,
  [SMALL_STATE(27)] = 376,
  [SMALL_STATE(28)] = 382,
  [SMALL_STATE(29)] = 392,
  [SMALL_STATE(30)] = 400,
  [SMALL_STATE(31)] = 408,
  [SMALL_STATE(32)] = 416,
  [SMALL_STATE(33)] = 426,
  [SMALL_STATE(34)] = 433,
  [SMALL_STATE(35)] = 438,
  [SMALL_STATE(36)] = 442,
  [SMALL_STATE(37)] = 446,
  [SMALL_STATE(38)] = 450,
  [SMALL_STATE(39)] = 454,
  [SMALL_STATE(40)] = 458,
  [SMALL_STATE(41)] = 462,
  [SMALL_STATE(42)] = 466,
  [SMALL_STATE(43)] = 470,
  [SMALL_STATE(44)] = 474,
  [SMALL_STATE(45)] = 478,
  [SMALL_STATE(46)] = 482,
  [SMALL_STATE(47)] = 486,
};

static const TSParseActionEntry ts_parse_actions[] = {
  [0] = {.entry = {.count = 0, .reusable = false}},
  [1] = {.entry = {.count = 1, .reusable = false}}, RECOVER(),
  [3] = {.entry = {.count = 1, .reusable = false}}, SHIFT(47),
  [5] = {.entry = {.count = 1, .reusable = false}}, SHIFT(24),
  [7] = {.entry = {.count = 1, .reusable = false}}, SHIFT(36),
  [9] = {.entry = {.count = 1, .reusable = false}}, SHIFT(28),
  [11] = {.entry = {.count = 1, .reusable = false}}, SHIFT(44),
  [13] = {.entry = {.count = 1, .reusable = false}}, SHIFT(45),
  [15] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 2, 0, 0),
  [17] = {.entry = {.count = 1, .reusable = false}}, SHIFT(34),
  [19] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 1, 0, 0),
  [21] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_setup_section, 3, 0, 0),
  [23] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_setup_section_repeat3, 2, 0, 0),
  [25] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_setup_section_repeat3, 2, 0, 0), SHIFT_REPEAT(24),
  [28] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_setup_section_repeat3, 2, 0, 0), SHIFT_REPEAT(44),
  [31] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_setup_section_repeat3, 2, 0, 0), SHIFT_REPEAT(45),
  [34] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_setup_section, 2, 0, 0),
  [36] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_setup_section, 1, 0, 0),
  [38] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0),
  [40] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(47),
  [43] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0),
  [45] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_setup_section_repeat1, 2, 0, 0),
  [47] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_setup_section_repeat1, 2, 0, 0), SHIFT_REPEAT(36),
  [50] = {.entry = {.count = 1, .reusable = false}}, SHIFT(37),
  [52] = {.entry = {.count = 1, .reusable = false}}, SHIFT(19),
  [54] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_setup_section_repeat2, 2, 0, 0),
  [56] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_setup_section_repeat2, 2, 0, 0), SHIFT_REPEAT(28),
  [59] = {.entry = {.count = 1, .reusable = true}}, SHIFT(47),
  [61] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_tryout_block_repeat1, 2, 0, 0), SHIFT_REPEAT(47),
  [64] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_tryout_block_repeat1, 2, 0, 0),
  [66] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_comment, 2, 0, 0),
  [68] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_teardown_section_repeat1, 2, 0, 0),
  [70] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_teardown_section_repeat1, 2, 0, 0), SHIFT_REPEAT(34),
  [73] = {.entry = {.count = 1, .reusable = false}}, SHIFT(32),
  [75] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_assignment_statement, 4, 0, 0),
  [77] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_configuration_statement, 2, 0, 0),
  [79] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_any_value, 1, 0, 0),
  [81] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_string_literal, 3, 0, 0),
  [83] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_any_statement, 1, 0, 0),
  [85] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_teardown_section, 1, 0, 0),
  [87] = {.entry = {.count = 1, .reusable = true}}, SHIFT(34),
  [89] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_require_statement, 2, 0, 0),
  [91] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_tryout_description, 2, 0, 0),
  [93] = {.entry = {.count = 1, .reusable = true}}, SHIFT(38),
  [95] = {.entry = {.count = 1, .reusable = true}}, SHIFT(35),
  [97] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_tryout_block, 2, 0, 0),
  [99] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_tryout_block, 2, 0, 0),
  [101] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_expectation, 2, 0, 0),
  [103] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_expectation, 2, 0, 0),
  [105] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_tryout_block, 3, 0, 0),
  [107] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_tryout_block, 3, 0, 0),
  [109] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_tryout_block_repeat2, 2, 0, 0),
  [111] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_tryout_block_repeat2, 2, 0, 0), SHIFT_REPEAT(32),
  [114] = {.entry = {.count = 1, .reusable = true}}, SHIFT(22),
  [116] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_any_statement, 1, 0, 0),
  [118] = {.entry = {.count = 1, .reusable = true}}, SHIFT(41),
  [120] = {.entry = {.count = 1, .reusable = true}}, SHIFT(17),
  [122] = {.entry = {.count = 1, .reusable = true}}, SHIFT(30),
  [124] = {.entry = {.count = 1, .reusable = true}}, SHIFT(40),
  [126] = {.entry = {.count = 1, .reusable = true}}, SHIFT(33),
  [128] = {.entry = {.count = 1, .reusable = true}}, SHIFT(23),
  [130] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 3, 0, 0),
  [132] = {.entry = {.count = 1, .reusable = true}},  ACCEPT_INPUT(),
  [134] = {.entry = {.count = 1, .reusable = true}}, SHIFT(39),
  [136] = {.entry = {.count = 1, .reusable = true}}, SHIFT(21),
  [138] = {.entry = {.count = 1, .reusable = true}}, SHIFT(27),
};

#ifdef __cplusplus
extern "C" {
#endif
#ifdef TREE_SITTER_HIDE_SYMBOLS
#define TS_PUBLIC
#elif defined(_WIN32)
#define TS_PUBLIC __declspec(dllexport)
#else
#define TS_PUBLIC __attribute__((visibility("default")))
#endif

TS_PUBLIC const TSLanguage *tree_sitter_tryouts(void) {
  static const TSLanguage language = {
    .version = LANGUAGE_VERSION,
    .symbol_count = SYMBOL_COUNT,
    .alias_count = ALIAS_COUNT,
    .token_count = TOKEN_COUNT,
    .external_token_count = EXTERNAL_TOKEN_COUNT,
    .state_count = STATE_COUNT,
    .large_state_count = LARGE_STATE_COUNT,
    .production_id_count = PRODUCTION_ID_COUNT,
    .field_count = FIELD_COUNT,
    .max_alias_sequence_length = MAX_ALIAS_SEQUENCE_LENGTH,
    .parse_table = &ts_parse_table[0][0],
    .small_parse_table = ts_small_parse_table,
    .small_parse_table_map = ts_small_parse_table_map,
    .parse_actions = ts_parse_actions,
    .symbol_names = ts_symbol_names,
    .symbol_metadata = ts_symbol_metadata,
    .public_symbol_map = ts_symbol_map,
    .alias_map = ts_non_terminal_alias_map,
    .alias_sequences = &ts_alias_sequences[0][0],
    .lex_modes = ts_lex_modes,
    .lex_fn = ts_lex,
    .primary_state_ids = ts_primary_state_ids,
  };
  return &language;
}
#ifdef __cplusplus
}
#endif
