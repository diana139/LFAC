#ifndef SYMTABLE_H
#define SYMTABLE_H

#include <iostream>
#include <string>
#include <map>
using namespace std;

struct IdInfo {
    string type;
    string name;
    IdInfo() {}
    IdInfo(string* t, string* n) { type = *t; name = *n; }
};

class SymTable {
public:
    SymTable(string name) { tableName = name; }
    ~SymTable();
    void addVar(string* type, string* name);
    bool existsId(string* var);
    void printVars();
private:
    string tableName;
    map<string, IdInfo> ids;
};

#endif
