import ballerina/http;
import ballerina/sql;
import ballerinax/mysql.driver as _;
import ballerinax/java.jdbc as jdbc;

// Types
type Employee record {|
     int employeeId;
     string firstName;
     string? lastName?;
     string email;
     string designation;
|};

configurable string dbUrl = ?;
configurable string dbUsername = ?;
configurable string dbPassword = ?;

final jdbc:Client mysqlClient = check new (url = dbUrl, user = dbUsername, password = dbPassword);
                                
service /company on new http:Listener(8090) {

    isolated resource function post employees(@http:Payload Employee payload) returns error? {
        sql:ParameterizedQuery insertQuery = `INSERT INTO employees VALUES (${payload.employeeId},
                                              ${payload.firstName}, ${payload?.lastName},${payload.email},
                                              ${payload.designation})`;
        sql:ExecutionResult _ = check mysqlClient->execute(insertQuery);
    }

    isolated resource function put employees(@http:Payload Employee payload) returns error? {
        sql:ParameterizedQuery updateQuery = `UPDATE  employees SET firstName=${payload.firstName},
                                             lastName=${payload?.lastName}, email=${payload.email},
                                             designation=${payload.designation} where
                                             employeeId= ${payload.employeeId}`;
        sql:ExecutionResult _ = check mysqlClient->execute(updateQuery);
    }
    
    isolated resource function get employees(string designation) returns json|error {
        sql:ParameterizedQuery selectQuery = `select * from employees where designation=${designation}`;
        stream <Employee, sql:Error?> resultStream = mysqlClient->query(selectQuery);
        Employee[] employees = [];

        check from Employee employee in resultStream
            do {
                employees.push(employee);
            };
        return employees;
    }

    isolated resource function delete employees(int employeeId) returns error? {
        sql:ParameterizedQuery deleteQuery = `DELETE FROM employees WHERE employeeId = ${employeeId}`;
        sql:ExecutionResult _ = check mysqlClient->execute(deleteQuery);
    }

}
