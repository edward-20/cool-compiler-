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

%x multi_line_comment one_line_comment string

MULTI_LINE_COMMENT_START "(*"
MULTI_LINE_COMMENT_END "*)"

SINGLE_LINE_COMMENT_START "--"

STRING_START "\""

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
true {cool_yylval.boolean = 1; return BOOL_CONST;}
false {cool_yylval.boolean = 0; return BOOL_CONST;}


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
  // clear the initialisation of string capturing variables
  string_buf[0] = '\0';
  string_buf_ptr = string_buf;
  len = 0;
  string_error_encountered = 0;
}

  /* escaped character; so two characters */
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
  // TODO: handle the case in which we've had an error
  if (string_error_encountered) {
    {BEGIN(INITIAL);return ERROR;}
  }
  *string_buf_ptr = yytext[1];
  string_buf_ptr++;
  len++;
  curr_lineno++;
}

  /* unescaped character */
<string>. {
  // error before and now we're ending the string 
  if (string_error_encountered) {
    if (yytext[0] == '\n' || yytext[0] == '"') {BEGIN(INITIAL);return ERROR;}
  }
  else if (len == 1024) {
    cool_yylval.error_msg = "String constant too long";
    string_error_encountered = 1;
    // resume lexing after the end of the string
  } else {
    switch (yytext[0]) {
      case '"':
        // handle ending of string
        *string_buf_ptr = '\0';
        cool_yylval.symbol = stringtable.add_string(string_buf);
        BEGIN(INITIAL);
        return STR_CONST;
      default:
        *string_buf_ptr = yytext[0];
    }
    string_buf_ptr++;
    len++;
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

{DARROW}		{ return (DARROW); }




%%







