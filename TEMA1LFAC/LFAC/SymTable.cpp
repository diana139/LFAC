#include "SymTable.h"

SymTable::SymTable(string name, SymTable* p) {
    this->tableName = name;
    this->parent = p;
}

SymTable::~SymTable() {}

void SymTable::addVar(string type, string name, string value) {
    ids[name] = IdInfo(name, type, value);
}

void SymTable::addFunc(string returnType, string name, vector<pair<string, string>> params) {
    ids[name] = IdInfo(name, returnType, params);
}

void SymTable::addClass(string name, SymTable* classScope) {
    ids[name] = IdInfo(name, "class");
    classScopes[name] = classScope;
}


bool SymTable::exists(string name) {
    if (ids.count(name) && !ids[name].isFunction) return true;
    if (parent != nullptr) return parent->exists(name);
    return false;
}

bool SymTable::existsFunction(string name) {
    if (ids.count(name) && ids[name].isFunction) return true;
    if (parent != nullptr) return parent->existsFunction(name);
    return false;
}

bool SymTable::existsClass(string name) {
    if (ids.count(name) && ids[name].type == "class") return true;
    if (parent != nullptr) return parent->existsClass(name);
    return false;
}


string SymTable::getType(string name) {
    if (ids.count(name)) return ids[name].type;
    if (parent != nullptr) return parent->getType(name);
    return "undefined_type";
}

string SymTable::getFunctionReturnType(string name) {
    if (ids.count(name) && ids[name].isFunction) return ids[name].returnType;
    if (parent != nullptr) return parent->getFunctionReturnType(name);
    return "undefined_ret_type";
}

vector<pair<string, string>> SymTable::getFunctionParams(string name) {
    if (ids.count(name) && ids[name].isFunction) return ids[name].params;
    if (parent != nullptr) return parent->getFunctionParams(name);
    return {}; 
}


bool SymTable::classHasField(string className, string fieldName) {
    if (classScopes.count(className)) {
        return classScopes[className]->ids.count(fieldName);
    }
    if (parent != nullptr) return parent->classHasField(className, fieldName);
    return false;
}

string SymTable::getFieldType(string className, string fieldName) {
    if (classScopes.count(className)) {
        if (classScopes[className]->ids.count(fieldName)) {
            return classScopes[className]->ids[fieldName].type;
        }
    }
    if (parent != nullptr) return parent->getFieldType(className, fieldName);
    return "undefined_field";
}
string SymTable::getMethodReturnType(string className, string methodName) {
    if (classScopes.count(className)) {
        SymTable* scopeClasa = classScopes[className];
        if (scopeClasa->ids.count(methodName) && scopeClasa->ids[methodName].isFunction) {
            return scopeClasa->ids[methodName].returnType;
        }
    }
    if (parent != nullptr) return parent->getMethodReturnType(className, methodName);
    return "undefined_method";
}

vector<pair<string, string>> SymTable::getMethodParams(string className, string methodName) {
    if (classScopes.count(className)) {
        SymTable* scopeClasa = classScopes[className];
        if (scopeClasa->ids.count(methodName) && scopeClasa->ids[methodName].isFunction) {
            return scopeClasa->ids[methodName].params;
        }
    }
    if (parent != nullptr) return parent->getMethodParams(className, methodName);
    return {};
}

// --- AFISARE ---

void SymTable::printTable(ostream& out) {
    out << "====================================================\n";
    out << " TABLE NAME: " << tableName << "\n";
    if (parent) out << " PARENT: " << parent->tableName << "\n";
    out << "====================================================\n";
    out << " [TYPE]        | [NAME]       | [VALUE/INFO]\n";
    out << "----------------------------------------------------\n";

    for (auto const& [name, info] : ids) {
        if (info.isFunction) {
            out << " FUNC: " << info.returnType << " | " << name << " | Params: ";
            for (auto const& p : info.params) out << p.first << " " << p.second << " ";
            out << "\n";
        } else {
            out << " VAR:  " << info.type << " | " << name << " | Value: " << info.value << "\n";
        }
    }
    out << "====================================================\n\n";
}