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

%}












/*
 * Define names for regular expressions here. And also start conditions
 */

%x multi_line_comment one_line_comment 
%x string
%x class
%x type_declared
%x inherits
%x class_signature
%x class_open_brace

%x feature_id
%x feature_id_colon
%x feature_id_colon_type
%x feature_id_colon_type_assign

%x feature_id_openingparen
%x formal_id
%x formal_id_colon
%x formal_needing_comma

MULTI_LINE_COMMENT_START "(*"
MULTI_LINE_COMMENT_END "*)"

SINGLE_LINE_COMMENT_START "--"

STRING_START "\""

TYPE_IDENTIFIER [A-Z]([:alnum]|_)*
TYPE_IDENTIFIER [A-Z]([:alnum]|_)*
OBJECT_IDENTIFIER [a-z]([:alnum]|_)*

DARROW          =>

%option noyywrap

















%%
[\t ]* {};
\n {curr_lineno++;}
  
  /* comments */
{MULTI_LINE_COMMENT_START} {BEGIN(multi_line_comment);}
<multi_line_comment>{MULTI_LINE_COMMENT_END} {BEGIN(INITIAL);}
<multi_line_comment>. {}
<multi_line_comment>\n {curr_lineno++;}
  /* EOF in comment */
<multi_line_comment><<EOF>> {
  cool_yylval.error_msg = "EOF in comment";
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

  /* integers */
[0-9]+ {
  cool_yylval.symbol = inttable.add_string(yytext);
  return INT_CONST;
}

  /* class */
(?i:class) {BEGIN(class); return CLASS;}

  /* class - type identifier */
<class>[ \t]* {}
<class>\n {curr_lineno++;}
<class>[^A-Z] {
  cool_yylval.error_msg = yytext; // invalid character
  return ERROR;
}
<class>TYPE_IDENTIFIER {
  cool_yylval.symbol = idtable.add_string(yytext);
  BEGIN(type_declared);
  return TYPEID;
}
<class>[A-Z][^a-zA-Z_0-9]* {
  cool_yylval.error_msg = yytext + 1; // invalid character (string)
  return ERROR; 
}

  /* type identifier - [ inherits | { ] */
<type_declared>[ \t]* {}
<type_declared>\n {curr_lineno++;}
<type_declared>inherits {
  BEGIN(inherits);
  return INHERITS;  
}
<type_declared>\{ {
  BEGIN(class_open_brace);
  return '{';
}
  
  /* inherits - type identifier */
<inherits>[\t ]* {}
<inherits>\n {curr_lineno++;}
<inherits>[^A-Z] {
  cool_yylval.error_msg = yytext; // invalid character
  return ERROR;
}
<inherits>TYPE_IDENTIFIER {
  // check if the parent class indeed exists
  if ((elem = idtable.lookup_string(yytext)) != NULL) {
    cool_yylval.symbol = elem;
  } else {
    cool_yylval.symbol = idtable.add_string(yytext); // is it the lexer's job to determine if there
    // exists that parent class? does having multiple files prevent lexer from
    // accurately deciding on this?
  }
  BEGIN(class_signature);
  return TYPEID;
}
<inherits>[A-Z][^a-zA-Z_0-9]* {
  cool_yylval.error_msg = yytext + 1; // invalid substring
  return ERROR; 
}

  /* class signature - open brace */
<class_signature>[\t ]* {}
<class_signature>\n {curr_lineno++;}
<class_signature>\{ {
  BEGIN(class_open_brace);
  return '{';
}
<class_signature>. {
  cool_yylval.error_msg = yytext; // invalid character
  return ERROR;
}

  /* class open brace - [ feature; ]* */
<class_open_brace>[\t ]* {}
<class_open_brace>\n {curr_lineno++;}
<class_open_brace>[^A-Z] {
  cool_yylval.error_msg = yytext; // invalid character
}
<class_open_brace>OBJECT_IDENTIFIER {
  cool_yylval.symbol = idtable.add_string(yytext);
  BEGIN(feature_id);
}
<class_open_brace>[a-z][^a-zA-Z_0-9]* {
  cool_yylval.error_msg = yytext + 1; // invalid character (substring)
  return ERROR; 
}

  /* feature identifier - ( | : */
<feature_id>[\t ]* {}
<feature_id>\n {curr_lineno++;}
<feature_id>: {
  BEGIN(feature_id_colon);
  return ':';
}
<feature_id>\{ {
  BEGIN(feature_id_openingparen);
  return '(';
}

  /* feature_id_colon - type annotation */
<feature_id_colon>[\t ]* {}
<feature_id>\n {curr_lineno++;}
<feature_id>[^A-Z] {
  cool_yylval.error_msg = yytext;
  return ERROR;
}
<feature_id_colon>TYPE_IDENTIFIER {
  // check if the type indeed exists
  if ((elem = idtable.lookup_string(yytext)) != NULL) {
    cool_yylval.symbol = elem;
  } else {
    cool_yylval.symbol = idtable.add_string(yytext); // is it the lexer's job to determine if there
    // exists that type? does having multiple files prevent lexer from
    // accurately deciding on this?
  }
  BEGIN(feature_id_colon_type)
  return TYPEID;
}
<feature_id_colon>[A-Z][^a-zA-Z_0-9]* {
  cool_yylval.error_msg = yytext + 1;
  return ERROR;
}

  /* feature_id_colon_type - assign */
<feature_id_colon_type>[\t ]* {}
<feature_id_colon_type>\n {curr_lineno++}
<feature_id_colon_type>\<- {
  BEGIN(feature_id_colon_type_assign)
  return ASSIGN;
}
<feature_id_colon_type>[^\<] {
  cool_yylval.error_msg = yytext;
  return ERROR;
}

  /* feature_id_colon_type_assign - expression */
<feature_id_colon_type_assign>. {
  BEGIN(INITIAL); // stub for now, will complete expressions later
}

  /* feature_id_openingparen - formal parameters */
<feature_id_openingparen>[\t ]* {}
<feature_id_openingparen>\n {curr_lineno++;}
<feature_id_openingparen>\) {
  return EXPR;
}
<feature_id_openingparen>OBJECT_IDENTIFIER {
  if (elem = idtable.lookup_string(yytext) != NULL) {
    cool_yylval.symbol = elem;
  } else {
    cool_yylval.symbol = idtable.add_string(yytext); // is it the lexer's job to determine if there
    // are distinct formal parameters for a method?
  }
  BEGIN(formal_id);
  return OBJECTID;
}
<feature_id_openingparen>[a-z][^a-zA-Z_0-9]* {
  cool_yylval.error_msg = yytext + 1;  
  return ERROR;
}

  /* formal_id - : */
<formal_id>[\t ]* {}
<formal_id>\n {curr_lineno++;}
<formal_id>: {
  BEGIN(formal_id_colon);
  return ':';
}
<formal_id>. {
  cool_yylval.error_msg = yytext;
  return ERROR;
}

  /* formal_id_colon - type identifier */
<formal_id_colon>[\t ]* {}
<formal_id_colon>\n {curr_lineno++;}
<formal_id_colon>TYPE_IDENTIFIER {
  if (elem = idtable.lookup_string(yytext) != NULL) {
    cool_yylval.symbol = elem;
  } else {
    cool_yylval.symbol = idtable.add_string(yytext); // is it the lexer's job to determine if there
    // are distinct formal parameters for a method?
  }
  BEGIN(formal_needing_comma);
  return TYPEID;
}

  /* formal_needing_comma */
<formal_needing_comma>[\t ]* {}
<formal_needing_comma>\n {curr_lineno++;}
<formal_needing_comma>, {
  BEGIN(feature_id_openingparen);
  return ',';
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







