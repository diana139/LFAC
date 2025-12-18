#ifndef SYMTABLE_H
#define SYMTABLE_H

#include <iostream>
#include <string>
#include <map>
#include <vector>
#include <fstream>

using namespace std;

struct IdInfo {
    string name;
    string type;          
    string value;         
    bool isFunction;
    string returnType;
    vector<pair<string, string>> params; 

    IdInfo() : isFunction(false) {}
    IdInfo(string n, string t, string v = "undefined") 
        : name(n), type(t), value(v), isFunction(false) {}
    IdInfo(string n, string retT, vector<pair<string, string>> p) 
        : name(n), returnType(retT), params(p), isFunction(true) {}
};

class SymTable {
public:
    string tableName;
    SymTable* parent;
    map<string, IdInfo> ids;
    map<string, SymTable*> classScopes; 

    SymTable(string name, SymTable* p = nullptr);
    ~SymTable();

    void addVar(string type, string name, string value = "undefined");
    void addFunc(string returnType, string name, vector<pair<string, string>> params);
    void addClass(string name, SymTable* classScope);

    bool exists(string name);
    bool existsFunction(string name);
    bool existsClass(string name);

    string getType(string name);               
    string getFunctionReturnType(string name); 
    vector<pair<string, string>> getFunctionParams(string name); 
    string getFieldType(string className, string fieldName);

    bool classHasField(string className, string fieldName);
    void printTable(ostream& out);
    string getMethodReturnType(string className, string methodName); 
    vector<pair<string, string>> getMethodParams(string className, string methodName);
};

#endif