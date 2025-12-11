start: statement+

statement: (_CFLAGS | _AFLAGS | _build_dep | conditional_flag_assignment | conditional_assignment | conditional_block | assignment |ifdef_stmt| ifndef_stmt)? _NEWLINE?

assignment: NAME ("+" | ":")? "=" object_list

conditional_assignment: NAME _var ("+=" | "=") object_list
conditional_flag_assignment: /[a-zA-Z0-9]+/ "-flags-$(" CONFIG_OPTION ")" ("+=" | ":=") flag_list

conditional_block: ("ifeq" | "ifneq") "(" cond_arg (COMMA cond_arg)? RPAR NEWLINE statement* ("else" NEWLINE statement*)? "endif"
_else_stmt: "else" /.+/ _NEWLINE statement+ 

ifdef_stmt: "ifdef" CONFIG_OPTION _NEWLINE statement+ "endif" _NEWLINE
ifndef_stmt: "ifndef" CONFIG_OPTION _NEWLINE statement+ "endif" _NEWLINE

conditional_statements: (conditional_assignment | assignment)+

_CFLAGS: "CFLAGS" /.+/ /\\n/+
_AFLAGS: "AFLAGS" /.+/ /\\n/+

_build_dep: ("$(@obj)/") /.+/ | ("quiet_"? "cmd_bflags" /.+/) | ("$(call "/[a-z_,-]+/")")

object_list: (OBJECT | VAR_REF | WORD)+
flag_list: (FLAGS | OBJECT)+
cond_arg: (VAR_REF | WORD)*

_var:"$(" (CONFIG_OPTION|_func_subst) ")"

_func_subst:"subst" _PARAMS _var
_PARAMS: /\\w+,\\w+/

FLAGS: /[A-Za-z0-9_\-]+/
CONFIG_OPTION: /[A-Za-z0-9_]+/
NAME: "$(@obj)"? /[A-Za-z0-9_\-]+(\.[oah])?/
OBJECT: "$(@obj)/"? /[A-Za-z0-9_.-]+((\.[oah])|\/)?/
VAR_REF: /\$\([^)]+\)/
WORD: /[^ \t#\n(),]+/
COMMA: ","
RPAR: ")"

%import common.NEWLINE
_NEWLINE: NEWLINE

%ignore " " | "\t"
%ignore /#.*\n/
%ignore "\\\n"
%ignore "\\\r\n"

%ignore "$(PERL)" /.+/ "\n"

