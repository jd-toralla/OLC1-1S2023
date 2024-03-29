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
    
    const {TypeIns} = require('../Instruction/Function');
    const {Function} = require('../Instruction/Function');
    const {Call} = require('../Instruction/Call');
    const {Params} = require('../Instruction/Params');

    const {ToLowerUpper} = require('../Expression/ToLowerUpper');
    const {Round} = require('../Expression/Round');

   const {NewVector} = require('../Expression/NewVector');
   const {AccessVector} = require('../Expression/AccessVector');
   const {AssignmentStruct} = require('../Instruction/AssignmentStruct');

    let arreglo_ = []
    let contador_arreglo_ = 0;

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

//Method and function
"void"                  return 'VOID'
"call"                  return 'CALL'
"return"                return "RETURN"

//Native functions
"toUpper"               return "TOUPPER"
"toLower"               return "TOLOWER"
"round"                 return "ROUND"
"new"                   return "NEW"

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
    : VoidIns       { $$ = $1 }
    | FunctionIns   { $$ = $1 }   
    | Declaration   { 
        contador_arreglo_++;
        $$ = $1 
    }
    | Statement     { $$ = $1 } //Sentencia
    | Assignment  ';' { $$ = $1 }
    | Print ';' { $$ = $1 }
    | Call  ';'         { $$=$1 }
    | error  {  
        console.log({ line: this._$.first_line, column: this._$.first_column, type: 'Sintáctico', message: `Error sintáctico, token no esperado '${yytext}' .`})
    }
;



Declaration
    : DataType ID '=' Expr ';' 
    { 

        //AST
        let arreglo_temp = [{ label: Type[$2], hijos: null }, { label: $3, hijos: null }]
        if($1){ arreglo_temp.push({ label: 'const', hijos: null }) }
        arreglo_.push( { label: 'Declaration', hijos: [arreglo_[contador_arreglo_]].concat(arreglo_temp) } )
        arreglo_.splice(contador_arreglo_,1)


        $$ = new Declaration($1, $2, $4 , @1.first_line, @1.first_column); 
    }
    | DataType '[' ']' ID '=' SimpleVector ';' 
    {
        $$ = new Declaration($1, $4, $6 ,@1.first_line, @1.first_column); 
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
    | F                 { 
        arreglo_.push( { label: 'F', hijos: [arreglo_[contador_arreglo_]] } )
        arreglo_.splice(contador_arreglo_,1)

        $$ = $1; }
    | ToLowerUpperExp   { $$ = $1; }
    | RoundExp          { $$ = $1; }
    | '[' ListaExpr ']' { $$ = new NewVector(1, null, $2, @1.first_line, @1.first_column); }
    | Expr '[' Expr ']' { $$ = new AccessVector($1, $3, @1.first_line, @1.first_column);}
;


F :  '(' Expr ')' 
    { 
        $$ = $2
    }
    | DECIMAL   { 
        arreglo_.push( { label: `${$1}`, hijos: null } )
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

VoidIns
    : 'VOID' ID '(' ')' Statement
    {
        $$ = new Function(Type.NULL, TypeIns.VOID, $2, $5, [], @1.first_line, @1.first_column);
    }
    | 'VOID' ID '(' Params ')' Statement
    {
        $$ = new Function(Type.NULL, TypeIns.VOID, $2, $6, $4, @1.first_line, @1.first_column);  
    }
;

FunctionIns
    : Const DataType ID '(' ')' Statement
    {
        $$ = new Function($2, TypeIns.FUNCTION, $3, $6, [], @1.first_line, @1.first_column);
    }
    | Const DataType ID '(' Params ')' Statement
    {
        $$ = new Function($2, TypeIns.FUNCTION, $3, $7, $5, @1.first_line, @1.first_column);
    }
;


Call
    : 'CALL' ID '(' ')'
    {
        $$ = new Call($2, [], @1.first_line, @1.first_column);
    }
    | 'CALL' ID '(' ListaExpr ')'
    {
        $$ = new Call($2, $4, @1.first_line, @1.first_column);
    }
;

ListaExpr 
    : ListaExpr ',' Expr {
        $1.push($3);
        $$ = $1;
    }
    | Expr {
        $$ = [$1];
    }
;    

Params
    : Params ',' Param {
        $1.push($3);
        $$ = $1;
    }
    | Param
    {
        $$ = [$1];
    }
;

Param
    : DataType ID
    {
        $$ = new Params($1,$2, @1.first_line, @1.first_column)
    }
;


ToLowerUpperExp
    : 'TOLOWER' '(' Expr ')'
    {
        $$ = new ToLowerUpper($3,1,@1.first_line, @1.first_column);
        
    }
    | 'TOUPPER' '(' Expr ')'
    {
        $$ = new ToLowerUpper($3,2,@1.first_line, @1.first_column);
    }
; 

RoundExp
    : 'ROUND' '(' Expr ')'
    {
        $$ = new Round($3,@1.first_line, @1.first_column);
    }
;


SimpleVector 
    :'NEW' DataType '[' ListaExpr ']' 
    { 
        $$ = new NewVector (2,  $2, $4, @1.first_line, @1.first_column);  
    }
    | Expr                          
    { 
        $$ = $1 
    }
;

AccessList
    : AccessList '[' Expr ']' {
        $1.push($3);
        $$ = $1;
    }
    | ID '[' Expr ']' {
        $$ = [$1, $3];
    }
;