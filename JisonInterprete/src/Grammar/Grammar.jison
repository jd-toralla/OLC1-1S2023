%{
 /* Declaraciones y importaciones JS*/
    
    // const {errores} = require('./Errores');
    const {Type} = require('../Symbol/Type');
    
    //Expressions
    const {Literal} = require('../Expression/Literal');
    const {Access} = require('../Expression/Access');
    const {Arithmetic,ArithmeticOption} = require('../Expression/Arithmetic');

    //Instructions
    const {Declaration} = require('../Instruction/Declaration');
    const {Print} = require('../Instruction/Print');
    const {Assignment} = require('../Instruction/Assignment');
    const {Statement} = require('../Instruction/Statement');

%}



//Innit Lexical Analysis
%lex
%options case-insensitive


//Regular Expressions
number [0-9]+
decimal ([0-9]+)"."([0-9]+)
string  (\"(\\.|[^\\"])*\")
char  (\'[^']\')
bool "true"| "false"
id ([a-zA-Z_])[a-zA-Z0-9_ñÑ]*

%%
\s+                   /* skip whitespace */
"//".*                // comment a line
[/][*][^*]*[*]+([^/*][^*]*[*]+)*[/] // comment multiple lines


{decimal}               return 'DECIMAL'
{number}                return 'NUMBER'
{string}                return 'STRING'
{bool}                  return 'BOOL'
{char}                  return 'CHAR'

"*"                     return '*'
"/"                     return '/'
";"                     return ';'
":"                     return ':'
"."                     return '.'
","                     return ','
"--"                    return '--'
"-"                     return '-'
"++"                    return '++'
"+"                     return '+'
"%"                     return '%'
"^"                     return '^'

"="                     return '='

"("                     return '('
")"                     return ')' 
"{"                     return '{'
"}"                     return '}'
"["                     return '['
"]"                     return ']'


//Regular Expressions
"int"                   return "INT"
"double"                return "DOUBLE"
"char"                  return "CHAR"
"boolean"               return "BOOLEAN"
"string"                return "STRING"


"println"               return 'PRINTLN'
"print"                 return 'PRINT'

{id}	                return 'ID';


<<EOF>>		            return 'EOF'

.                       {  
    console.log({ line: yylloc.first_line, column: yylloc.first_column+1, type: 'Lexico', message: `Error léxico, caracter '${yytext}' no esperado.`})
}

/lex /* End lexical analysis */

//Carrier Priority
%left '||'
%left '&&'
%left '^'
%left '==', '!='
%left '>=', '<=', '<', '>'
%left '+' '-'
%left '*' '/','%'
%left '!'
%left '.' '[' ']'
%left '++' '--'
%left '?' ':'

%start Init

%%

Init    
    : Instructions EOF 
    {
        return $1;
    } 
;


Instructions
    : Instructions Instruction
     {
        $1.push($2); 
        $$ = $1;
    }
    | Instruction{   $$ = [$1]; }
;

Instruction
    :Declaration   { 
        $$ = $1
    }
    | Statement     { $$ = $1 } //Sentencia
    | Assignment  ';' { $$ = $1 }
    | Print ';' { $$ = $1 }
    | error  {  
        console.log({ line: this._$.first_line, column: this._$.first_column, type: 'Sintáctico', message: `Error sintáctico, token no esperado '${yytext}' .`})
    }
;



Declaration
    : DataType ID '=' Expr ';' 
    { 
        $$ = new Declaration($1, $2, $4 , @1.first_line, @1.first_column); 
    }
;



Assignment
    : ID '=' Expr 
    {

        $$ = new Assignment($1, $3, @1.first_line, @1.first_column)
    }
    | AccessList '=' Expr 
    {
        $$ = new AssignmentStruct($1, $3);
    }
;


Print 
    : 'PRINTLN' '(' Expr ')'
    {
        $$ = new Print(true, $3, @1.first_line, @1.first_column);
    }
    | 'PRINT' '(' Expr ')'
    {
        $$ = new Print(false, $3, @1.first_line, @1.first_column);
    }
;

//Bloque de instrucciones pueden
Statement
    : '{' Instructions '}' 
    {
        $$ = new Statement($2, @1.first_line, @1.first_column);
    }
    | '{' '}' {
        $$ = new Statement(new Array(), @1.first_line, @1.first_column);
    }
;


DataType
    : 'INT'     { $$ = 0; }
    | 'DOUBLE'  { $$ = 1; }
    | 'CHAR'    { $$ = 2; }
    | 'STRING'  { $$ = 3; }
    | 'BOOLEAN' { $$ = 4; }
;

Expr
    : Expr '+' Expr     { $$ = new Arithmetic($1, $3, ArithmeticOption.PLUS, @1.first_line, @1.first_column ) }
    | Expr '-' Expr     { $$ = new Arithmetic($1, $3, ArithmeticOption.MINUS, @1.first_line, @1.first_column ) }
    | Expr '*' Expr     { $$ = new Arithmetic($1, $3, ArithmeticOption.TIMES, @1.first_line, @1.first_column ) }
    | Expr '*''*' Expr  { $$ = new Arithmetic($1, $4, ArithmeticOption.POT, @1.first_line, @1.first_column ) }
    | Expr '/' Expr     { $$ = new Arithmetic($1, $3, ArithmeticOption.DIV, @1.first_line, @1.first_column ) }
    | Expr '%' Expr     { $$ = new Arithmetic($1, $3, ArithmeticOption.MODULE, @1.first_line, @1.first_column ) }
    | '-' F             { $$ = new Literal($2, Type.NEGATIVE, @1.first_line, @1.first_column) }
    | F                 { $$ = $1; }
;


F :  '(' Expr ')' 
    { 
        $$ = $2
    }
    | DECIMAL   { 
        $$ = new Literal($1, Type.DECIMAL, @1.first_line, @1.first_column) }
    | NUMBER    { 
        $$ = new Literal($1, Type.NUMBER, @1.first_line, @1.first_column) }
    | STRING    { 
        $$ = new Literal($1, Type.STRING, @1.first_line, @1.first_column) }
    | BOOL      { 
        $$ = new Literal($1, Type.BOOLEAN, @1.first_line, @1.first_column) }
    | CHAR      { 
        $$ = new Literal($1, Type.CHAR, @1.first_line, @1.first_column) }
    | ID        { 
        $$ = new Access($1, null, @1.first_line, @1.first_column); }
;
