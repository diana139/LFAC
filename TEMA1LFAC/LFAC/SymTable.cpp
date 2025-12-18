#include "SymTable.h"

void SymTable::addVar(string* type, string* name) {
    IdInfo var(type, name);
    ids[*name] = var; 
}

bool SymTable::existsId(string* var) {
    return ids.count(*var) > 0;  
}

void SymTable::printVars() {
    for (const auto &v : ids) {
        cout << "name: " << v.first << " type:" << v.second.type << endl;
    }
}

SymTable::~SymTable() {
    ids.clear();
}
