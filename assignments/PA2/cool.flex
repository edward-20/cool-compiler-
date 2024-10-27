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

%x multi_line_comment one_line_comment string

MULTI_LINE_COMMENT_START "(*"
MULTI_LINE_COMMENT_END "*)"

SINGLE_LINE_COMMENT_START "--"

STRING_START "\""

DARROW          =>

%option noyywrap

















%%

  /* comments */
{MULTI_LINE_COMMENT_START} {BEGIN(multi_line_comment);}
<multi_line_comment>{MULTI_LINE_COMMENT_END} {BEGIN(INITIAL);}
<multi_line_comment>[^\*]* {}
  /* EOF in comment */
<multi_line_comment><<EOF>> {
  cool_yylval.error_msg = "EOF in comment";
  return ERROR;
}

{SINGLE_LINE_COMMENT_START} {BEGIN(one_line_comment);}
<one_line_comment>[\n] {BEGIN(INITIAL);}
<one_line_comment>.* {}

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

  /* keywords */
(?i:class) {return CLASS;}
(?i:else) {return ELSE;}
(?i:fi) {return FI;}
(?i:if) {return IF;}
(?i:in) {return IN;}
(?i:inherits) {return INHERITS;}
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
true {return BOOL_CONST;}
false {return BOOL_CONST;}


  /* Type identifiers */
[A-Z][^ \t\n]* {
  cool_yylval.symbol = idtable.add_string(yytext);
  return TYPEID;
}

  /* object identifiers */
[a-z][^ \t\n]* {
  cool_yylval.symbol = idtable.add_string(yytext);
  return OBJECTID;
}

  /* strings */
\" {
  BEGIN(string);
}

  /* requires terminating quotation */
<string>.*([^\\]\"|\n) {
  char *new_string = (char *)malloc((strlen(yytext) + 1) * sizeof(char));
  char *i = yytext;
  
  char *j = new_string;
  int len = 0;

  int error_found_thats_not_unescaped_newline_just_proceed_to_end_of_string = 0;
  
  while (*i != '\0') {
    if (error_found_thats_not_unescaped_newline_just_proceed_to_end_of_string == 1) {
      if (*i == '\n' || *i == '"') {
        BEGIN(INITIAL);
        return ERROR;
      }
      i++;
      continue;
    }

    if (*i == '"') {
      break;
    }
    
    if (len > 1024) {
      cool_yylval.error_msg = "String constant too long";
      error_found_thats_not_unescaped_newline_just_proceed_to_end_of_string = 1;
      i++;
      continue;
    }

    if (*i == '\n') {
      if (error_found_thats_not_unescaped_newline_just_proceed_to_end_of_string != 1) {
        cool_yylval.error_msg = "Unterminated string constant";
      }
      BEGIN(INITIAL);
      return ERROR;
    }
    
    if (*i == '\\') {
      i++;
      switch (*i) {
        case 'b':
          *j = '\b';
          break;
        case 't':
          *j = '\t';
          break;
        case 'n':
          *j = '\n';
          break;
        case 'f':
          *j = '\f';
          break;
        case '0':
          cool_yylval.error_msg = "String contains null character";
          error_found_thats_not_unescaped_newline_just_proceed_to_end_of_string = 1;
          i++;
          continue;
      }
    } else {
      *j = *i;
    }
    i++;
    j++;
    len++;
  }
  *j = '\0';
  cool_yylval.symbol = stringtable.add_string(new_string);
  BEGIN(INITIAL);
  return STR_CONST;
}
{DARROW}		{ return (DARROW); }




%%







