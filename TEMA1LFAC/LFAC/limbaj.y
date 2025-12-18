%code requires {
    #include <string>
    #include <vector>
    using namespace std;
}

%{
#include <iostream>
#include <string>
#include <stdio.h>
#include "SymTable.h" 
#include <vector>

using namespace std;
extern FILE* yyin;
extern char* yytext;
extern int yylineno;
extern int yylex();
void yyerror(const char * s);

int errorCount = 0;
%}

%union {
    int Int;
    float Float;
    char* Str;
    std::string* Id;
    bool BoolVal;
}

%token <Int> NR_INT
%token <Float> NR_FLOAT
%token <Str> STRING_VAL
%token <Id> ID TYPE
%token <BoolVal> BOOL_VAL

%token CLASS FUNCTION RETURN IF WHILE PRINT NEW BGIN END
%token PUBLIC PRIVATE PROTECTED FOR ELSE
%token ASSIGN
%token TRUE FALSE

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%left OR
%left AND
%left EQ NEQ
%left LT GT LE GE
%left '+' '-'
%left '*' '/' '%'
%left NOT
%left '.'
%right UMINUS 

%start progr

%%

progr 
    : global_definitions main_block 
      { 
        if (errorCount == 0) cout << "Program corect sintactic!" << endl; 
      }
    ;

global_definitions
    : /* empty */
    | global_definitions decl_var
    | global_definitions class_def
    | global_definitions func_def
    ;

decl_var
    : TYPE vars ';'{
        for(auto id : *$2) {
            if(!symTable->addVariable(id, *$1, yylineno)){
                yyerror(("Variable " + id + " already declared").c_str());
            }
        }
    }
    | ID ID ';'{
        if(!symTable->classExists(*$1) && !symTable->isPrimitive(*$1)){
            yyerror(("Type " + *$1 + " not declared").c_str());
        }
        if(!symTable->addVariable(*$2, *$1 , yylineno)){
            yyerror(("Variable " + *$2 + " already declared").c_str());
        }
    }
    | TYPE ID ASSIGN expr ';'{
        string left_type = *$1;  
        if(lhsType != $3) {
            yyerror(("Type mismatch: cannot assign " + $3 + " to " + lhsType).c_str());
        }   
    }
    | ID ID ASSIGN expr ';'{
        if(!symTable->classExists(*$1) && !symTable->isPrimitive(*$1)){
            yyerror(("Type " + *$1 + " not declared").c_str());
        }
        if(!symTable->addVariable(*$2, *$1 , yylineno)){
            yyerror(("Variable " + *$2 + " already declared").c_str());
        }
    }
    ;
vars:
    vars ',' ID
    |ID
    ;
class_def
    : CLASS ID BGIN class_body END
    ;

class_body
    : /* empty */
    | class_body access_modifier members_definition
    ;

access_modifier
    : PUBLIC | PRIVATE | PROTECTED
    ;

members_definition
    : members_definition decl_var               
    | members_definition func_def       
    | /*empty*/        
    ;

func_def
    : FUNCTION TYPE ID '(' list_param ')' BGIN func_block END
    | FUNCTION ID ID '(' list_param ')' BGIN func_block END
    ;

func_block
    : /* empty */
    | func_block func_item
    ;

func_item
    : TYPE ID ';'                   
    | TYPE ID ASSIGN expr ';'
    | control_stmt                  
    | id_start_item ';'             
    | RETURN expr ';'
    ;

id_start_item
    : ID ID                         
    | ID ID ASSIGN expr             
    | ID ASSIGN expr                
    | ID ASSIGN NEW ID '(' ')'      
    | ID '.' ID ASSIGN expr         
    | ID '(' call_list ')'          
    | ID '.' ID '(' call_list ')'   
    | PRINT '(' expr ')'            
    ;

list_param 
    : /* empty */
    | param
    | list_param ',' param
    ;

param
    : TYPE ID
    | ID ID
    ;

main_block
    : BGIN stmt_list END
    ;

block_stmts
    : BGIN stmt_list END
    ;

stmt_list
    : /* empty */
    | stmt_list statement
    ;

statement
    : simple_stmt ';'
    | control_stmt
    ;

simple_stmt
    : ID ASSIGN expr {
          if(!symTable->exists(*$1))
              yyerror(("Variable " + *$1 + " used before declaration").c_str());
          string left_type = symTable->getType(*$1);
          if(left_type != $3)
              yyerror(("Type mismatch: cannot assign " + $3 + " to " + left_type).c_str());
      }                
    | ID ASSIGN NEW ID '(' ')' {
          if(!symTable->exists(*$1))
              yyerror(("Variable " + *$1 + " used before declaration").c_str());
          if(!symTable->classExists(*$4))
              yyerror(("Class " + *$4 + " not declared").c_str());
          string left_type = symTable->getType(*$1);
          string right_type = *$4;
          if(left_type != right_type)
              yyerror(("Type mismatch: cannot assign " + right_type + " to " + left_type).c_str());
      }   
    | ID '.' ID ASSIGN expr  {
          if(!symTable->exists(*$1))
              yyerror(("Variable " + *$1 + " used before declaration").c_str());

          string classType = symTable->getType(*$1);

          if(!symTable->classHasField(classType, *$3))
              yyerror(("Class " + classType + " has no field " + *$3).c_str());

          string fieldType = symTable->getFieldType(classType, *$3);
          if(fieldType != $5)
              yyerror(("Field assignment type mismatch in " + *$3).c_str());
      }         
    | ID '(' call_list ')' {
          if(!symTable->functionExists(*$1))
              yyerror(("Function " + *$1 + " used before declaration").c_str());

          auto expected = symTable->getFunctionParams(*$1);
          if(expected != $3)
              yyerror(("Function call parameters mismatch for " + *$1).c_str());

          $$ = symTable->getFunctionReturnType(*$1);
      }
    | ID '.' ID '(' call_list ')'{
          if(!symTable->exists(*$1))
              yyerror(("Variable " + *$1 + " used before declaration").c_str());

          string classType = symTable->getType(*$1);

          if(!symTable->classHasMethod(classType, *$3))
              yyerror(("Class " + classType + " has no method " + *$3).c_str());

          auto expected = symTable->getMethodParams(classType, *$3);
          if(expected != $5)
              yyerror(("Method call parameter mismatch in " + *$3).c_str());

          $$ = symTable->getMethodReturnType(classType, *$3);
      } 
    | PRINT '(' expr ')'              
    | RETURN expr{
        $$ = $2;
    }
    ;

control_stmt
    : IF '(' expr_bool ')' block_stmts %prec LOWER_THAN_ELSE
    | IF '(' expr_bool ')' block_stmts ELSE block_stmts
    | WHILE '(' expr_bool ')' block_stmts
    | FOR '(' simple_stmt ';' expr_bool ';' simple_stmt ')' block_stmts
    ;

expr
    : expr '+' expr{
        if($1 != $3) yyerror(("Type mismatch in addition: " + $1 + " + " + $3).c_str());
        $$ = $1;
    }
    | expr '-' expr{
        if($1 != $3) yyerror(("Type mismatch in addition: " + $1 + " + " + $3).c_str());
        $$ = $1;
    }
    | expr '*' expr{
        if($1 != $3) yyerror(("Type mismatch in addition: " + $1 + " + " + $3).c_str());
        $$ = $1;
    }
    | expr '/' expr{
        if($1 != $3) yyerror(("Type mismatch in addition: " + $1 + " + " + $3).c_str());
        $$ = $1;
    }
    | expr '%' expr{
        if($1 != $3) yyerror(("Type mismatch in addition: " + $1 + " + " + $3).c_str());
        $$ = $1;    
    }
    | '-' expr %prec UMINUS{
         $$ =$2;
    }
    | '(' expr ')'{
        $$ =$2;
    }
    | NR_INT{
        $$ = "int";
    }
    | NR_FLOAT{
        $$ ="float";
    }
    | STRING_VAL{
        $$ = "string"; 
    }
    | ID {
          if(!symTable->exists(*$1)) {
              yyerror(("Variable " + *$1 + " used before declaration").c_str());
          }
          $$ = symTable->getType(*$1);
    }
    | ID '.' ID {
        if(!symTable->exists(*$1)){
            yyerror("Variable not declared");
        }
        string classType = symTable->getType(*$1);
        if(!symTable->classHasField(classType, *$3)){
            yyerror("Field not declared in class");
        }
        $$ = symTable->getFieldType(classType, *$3);
    }
    | ID '(' call_list ')'{
        if(!symTable->functionExists(*$1)){
            yyerror("Function not declared");
        }
        auto expected = symTable->getFunctionParams(*$1);
        if(expected != $3){
            yyerror("Function call parameter mismatch");
        }
        $$ = symTable->getFunctionReturnType(*$1);
    }    
    | ID '.' ID '(' call_list ')' {
        if(!symTable->exists(*$1)){
            yyerror("Object not declared");
        }
        string classType = symTable->getType(*$1);
        if(!symTable->classHasMethod(classType, *$3)){
            yyerror("Method not declared in class");
        }
        auto expected = symTable->getMethodParams(classType, *$3);
        if(expected != $5){
            yyerror("Method call parameter mismatch");
        }
        $$ = symTable->getMethodReturnType(classType, *$3);
    }
    ;
expr_bool:
    | TRUE
    | FALSE
    | BOOL_VAL
    | NOT expr_bool
    | expr_bool AND expr_bool
    | expr_bool OR expr_bool
    | expr_bool LT expr_bool
    | expr_bool GT expr_bool
    | expr_bool LE expr_bool
    | expr_bool GE expr_bool
    | expr_bool EQ expr_bool
    | expr_bool NEQ expr_bool
    | expr comp expr
    | '(' expr_bool ')'
    ;
comp: EQ| LE | GE | GT| LT | NEQ;
call_list
    : /* empty */
    | expr
    | call_list ',' expr
    ;

%%

void yyerror(const char * s){
    errorCount++;
    fprintf(stderr, "Error: %s at line: %d\n", s, yylineno);
}

int main(int argc, char** argv){
    if(argc < 2) { cout<<"Usage: ./minilang file\n"; return 1; }
    yyin = fopen(argv[1], "r");
    yyparse();
    return 0;
}