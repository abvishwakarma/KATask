/*
Class Name: TransactItemsDetCalloutQueuableTest
Created By: Abhishek Vishwakarma 
Description: Callout Test Class 
*/

@isTest
private class TransactItemsDetCalloutQueuableTest {
    
    public static Set<Id> transactionIds = new set<Id>();
    public static List<TransactionItem__c> lstTransactionItemData;
    private static void createTransAndItemData(){
        
        lstTransactionItemData = new List<TransactionItem__c>();
        Transaction__c insertTransactionData = new Transaction__c(Total_Cost__c = 100,Total_Discount__c =10,Transaction_Count__c =3);        
        transactionIds.add(insertTransactionData.Id);
        insert insertTransactionData;
        
        lstTransactionItemData.add(new TransactionItem__c(Name = 'Test Tranascation Item 1',Item_Cost__c = 300,Transaction__c =insertTransactionData.id ));
        insert lstTransactionItemData; 
        
    }
    
    @isTest 
    static void testCallout() {
        
        //Setting my Mock up Class 
        Test.setMock(HttpCalloutMock.class, new TransImplementMock()); 
        // Call method to test.
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        HttpResponse res = TransactionItemsDetailCalloutQueuable.makeCallout(lstTransactionItemData,'AuthCredentialsPOST');
        
        // Verify response received contains fake values
        String contentType = res.getHeader('Content-Type');
        System.assert(contentType == 'application/json');
        String actualValue = res.getBody();
        String expectedValue = '{"trail":"test"}';
        System.assertEquals(actualValue, expectedValue);
        System.assertEquals(200, res.getStatusCode());
    }
    
    static testMethod void makeCalloutTest(){
        
        createTransAndItemData();
        
        Test.startTest();
        TransactionItemsDetailCalloutQueuable.getAllAuthData('AuthCredentialsPOST');
        TransactionItemsDetailCalloutQueuable updater = new TransactionItemsDetailCalloutQueuable(transactionIds);
        system.enqueueJob(updater);
        Test.setMock(HttpCalloutMock.class, new TransImplementMock());   
        Test.stopTest();
    }
}