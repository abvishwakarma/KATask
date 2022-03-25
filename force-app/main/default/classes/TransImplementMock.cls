/*
Class Name: TransImplementMock
Created By: Abhishek Vishwakarma 
Description: Mock Callout Class 
*/
@isTest
global class TransImplementMock implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"trail":"test"}');
        res.setStatusCode(200);
        return res;
    }
}