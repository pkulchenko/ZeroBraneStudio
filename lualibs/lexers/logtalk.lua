-- Copyright © 2017-2018 Michael T. Richter <ttmrichter@gmail.com>. See License.txt.
-- Logtalk LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('logtalk', {inherit = lexer.load('prolog')})

lex:modify_rule('keyword', token(lexer.KEYWORD, word_match[[
  -- Logtalk "keywords" generated from Vim syntax highlighting file with Prolog
  -- keywords stripped since were building up on the Prolog lexer.
  abolish_category abolish_events abolish_object abolish_protocol after alias as
  before built_in calls category category_property coinductive complements
  complements_object conforms_to_protocol create create_category create_object
  create_protocol create_logtalk_flag current current_category current_event
  current_logtalk_flag current_object current_protocol define_events encoding
  end_category end_class end_object end_protocol extends extends_category
  extends_object extends_protocol forward implements implements_protocol imports
  imports_category include info instantiates instantiates_class is
  logtalk_compile logtalk_library_path logtalk_load logtalk_load_context
  logtalk_make meta_non_terminal mode object object_property parameter private
  protected protocol_property self sender set_logtalk_flag specializes
  specializes_class synchronized this threaded threaded_call threaded_engine
  threaded_engine_create threaded_engine_destroy threaded_engine_fetch
  threaded_engine_next threaded_engine_next_reified threaded_engine_post
  threaded_engine_self threaded_engine_yield threaded_exit threaded_ignore
  threaded_notify threaded_once threaded_peek threaded_wait uses
  -- info/1 and info/2 predicates have their own keywords manually extracted
  -- from documentation.
  comment argnames arguments author version date parameters parnames copyright
  license remarks see_also
]]) + lex:get_rule('keyword'))

return lex
