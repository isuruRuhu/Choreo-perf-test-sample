import ballerina/http;
import ballerina/sql;
import ballerinax/mssql.driver as _;
import ballerinax/mssql as mssql;

// Types
type Employee record {|
     int employeeId;
     string firstName;
     string? lastName?;
     string email;
     string designation;
|};

configurable string dbHost = ?;
configurable string dbUser = ?;
configurable string dbPassword = ?;
configurable string dbName = ?;

final mssql:Client dbClient = check new (host = dbHost, user = dbUser, password = dbPassword, database = dbName, port = 1433);
                                
service /company on new http:Listener(8090) {

    isolated resource function post employees(@http:Payload Employee payload) returns error? {
        sql:ParameterizedQuery insertQuery = `INSERT INTO employees VALUES (${payload.employeeId},
                                              ${payload.firstName}, ${payload?.lastName},${payload.email},
                                              ${payload.designation})`;
        sql:ExecutionResult _ = check dbClient->execute(insertQuery);
    }

    isolated resource function put employees(@http:Payload Employee payload) returns error? {
        sql:ParameterizedQuery updateQuery = `UPDATE  employees SET firstName=${payload.firstName},
                                             lastName=${payload?.lastName}, email=${payload.email},
                                             designation=${payload.designation} where
                                             employeeId= ${payload.employeeId}`;
        sql:ExecutionResult _ = check dbClient->execute(updateQuery);
    }
    
    isolated resource function get employees(string designation) returns json|error {
        sql:ParameterizedQuery selectQuery = `select * from employees where designation=${designation}`;
        stream <Employee, sql:Error?> resultStream = dbClient->query(selectQuery);
        Employee[] employees = [];

        check from Employee employee in resultStream
            do {
                employees.push(employee);
            };
        return employees;
    }

    isolated resource function delete employees(int employeeId) returns error? {
        sql:ParameterizedQuery deleteQuery = `DELETE FROM employees WHERE employeeId = ${employeeId}`;
        sql:ExecutionResult _ = check dbClient->execute(deleteQuery);
    }

}
