/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;
int len;
int string_error_encountered = 0;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

#define RETURN_ERROR(A) \
  cool_yylval.error_msg = yytext + A;\
  return ERROR

%}












/*
 * Define names for regular expressions here. And also start conditions
 */

%x multi_line_comment
%x one_line_comment 
%x string
%x class
%x class_type
%x class_type_inherits
%x class_signature
/* this condition means we've had * features defined before in the class definition */
%x class_feature
%x class_feature_needing_semicolon

%x feature_id
%x feature_id_colon
%x feature_id_colon_type
/* if we're in this state it means we've finished the expression and are now seeking the semicolon to transition to class_feature */
%x feature_id_colon_type_assign


%x feature_id_openingparen
%x formal
%x formal_id
%x formal_id_colon
%x formal_needing_comma
%x formal_with_comma
%x feature_id_formal_parameters
%x feature_id_formal_parameters_colon

%x function_body
%x function_body_openingbrace

%x expr
%x expr_assgn_id
%x expr_assgn_id_assign

%x expr_function_call
%x expr_function_call_openingparen

%x expr_if_clause_if
%x expr_if_clause_if_expr_then
%x expr_if_clause_if_expr_then_expr_else

MULTI_LINE_COMMENT_START "(*"
MULTI_LINE_COMMENT_END "*)"

SINGLE_LINE_COMMENT_START "--"

STRING_START "\""

TYPE_IDENTIFIER [A-Z][a-zA-Z0-9_]*
OBJECT_IDENTIFIER [a-z][a-zA-Z0-9_]*

%option noyywrap
%option stack

















%%
[\t ]* {};
\n {curr_lineno++;}
<INITIAL><<EOF>> {yyterminate();}
  
  /* comments */
{MULTI_LINE_COMMENT_START} {BEGIN(multi_line_comment);}
<multi_line_comment>{MULTI_LINE_COMMENT_END} {BEGIN(INITIAL);}
<multi_line_comment>. {}
<multi_line_comment>\n {curr_lineno++;}
<multi_line_comment><<EOF>> {
  cool_yylval.error_msg = "EOF in comment";
  BEGIN(INITIAL);
  return ERROR;
}

{SINGLE_LINE_COMMENT_START} {BEGIN(one_line_comment);}
<one_line_comment>\n {curr_lineno++; BEGIN(INITIAL);}
<one_line_comment>[^\n]* {}

  /* unmatched *) */
\*\) {
  cool_yylval.error_msg = "Unmatched *)";
  return ERROR;
}

  /* class */
(?i:class) {BEGIN(class); return CLASS;}

  /* class - type identifier */
<class>[ \t]* {}
<class>\n {curr_lineno++;}
<class>[^A-Z] { RETURN_ERROR(0);}
<class>[A-Z][^a-zA-Z_0-9]* {RETURN_ERROR(1);}
<class>{TYPE_IDENTIFIER} {
  cool_yylval.symbol = idtable.add_string(yytext);
  BEGIN(class_type);
  return TYPEID;
}

  /* type identifier - [ inherits | { ] */
<class_type>[ \t]* {}
<class_type>\n {curr_lineno++;}
<class_type>(?i:inherits) {
  BEGIN(class_type_inherits);
  return INHERITS;  
}
<class_type>\{ {
  BEGIN(class_feature);
  return '{';
}
  
  /* inherits - type identifier */
<class_type_inherits>[\t ]* {}
<class_type_inherits>\n {curr_lineno++;}
<class_type_inherits>[^A-Z] {RETURN_ERROR(0);}
<class_type_inherits>{TYPE_IDENTIFIER} {
  cool_yylval.symbol = idtable.add_string(yytext); // should be looking up
  BEGIN(class_signature);
  return TYPEID;
}
<class_type_inherits>[A-Z][^a-zA-Z_0-9]* {RETURN_ERROR(1);}

  /* class signature - open brace */
<class_signature>[\t ]* {}
<class_signature>\n {curr_lineno++;}
<class_signature>\{ {
  BEGIN(class_feature);
  return '{';
}
<class_signature>. {RETURN_ERROR(0);}

  /* class open brace - [ feature; ]* */
<class_feature>[\t ]* {}
<class_feature>\n {curr_lineno++;}
<class_feature>[^a-z] {RETURN_ERROR(0);}
<class_feature>{OBJECT_IDENTIFIER} {
  cool_yylval.symbol = idtable.add_string(yytext);
  BEGIN(feature_id);
  return OBJECTID;
}
<class_feature>[a-z][^a-zA-Z_0-9]* {RETURN_ERROR(1);}

  /* feature identifier - ( | : */
<feature_id>[\t ]* {}
<feature_id>\n {curr_lineno++;}
<feature_id>: {
  BEGIN(feature_id_colon);
  return ':';
}
<feature_id>\( {
  BEGIN(feature_id_openingparen);
  return '(';
}

  /* feature_id_colon - type annotation */
<feature_id_colon>[\t ]* {}
<feature_id_colon>\n {curr_lineno++;}
<feature_id_colon>[^A-Z] {
  RETURN_ERROR(0);
}
<feature_id_colon>{TYPE_IDENTIFIER} {
  // check if the type indeed exists
  cool_yylval.symbol = idtable.add_string(yytext); // should be looking up
  BEGIN(feature_id_colon_type);
  return TYPEID;
}
<feature_id_colon>\; {BEGIN(class_feature); return ';';}
<feature_id_colon>[A-Z][^a-zA-Z_0-9]* {
  RETURN_ERROR(1);
}

  /* feature_id_colon_type - assign */
<feature_id_colon_type>[\t ]* {}
<feature_id_colon_type>\n {curr_lineno++;}
<feature_id_colon_type>\<- {
  yy_push_state(feature_id_colon_type_assign);
  yy_push_state(expr);
  return ASSIGN;
}
<feature_id_colon_type>\; {BEGIN(class_feature); return ';';}
  
  /* feature_id_colon_type_assign (searching for semicolon to end class feature) */
<feature_id_colon_type_assign>[\t ]* {}
<feature_id_colon_type_assign>\n {curr_lineno++;}
<feature_id_colon_type_assign>\; {
  return ';';
  BEGIN(class_feature);
}

  /* feature_id_openingparen - formal parameters */
<feature_id_openingparen>[\t ]* {}
<feature_id_openingparen>\n {curr_lineno++;}
<feature_id_openingparen>\) {
  BEGIN(feature_id_formal_parameters);
  return ')';
}
<feature_id_openingparen>{OBJECT_IDENTIFIER} {
  cool_yylval.symbol = idtable.add_string(yytext);
  BEGIN(formal_id);
  return OBJECTID;
}
<feature_id_openingparen>[a-z][^a-zA-Z_0-9]* {
  RETURN_ERROR(1);
}

  /* formal_id - : */
<formal_id>[\t ]* {}
<formal_id>\n {curr_lineno++;}
<formal_id>: {
  BEGIN(formal_id_colon);
  return ':';
}
<formal_id>. {
  RETURN_ERROR(0);
}

  /* formal_id_colon - type identifier */
<formal_id_colon>[\t ]* {}
<formal_id_colon>\n {curr_lineno++;}
<formal_id_colon>{TYPE_IDENTIFIER} {
  cool_yylval.symbol = idtable.add_string(yytext); // should be looking up
  BEGIN(formal_needing_comma);
  return TYPEID;
}
<formal_id_colon>[A-Z][^A-Za-z0-9_]* {RETURN_ERROR(1);}

  /* formal_needing_comma */
<formal_needing_comma>[\t ]* {}
<formal_needing_comma>\n {curr_lineno++;}
<formal_needing_comma>, {
  BEGIN(formal_with_comma);
  return ',';
}
<formal_needing_comma>\) {
  BEGIN(feature_id_formal_parameters);
  return ')';
}
<formal_needing_comma>. {
  RETURN_ERROR(0);
}

  /* formal with comma - type identifier*/
<formal_with_comma>[\t ]* {}
<formal_with_comma>\n {curr_lineno++;}
<formal_with_comma>{TYPE_IDENTIFIER} {
  cool_yylval.symbol = idtable.add_string(yytext); // should be looking up
  BEGIN(formal_with_comma);
  return TYPEID;
}
<formal_with_comma>[^A-Z] {RETURN_ERROR(0);}

<feature_id_formal_parameters>[\t ]* {}
<feature_id_formal_parameters>\n {curr_lineno++;}
<feature_id_formal_parameters>: {
  BEGIN(feature_id_formal_parameters_colon);
  return ':';
}
<feature_id_formal_parameters>. {
  RETURN_ERROR(0);
}

<feature_id_formal_parameters_colon>[\t ]* {}
<feature_id_formal_parameters_colon>\n {curr_lineno++;}
<feature_id_formal_parameters_colon>{TYPE_IDENTIFIER} {
  cool_yylval.symbol = idtable.add_string(yytext); // should be looking up
  BEGIN(function_body);
  return TYPEID;
}
<feature_id_formal_parameters_colon>[A-Z][^A-Za-z0-9_]* {
  RETURN_ERROR(1);
}

<function_body>[\t ]* {}
<function_body>\n {curr_lineno++;}
<function_body>\{ {
  yy_push_state(function_body_openingbrace);
  yy_push_state(expr);
  return '{';
}
<function_body>. {RETURN_ERROR(0);}

  /* the only time this start condition occurs is when the expr in the function body has happened */
<function_body_openingbrace>[\t ]* {}
<function_body_openingbrace>\n {curr_lineno++;}
<function_body_openingbrace>\} {BEGIN(class_feature_needing_semicolon); return '}';}
<function_body_openingbrace>. {RETURN_ERROR(0);}

<class_feature_needing_semicolon>[\t ]* {}
<class_feature_needing_semicolon>\n {curr_lineno++;}
<class_feature_needing_semicolon>\; {BEGIN(class_feature); return ';';}

  /* handle expression */
<expr>[\t ]* {}
<expr>\n {curr_lineno++;}

  /* assignment expression */
<expr>{OBJECT_IDENTIFIER}/([\t ]|\n)*\<- {
  BEGIN(expr_assgn_id);
  cool_yylval.symbol = idtable.add_string(yytext);
  return OBJECTID;
}
<expr_assgn_id>[\t ]* {}
<expr_assgn_id>\n {curr_lineno++;}
<expr_assgn_id>\<- {yy_push_state(expr_assgn_id_assign); yy_push_state(expr); return ASSIGN;}
<expr_assgn_id_assign>


  /* function call expression */
<expr>{OBJECT_IDENTIFIER}/([\t ]|\n)*\( {
  BEGIN(expr_function_call);
  cool_yylval.symbol = idtable.add_string(yytext);
  return OBJECTID;
}
<expr_function_call>[\t ]* {}
<expr_function_call>\n {curr_lineno++;}
<expr_function_call>\( {
  BEGIN(expr_function_call_openingparen)
  return '(';
}
<expr_function_call_openingparen>

  /* dispatch */
<expr>{OBJECT_IDENTIFIER} {
  yy_pop_state();
  RETURN OBJECTID;
}

  /* if then else */
<expr>(?i:if) {
  BEGIN(expr_if_clause_if);
  yy_push_state(expr);
  return IF;
}
<expr_if_clause_if>[\t ]* {}
<expr_if_clause_if>\n {curr_lineno++;}
<expr_if_clase>(?:then) {
  BEGIN(expr_if_clause_if_expr_then);
  yy_push_state(expr);
  return THEN;
}
<expr_if_clause_if_expr_then>(?i:else) {
  BEGIN(expr_if_clause_if_expr_then_expr_else);
  yy_push_state(expr);
  return ELSE;
}




(?i:else) {return ELSE;}
(?i:fi) {return FI;}
(?i:if) {return IF;}
(?i:in) {return IN;}
(?i:let) {return LET;}
(?i:loop) {return LOOP;}
(?i:pool) {return POOL;}
(?i:then) {return THEN;}
(?i:while) {return WHILE;}
(?i:case) {return CASE;}
(?i:esac) {return ESAC;}
(?i:new) {return NEW;}
(?i:of) {return OF;}
(?i:not) {return NOT;}

  /* key characters */
true {cool_yylval.boolean = 1; return BOOL_CONST;}
false {cool_yylval.boolean = 0; return BOOL_CONST;}

  /* strings */
\" {
  BEGIN(string);
  // clear the initialisation of string capturing variables
  string_buf[0] = '\0';
  string_buf_ptr = string_buf;
  len = 0;
  string_error_encountered = 0;
}

  /* escaped character; not escaped newline */
<string>\\. {
  // if an error has already been encountered
  if (string_error_encountered) {
    // do nothing because the end of the string will not happen at an escaped character
  } 
  else if (len == 1024) {
    cool_yylval.error_msg = "String constant too long";
    string_error_encountered = 1; // resume lexing at end of string
  } 
  else {
    switch (yytext[1]) {
      case 'b': 
        *string_buf_ptr = '\b';
        break;
      case 't': 
        *string_buf_ptr = '\t';
        break;
      case 'n': 
        *string_buf_ptr = '\n';
        break;
      case 'f': 
        *string_buf_ptr = '\f';
        break;
      case '0':
        *string_buf_ptr = '\0';
        break;
      default:
        *string_buf_ptr = yytext[1];
    }
    string_buf_ptr++;
    len++;
  }
}

  /* escaped newline */
<string>\\\n {
  if (string_error_encountered == 0) {
    *string_buf_ptr = yytext[1];
    string_buf_ptr++;
    len++;
  } 
  curr_lineno++; // keep track of the end of the error string regardless
}

  /* invalid null character */
<string>\0 {
  if (string_error_encountered == 0) {
    cool_yylval.error_msg = "String contains null character";
    string_error_encountered = 1;
  }
  // resume lexing at end of string
}

  /* EOF in string */
<string><<EOF>> {
  if (string_error_encountered == 0) {
    cool_yylval.error_msg = "String contains EOF character";
  }
  BEGIN(INITIAL);
  return ERROR; 
}

  /* unescaped character */
<string>. {
  // error before and now we're prepared to end the string if this is the right character
  if (string_error_encountered && yytext[0] == '"') {
    BEGIN(INITIAL);
    return ERROR;
  }
  else {
    switch (yytext[0]) {
      case '"':
        // handle ending of string
        *string_buf_ptr = '\0';
        cool_yylval.symbol = stringtable.add_string(string_buf);
        BEGIN(INITIAL);
        return STR_CONST;
      default:
        if (len == 1024) {
          cool_yylval.error_msg = "String constant too long"; 
          string_error_encountered = 1;
          // resume lexing after the end of the string
        } else {
          *string_buf_ptr = yytext[0];
          string_buf_ptr++;
          len++;
        }
    }
  }
}

  /* unescaped newline */
<string>\n {
  if (string_error_encountered == 0) {
    cool_yylval.error_msg = "Unterminated string constant";
  }
  curr_lineno++;
  BEGIN(INITIAL);
  return ERROR;
}

%%







