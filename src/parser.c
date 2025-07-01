#include "tree_sitter/parser.h"

#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif

#define LANGUAGE_VERSION 14
#define STATE_COUNT 43
#define LARGE_STATE_COUNT 2
#define SYMBOL_COUNT 22
#define ALIAS_COUNT 0
#define TOKEN_COUNT 9
#define EXTERNAL_TOKEN_COUNT 0
#define FIELD_COUNT 0
#define MAX_ALIAS_SEQUENCE_LENGTH 4
#define PRODUCTION_ID_COUNT 1

enum ts_symbol_identifiers {
  anon_sym_POUND_POUND = 1,
  aux_sym_description_line_token1 = 2,
  anon_sym_LF = 3,
  anon_sym_POUND = 4,
  aux_sym_code_line_token1 = 5,
  aux_sym_code_line_token2 = 6,
  anon_sym_POUND_EQ_GT = 7,
  sym_blank_line = 8,
  sym_source_file = 9,
  sym_setup_section = 10,
  sym_teardown_section = 11,
  sym_testcase = 12,
  sym_description_line = 13,
  sym_code_line = 14,
  sym_expectation_line = 15,
  sym_non_description_line = 16,
  aux_sym_source_file_repeat1 = 17,
  aux_sym_setup_section_repeat1 = 18,
  aux_sym_testcase_repeat1 = 19,
  aux_sym_testcase_repeat2 = 20,
  aux_sym_testcase_repeat3 = 21,
};

static const char * const ts_symbol_names[] = {
  [ts_builtin_sym_end] = "end",
  [anon_sym_POUND_POUND] = "##",
  [aux_sym_description_line_token1] = "description_line_token1",
  [anon_sym_LF] = "\n",
  [anon_sym_POUND] = "#",
  [aux_sym_code_line_token1] = "code_line_token1",
  [aux_sym_code_line_token2] = "code_line_token2",
  [anon_sym_POUND_EQ_GT] = "#=>",
  [sym_blank_line] = "blank_line",
  [sym_source_file] = "source_file",
  [sym_setup_section] = "setup_section",
  [sym_teardown_section] = "teardown_section",
  [sym_testcase] = "testcase",
  [sym_description_line] = "description_line",
  [sym_code_line] = "code_line",
  [sym_expectation_line] = "expectation_line",
  [sym_non_description_line] = "non_description_line",
  [aux_sym_source_file_repeat1] = "source_file_repeat1",
  [aux_sym_setup_section_repeat1] = "setup_section_repeat1",
  [aux_sym_testcase_repeat1] = "testcase_repeat1",
  [aux_sym_testcase_repeat2] = "testcase_repeat2",
  [aux_sym_testcase_repeat3] = "testcase_repeat3",
};

static const TSSymbol ts_symbol_map[] = {
  [ts_builtin_sym_end] = ts_builtin_sym_end,
  [anon_sym_POUND_POUND] = anon_sym_POUND_POUND,
  [aux_sym_description_line_token1] = aux_sym_description_line_token1,
  [anon_sym_LF] = anon_sym_LF,
  [anon_sym_POUND] = anon_sym_POUND,
  [aux_sym_code_line_token1] = aux_sym_code_line_token1,
  [aux_sym_code_line_token2] = aux_sym_code_line_token2,
  [anon_sym_POUND_EQ_GT] = anon_sym_POUND_EQ_GT,
  [sym_blank_line] = sym_blank_line,
  [sym_source_file] = sym_source_file,
  [sym_setup_section] = sym_setup_section,
  [sym_teardown_section] = sym_teardown_section,
  [sym_testcase] = sym_testcase,
  [sym_description_line] = sym_description_line,
  [sym_code_line] = sym_code_line,
  [sym_expectation_line] = sym_expectation_line,
  [sym_non_description_line] = sym_non_description_line,
  [aux_sym_source_file_repeat1] = aux_sym_source_file_repeat1,
  [aux_sym_setup_section_repeat1] = aux_sym_setup_section_repeat1,
  [aux_sym_testcase_repeat1] = aux_sym_testcase_repeat1,
  [aux_sym_testcase_repeat2] = aux_sym_testcase_repeat2,
  [aux_sym_testcase_repeat3] = aux_sym_testcase_repeat3,
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
  [aux_sym_description_line_token1] = {
    .visible = false,
    .named = false,
  },
  [anon_sym_LF] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_POUND] = {
    .visible = true,
    .named = false,
  },
  [aux_sym_code_line_token1] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_code_line_token2] = {
    .visible = false,
    .named = false,
  },
  [anon_sym_POUND_EQ_GT] = {
    .visible = true,
    .named = false,
  },
  [sym_blank_line] = {
    .visible = true,
    .named = true,
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
  [sym_testcase] = {
    .visible = true,
    .named = true,
  },
  [sym_description_line] = {
    .visible = true,
    .named = true,
  },
  [sym_code_line] = {
    .visible = true,
    .named = true,
  },
  [sym_expectation_line] = {
    .visible = true,
    .named = true,
  },
  [sym_non_description_line] = {
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
  [aux_sym_testcase_repeat1] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_testcase_repeat2] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_testcase_repeat3] = {
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
  [17] = 14,
  [18] = 18,
  [19] = 19,
  [20] = 20,
  [21] = 21,
  [22] = 22,
  [23] = 22,
  [24] = 21,
  [25] = 25,
  [26] = 26,
  [27] = 27,
  [28] = 28,
  [29] = 29,
  [30] = 30,
  [31] = 31,
  [32] = 32,
  [33] = 33,
  [34] = 34,
  [35] = 35,
  [36] = 36,
  [37] = 37,
  [38] = 38,
  [39] = 39,
  [40] = 27,
  [41] = 29,
  [42] = 38,
};

static bool ts_lex(TSLexer *lexer, TSStateId state) {
  START_LEXER();
  eof = lexer->eof(lexer);
  switch (state) {
    case 0:
      if (eof) ADVANCE(11);
      if (lookahead == '\n') ADVANCE(37);
      if (lookahead == '#') ADVANCE(19);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(27);
      if (lookahead != 0) ADVANCE(34);
      END_STATE();
    case 1:
      if (lookahead == '\n') SKIP(1);
      if (lookahead == '#') ADVANCE(19);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(29);
      if (lookahead != 0) ADVANCE(34);
      END_STATE();
    case 2:
      if (lookahead == '\n') ADVANCE(16);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(2);
      END_STATE();
    case 3:
      if (lookahead == '\n') SKIP(3);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(25);
      if (lookahead != 0 &&
          lookahead != '#' &&
          lookahead != '=' &&
          lookahead != '>') ADVANCE(26);
      END_STATE();
    case 4:
      if (lookahead == '\n') SKIP(4);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(28);
      if (lookahead != 0 &&
          lookahead != '#') ADVANCE(34);
      END_STATE();
    case 5:
      if (lookahead == '\n') SKIP(5);
      if (lookahead == '#') ADVANCE(22);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(31);
      if (lookahead != 0) ADVANCE(34);
      END_STATE();
    case 6:
      if (lookahead == '#') ADVANCE(12);
      END_STATE();
    case 7:
      if (lookahead == '#') ADVANCE(6);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(7);
      END_STATE();
    case 8:
      if (lookahead == '>') ADVANCE(35);
      END_STATE();
    case 9:
      if (eof) ADVANCE(11);
      if (lookahead == '\n') SKIP(9);
      if (lookahead == '#') ADVANCE(18);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(30);
      if (lookahead != 0) ADVANCE(34);
      END_STATE();
    case 10:
      if (eof) ADVANCE(11);
      if (lookahead == '\n') SKIP(10);
      if (lookahead == '#') ADVANCE(17);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(32);
      if (lookahead != 0) ADVANCE(34);
      END_STATE();
    case 11:
      ACCEPT_TOKEN(ts_builtin_sym_end);
      END_STATE();
    case 12:
      ACCEPT_TOKEN(anon_sym_POUND_POUND);
      END_STATE();
    case 13:
      ACCEPT_TOKEN(anon_sym_POUND_POUND);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(34);
      END_STATE();
    case 14:
      ACCEPT_TOKEN(aux_sym_description_line_token1);
      if (lookahead == '\t' ||
          (0x0b <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(14);
      if (lookahead != 0 &&
          (lookahead < '\t' || '\r' < lookahead)) ADVANCE(15);
      END_STATE();
    case 15:
      ACCEPT_TOKEN(aux_sym_description_line_token1);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(15);
      END_STATE();
    case 16:
      ACCEPT_TOKEN(anon_sym_LF);
      if (lookahead == '\n') ADVANCE(16);
      END_STATE();
    case 17:
      ACCEPT_TOKEN(anon_sym_POUND);
      END_STATE();
    case 18:
      ACCEPT_TOKEN(anon_sym_POUND);
      if (lookahead == '#') ADVANCE(12);
      END_STATE();
    case 19:
      ACCEPT_TOKEN(anon_sym_POUND);
      if (lookahead == '#') ADVANCE(12);
      if (lookahead == '=') ADVANCE(8);
      END_STATE();
    case 20:
      ACCEPT_TOKEN(anon_sym_POUND);
      if (lookahead == '#') ADVANCE(13);
      if (lookahead == '=') ADVANCE(33);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(34);
      END_STATE();
    case 21:
      ACCEPT_TOKEN(anon_sym_POUND);
      if (lookahead == '#') ADVANCE(13);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(34);
      END_STATE();
    case 22:
      ACCEPT_TOKEN(anon_sym_POUND);
      if (lookahead == '=') ADVANCE(8);
      END_STATE();
    case 23:
      ACCEPT_TOKEN(anon_sym_POUND);
      if (lookahead == '=') ADVANCE(33);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(34);
      END_STATE();
    case 24:
      ACCEPT_TOKEN(anon_sym_POUND);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(34);
      END_STATE();
    case 25:
      ACCEPT_TOKEN(aux_sym_code_line_token1);
      if (lookahead == '#' ||
          lookahead == '=' ||
          lookahead == '>') ADVANCE(26);
      if (lookahead == '\t' ||
          (0x0b <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(25);
      if (lookahead != 0 &&
          (lookahead < '\t' || '\r' < lookahead)) ADVANCE(26);
      END_STATE();
    case 26:
      ACCEPT_TOKEN(aux_sym_code_line_token1);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(26);
      END_STATE();
    case 27:
      ACCEPT_TOKEN(aux_sym_code_line_token2);
      if (lookahead == '\n') ADVANCE(37);
      if (lookahead == '#') ADVANCE(20);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(27);
      if (lookahead != 0) ADVANCE(34);
      END_STATE();
    case 28:
      ACCEPT_TOKEN(aux_sym_code_line_token2);
      if (lookahead == '#') ADVANCE(34);
      if (lookahead == '\t' ||
          (0x0b <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(28);
      if (lookahead != 0 &&
          (lookahead < '\t' || '\r' < lookahead)) ADVANCE(34);
      END_STATE();
    case 29:
      ACCEPT_TOKEN(aux_sym_code_line_token2);
      if (lookahead == '#') ADVANCE(20);
      if (lookahead == '\t' ||
          (0x0b <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(29);
      if (lookahead != 0 &&
          (lookahead < '\t' || '\r' < lookahead)) ADVANCE(34);
      END_STATE();
    case 30:
      ACCEPT_TOKEN(aux_sym_code_line_token2);
      if (lookahead == '#') ADVANCE(21);
      if (lookahead == '\t' ||
          (0x0b <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(30);
      if (lookahead != 0 &&
          (lookahead < '\t' || '\r' < lookahead)) ADVANCE(34);
      END_STATE();
    case 31:
      ACCEPT_TOKEN(aux_sym_code_line_token2);
      if (lookahead == '#') ADVANCE(23);
      if (lookahead == '\t' ||
          (0x0b <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(31);
      if (lookahead != 0 &&
          (lookahead < '\t' || '\r' < lookahead)) ADVANCE(34);
      END_STATE();
    case 32:
      ACCEPT_TOKEN(aux_sym_code_line_token2);
      if (lookahead == '#') ADVANCE(24);
      if (lookahead == '\t' ||
          (0x0b <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(32);
      if (lookahead != 0 &&
          (lookahead < '\t' || '\r' < lookahead)) ADVANCE(34);
      END_STATE();
    case 33:
      ACCEPT_TOKEN(aux_sym_code_line_token2);
      if (lookahead == '>') ADVANCE(36);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(34);
      END_STATE();
    case 34:
      ACCEPT_TOKEN(aux_sym_code_line_token2);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(34);
      END_STATE();
    case 35:
      ACCEPT_TOKEN(anon_sym_POUND_EQ_GT);
      END_STATE();
    case 36:
      ACCEPT_TOKEN(anon_sym_POUND_EQ_GT);
      if (lookahead != 0 &&
          lookahead != '\n') ADVANCE(34);
      END_STATE();
    case 37:
      ACCEPT_TOKEN(sym_blank_line);
      if (lookahead == '\n') ADVANCE(37);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') ADVANCE(27);
      END_STATE();
    default:
      return false;
  }
}

static const TSLexMode ts_lex_modes[STATE_COUNT] = {
  [0] = {.lex_state = 0},
  [1] = {.lex_state = 9},
  [2] = {.lex_state = 9},
  [3] = {.lex_state = 9},
  [4] = {.lex_state = 1},
  [5] = {.lex_state = 9},
  [6] = {.lex_state = 0},
  [7] = {.lex_state = 0},
  [8] = {.lex_state = 0},
  [9] = {.lex_state = 5},
  [10] = {.lex_state = 0},
  [11] = {.lex_state = 1},
  [12] = {.lex_state = 7},
  [13] = {.lex_state = 10},
  [14] = {.lex_state = 9},
  [15] = {.lex_state = 9},
  [16] = {.lex_state = 5},
  [17] = {.lex_state = 10},
  [18] = {.lex_state = 1},
  [19] = {.lex_state = 9},
  [20] = {.lex_state = 9},
  [21] = {.lex_state = 9},
  [22] = {.lex_state = 9},
  [23] = {.lex_state = 10},
  [24] = {.lex_state = 10},
  [25] = {.lex_state = 5},
  [26] = {.lex_state = 5},
  [27] = {.lex_state = 2},
  [28] = {.lex_state = 0},
  [29] = {.lex_state = 2},
  [30] = {.lex_state = 3},
  [31] = {.lex_state = 14},
  [32] = {.lex_state = 2},
  [33] = {.lex_state = 0},
  [34] = {.lex_state = 14},
  [35] = {.lex_state = 0},
  [36] = {.lex_state = 2},
  [37] = {.lex_state = 2},
  [38] = {.lex_state = 4},
  [39] = {.lex_state = 2},
  [40] = {.lex_state = 2},
  [41] = {.lex_state = 2},
  [42] = {.lex_state = 4},
};

static const uint16_t ts_parse_table[LARGE_STATE_COUNT][SYMBOL_COUNT] = {
  [0] = {
    [ts_builtin_sym_end] = ACTIONS(1),
    [anon_sym_POUND_POUND] = ACTIONS(1),
    [anon_sym_POUND] = ACTIONS(1),
    [aux_sym_code_line_token2] = ACTIONS(1),
    [anon_sym_POUND_EQ_GT] = ACTIONS(1),
    [sym_blank_line] = ACTIONS(1),
  },
  [1] = {
    [sym_source_file] = STATE(33),
    [sym_setup_section] = STATE(12),
    [sym_testcase] = STATE(2),
    [sym_description_line] = STATE(4),
    [sym_non_description_line] = STATE(15),
    [aux_sym_source_file_repeat1] = STATE(2),
    [aux_sym_setup_section_repeat1] = STATE(15),
    [aux_sym_testcase_repeat1] = STATE(4),
    [anon_sym_POUND_POUND] = ACTIONS(3),
    [anon_sym_POUND] = ACTIONS(5),
    [aux_sym_code_line_token2] = ACTIONS(7),
  },
};

static const uint16_t ts_small_parse_table[] = {
  [0] = 8,
    ACTIONS(3), 1,
      anon_sym_POUND_POUND,
    ACTIONS(9), 1,
      ts_builtin_sym_end,
    ACTIONS(11), 1,
      anon_sym_POUND,
    ACTIONS(13), 1,
      aux_sym_code_line_token2,
    STATE(28), 1,
      sym_teardown_section,
    STATE(4), 2,
      sym_description_line,
      aux_sym_testcase_repeat1,
    STATE(5), 2,
      sym_testcase,
      aux_sym_source_file_repeat1,
    STATE(13), 2,
      sym_non_description_line,
      aux_sym_setup_section_repeat1,
  [28] = 8,
    ACTIONS(3), 1,
      anon_sym_POUND_POUND,
    ACTIONS(11), 1,
      anon_sym_POUND,
    ACTIONS(13), 1,
      aux_sym_code_line_token2,
    ACTIONS(15), 1,
      ts_builtin_sym_end,
    STATE(35), 1,
      sym_teardown_section,
    STATE(4), 2,
      sym_description_line,
      aux_sym_testcase_repeat1,
    STATE(5), 2,
      sym_testcase,
      aux_sym_source_file_repeat1,
    STATE(13), 2,
      sym_non_description_line,
      aux_sym_setup_section_repeat1,
  [56] = 7,
    ACTIONS(3), 1,
      anon_sym_POUND_POUND,
    ACTIONS(17), 1,
      anon_sym_POUND,
    ACTIONS(19), 1,
      aux_sym_code_line_token2,
    ACTIONS(21), 1,
      anon_sym_POUND_EQ_GT,
    STATE(6), 2,
      sym_expectation_line,
      aux_sym_testcase_repeat3,
    STATE(9), 2,
      sym_code_line,
      aux_sym_testcase_repeat2,
    STATE(11), 2,
      sym_description_line,
      aux_sym_testcase_repeat1,
  [81] = 5,
    ACTIONS(23), 1,
      ts_builtin_sym_end,
    ACTIONS(25), 1,
      anon_sym_POUND_POUND,
    ACTIONS(28), 2,
      anon_sym_POUND,
      aux_sym_code_line_token2,
    STATE(4), 2,
      sym_description_line,
      aux_sym_testcase_repeat1,
    STATE(5), 2,
      sym_testcase,
      aux_sym_source_file_repeat1,
  [100] = 5,
    ACTIONS(21), 1,
      anon_sym_POUND_EQ_GT,
    ACTIONS(30), 1,
      ts_builtin_sym_end,
    ACTIONS(34), 1,
      sym_blank_line,
    STATE(7), 2,
      sym_expectation_line,
      aux_sym_testcase_repeat3,
    ACTIONS(32), 3,
      anon_sym_POUND_POUND,
      anon_sym_POUND,
      aux_sym_code_line_token2,
  [119] = 4,
    ACTIONS(36), 1,
      ts_builtin_sym_end,
    ACTIONS(40), 1,
      anon_sym_POUND_EQ_GT,
    STATE(7), 2,
      sym_expectation_line,
      aux_sym_testcase_repeat3,
    ACTIONS(38), 4,
      anon_sym_POUND_POUND,
      anon_sym_POUND,
      aux_sym_code_line_token2,
      sym_blank_line,
  [136] = 5,
    ACTIONS(21), 1,
      anon_sym_POUND_EQ_GT,
    ACTIONS(43), 1,
      ts_builtin_sym_end,
    ACTIONS(47), 1,
      sym_blank_line,
    STATE(7), 2,
      sym_expectation_line,
      aux_sym_testcase_repeat3,
    ACTIONS(45), 3,
      anon_sym_POUND_POUND,
      anon_sym_POUND,
      aux_sym_code_line_token2,
  [155] = 5,
    ACTIONS(17), 1,
      anon_sym_POUND,
    ACTIONS(19), 1,
      aux_sym_code_line_token2,
    ACTIONS(21), 1,
      anon_sym_POUND_EQ_GT,
    STATE(8), 2,
      sym_expectation_line,
      aux_sym_testcase_repeat3,
    STATE(16), 2,
      sym_code_line,
      aux_sym_testcase_repeat2,
  [173] = 2,
    ACTIONS(49), 1,
      ts_builtin_sym_end,
    ACTIONS(51), 5,
      anon_sym_POUND_POUND,
      anon_sym_POUND,
      aux_sym_code_line_token2,
      anon_sym_POUND_EQ_GT,
      sym_blank_line,
  [184] = 3,
    ACTIONS(53), 1,
      anon_sym_POUND_POUND,
    STATE(11), 2,
      sym_description_line,
      aux_sym_testcase_repeat1,
    ACTIONS(56), 3,
      anon_sym_POUND,
      aux_sym_code_line_token2,
      anon_sym_POUND_EQ_GT,
  [197] = 3,
    ACTIONS(58), 1,
      anon_sym_POUND_POUND,
    STATE(3), 2,
      sym_testcase,
      aux_sym_source_file_repeat1,
    STATE(4), 2,
      sym_description_line,
      aux_sym_testcase_repeat1,
  [209] = 4,
    ACTIONS(11), 1,
      anon_sym_POUND,
    ACTIONS(13), 1,
      aux_sym_code_line_token2,
    ACTIONS(60), 1,
      ts_builtin_sym_end,
    STATE(17), 2,
      sym_non_description_line,
      aux_sym_setup_section_repeat1,
  [223] = 4,
    ACTIONS(62), 1,
      anon_sym_POUND_POUND,
    ACTIONS(64), 1,
      anon_sym_POUND,
    ACTIONS(67), 1,
      aux_sym_code_line_token2,
    STATE(14), 2,
      sym_non_description_line,
      aux_sym_setup_section_repeat1,
  [237] = 4,
    ACTIONS(5), 1,
      anon_sym_POUND,
    ACTIONS(7), 1,
      aux_sym_code_line_token2,
    ACTIONS(70), 1,
      anon_sym_POUND_POUND,
    STATE(14), 2,
      sym_non_description_line,
      aux_sym_setup_section_repeat1,
  [251] = 4,
    ACTIONS(72), 1,
      anon_sym_POUND,
    ACTIONS(75), 1,
      aux_sym_code_line_token2,
    ACTIONS(78), 1,
      anon_sym_POUND_EQ_GT,
    STATE(16), 2,
      sym_code_line,
      aux_sym_testcase_repeat2,
  [265] = 4,
    ACTIONS(80), 1,
      ts_builtin_sym_end,
    ACTIONS(82), 1,
      anon_sym_POUND,
    ACTIONS(85), 1,
      aux_sym_code_line_token2,
    STATE(17), 2,
      sym_non_description_line,
      aux_sym_setup_section_repeat1,
  [279] = 1,
    ACTIONS(88), 4,
      anon_sym_POUND_POUND,
      anon_sym_POUND,
      aux_sym_code_line_token2,
      anon_sym_POUND_EQ_GT,
  [286] = 2,
    ACTIONS(90), 1,
      ts_builtin_sym_end,
    ACTIONS(92), 3,
      anon_sym_POUND_POUND,
      anon_sym_POUND,
      aux_sym_code_line_token2,
  [295] = 2,
    ACTIONS(43), 1,
      ts_builtin_sym_end,
    ACTIONS(45), 3,
      anon_sym_POUND_POUND,
      anon_sym_POUND,
      aux_sym_code_line_token2,
  [304] = 1,
    ACTIONS(94), 3,
      anon_sym_POUND_POUND,
      anon_sym_POUND,
      aux_sym_code_line_token2,
  [310] = 1,
    ACTIONS(96), 3,
      anon_sym_POUND_POUND,
      anon_sym_POUND,
      aux_sym_code_line_token2,
  [316] = 2,
    ACTIONS(98), 1,
      ts_builtin_sym_end,
    ACTIONS(96), 2,
      anon_sym_POUND,
      aux_sym_code_line_token2,
  [324] = 2,
    ACTIONS(100), 1,
      ts_builtin_sym_end,
    ACTIONS(94), 2,
      anon_sym_POUND,
      aux_sym_code_line_token2,
  [332] = 1,
    ACTIONS(102), 3,
      anon_sym_POUND,
      aux_sym_code_line_token2,
      anon_sym_POUND_EQ_GT,
  [338] = 1,
    ACTIONS(104), 3,
      anon_sym_POUND,
      aux_sym_code_line_token2,
      anon_sym_POUND_EQ_GT,
  [344] = 1,
    ACTIONS(106), 1,
      anon_sym_LF,
  [348] = 1,
    ACTIONS(15), 1,
      ts_builtin_sym_end,
  [352] = 1,
    ACTIONS(108), 1,
      anon_sym_LF,
  [356] = 1,
    ACTIONS(110), 1,
      aux_sym_code_line_token1,
  [360] = 1,
    ACTIONS(112), 1,
      aux_sym_description_line_token1,
  [364] = 1,
    ACTIONS(114), 1,
      anon_sym_LF,
  [368] = 1,
    ACTIONS(116), 1,
      ts_builtin_sym_end,
  [372] = 1,
    ACTIONS(118), 1,
      aux_sym_description_line_token1,
  [376] = 1,
    ACTIONS(120), 1,
      ts_builtin_sym_end,
  [380] = 1,
    ACTIONS(122), 1,
      anon_sym_LF,
  [384] = 1,
    ACTIONS(124), 1,
      anon_sym_LF,
  [388] = 1,
    ACTIONS(126), 1,
      aux_sym_code_line_token2,
  [392] = 1,
    ACTIONS(128), 1,
      anon_sym_LF,
  [396] = 1,
    ACTIONS(130), 1,
      anon_sym_LF,
  [400] = 1,
    ACTIONS(132), 1,
      anon_sym_LF,
  [404] = 1,
    ACTIONS(134), 1,
      aux_sym_code_line_token2,
};

static const uint32_t ts_small_parse_table_map[] = {
  [SMALL_STATE(2)] = 0,
  [SMALL_STATE(3)] = 28,
  [SMALL_STATE(4)] = 56,
  [SMALL_STATE(5)] = 81,
  [SMALL_STATE(6)] = 100,
  [SMALL_STATE(7)] = 119,
  [SMALL_STATE(8)] = 136,
  [SMALL_STATE(9)] = 155,
  [SMALL_STATE(10)] = 173,
  [SMALL_STATE(11)] = 184,
  [SMALL_STATE(12)] = 197,
  [SMALL_STATE(13)] = 209,
  [SMALL_STATE(14)] = 223,
  [SMALL_STATE(15)] = 237,
  [SMALL_STATE(16)] = 251,
  [SMALL_STATE(17)] = 265,
  [SMALL_STATE(18)] = 279,
  [SMALL_STATE(19)] = 286,
  [SMALL_STATE(20)] = 295,
  [SMALL_STATE(21)] = 304,
  [SMALL_STATE(22)] = 310,
  [SMALL_STATE(23)] = 316,
  [SMALL_STATE(24)] = 324,
  [SMALL_STATE(25)] = 332,
  [SMALL_STATE(26)] = 338,
  [SMALL_STATE(27)] = 344,
  [SMALL_STATE(28)] = 348,
  [SMALL_STATE(29)] = 352,
  [SMALL_STATE(30)] = 356,
  [SMALL_STATE(31)] = 360,
  [SMALL_STATE(32)] = 364,
  [SMALL_STATE(33)] = 368,
  [SMALL_STATE(34)] = 372,
  [SMALL_STATE(35)] = 376,
  [SMALL_STATE(36)] = 380,
  [SMALL_STATE(37)] = 384,
  [SMALL_STATE(38)] = 388,
  [SMALL_STATE(39)] = 392,
  [SMALL_STATE(40)] = 396,
  [SMALL_STATE(41)] = 400,
  [SMALL_STATE(42)] = 404,
};

static const TSParseActionEntry ts_parse_actions[] = {
  [0] = {.entry = {.count = 0, .reusable = false}},
  [1] = {.entry = {.count = 1, .reusable = false}}, RECOVER(),
  [3] = {.entry = {.count = 1, .reusable = false}}, SHIFT(34),
  [5] = {.entry = {.count = 1, .reusable = false}}, SHIFT(38),
  [7] = {.entry = {.count = 1, .reusable = false}}, SHIFT(27),
  [9] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 1, 0, 0),
  [11] = {.entry = {.count = 1, .reusable = false}}, SHIFT(42),
  [13] = {.entry = {.count = 1, .reusable = false}}, SHIFT(40),
  [15] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 2, 0, 0),
  [17] = {.entry = {.count = 1, .reusable = false}}, SHIFT(30),
  [19] = {.entry = {.count = 1, .reusable = false}}, SHIFT(32),
  [21] = {.entry = {.count = 1, .reusable = false}}, SHIFT(31),
  [23] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0),
  [25] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(34),
  [28] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0),
  [30] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_testcase, 2, 0, 0),
  [32] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_testcase, 2, 0, 0),
  [34] = {.entry = {.count = 1, .reusable = false}}, SHIFT(20),
  [36] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_testcase_repeat3, 2, 0, 0),
  [38] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_testcase_repeat3, 2, 0, 0),
  [40] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_testcase_repeat3, 2, 0, 0), SHIFT_REPEAT(31),
  [43] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_testcase, 3, 0, 0),
  [45] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_testcase, 3, 0, 0),
  [47] = {.entry = {.count = 1, .reusable = false}}, SHIFT(19),
  [49] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_expectation_line, 3, 0, 0),
  [51] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_expectation_line, 3, 0, 0),
  [53] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_testcase_repeat1, 2, 0, 0), SHIFT_REPEAT(34),
  [56] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_testcase_repeat1, 2, 0, 0),
  [58] = {.entry = {.count = 1, .reusable = true}}, SHIFT(34),
  [60] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_teardown_section, 1, 0, 0),
  [62] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_setup_section_repeat1, 2, 0, 0),
  [64] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_setup_section_repeat1, 2, 0, 0), SHIFT_REPEAT(38),
  [67] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_setup_section_repeat1, 2, 0, 0), SHIFT_REPEAT(27),
  [70] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_setup_section, 1, 0, 0),
  [72] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_testcase_repeat2, 2, 0, 0), SHIFT_REPEAT(30),
  [75] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_testcase_repeat2, 2, 0, 0), SHIFT_REPEAT(32),
  [78] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_testcase_repeat2, 2, 0, 0),
  [80] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_setup_section_repeat1, 2, 0, 0),
  [82] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_setup_section_repeat1, 2, 0, 0), SHIFT_REPEAT(42),
  [85] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_setup_section_repeat1, 2, 0, 0), SHIFT_REPEAT(40),
  [88] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_description_line, 3, 0, 0),
  [90] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_testcase, 4, 0, 0),
  [92] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_testcase, 4, 0, 0),
  [94] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_non_description_line, 2, 0, 0),
  [96] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_non_description_line, 3, 0, 0),
  [98] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_non_description_line, 3, 0, 0),
  [100] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_non_description_line, 2, 0, 0),
  [102] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_code_line, 2, 0, 0),
  [104] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_code_line, 3, 0, 0),
  [106] = {.entry = {.count = 1, .reusable = true}}, SHIFT(21),
  [108] = {.entry = {.count = 1, .reusable = true}}, SHIFT(22),
  [110] = {.entry = {.count = 1, .reusable = true}}, SHIFT(39),
  [112] = {.entry = {.count = 1, .reusable = true}}, SHIFT(36),
  [114] = {.entry = {.count = 1, .reusable = true}}, SHIFT(25),
  [116] = {.entry = {.count = 1, .reusable = true}},  ACCEPT_INPUT(),
  [118] = {.entry = {.count = 1, .reusable = true}}, SHIFT(37),
  [120] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 3, 0, 0),
  [122] = {.entry = {.count = 1, .reusable = true}}, SHIFT(10),
  [124] = {.entry = {.count = 1, .reusable = true}}, SHIFT(18),
  [126] = {.entry = {.count = 1, .reusable = true}}, SHIFT(29),
  [128] = {.entry = {.count = 1, .reusable = true}}, SHIFT(26),
  [130] = {.entry = {.count = 1, .reusable = true}}, SHIFT(24),
  [132] = {.entry = {.count = 1, .reusable = true}}, SHIFT(23),
  [134] = {.entry = {.count = 1, .reusable = true}}, SHIFT(41),
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
