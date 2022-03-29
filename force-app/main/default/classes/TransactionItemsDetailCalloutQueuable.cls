/*
Class Name: TransactionItemsDetailCalloutQueuable
Created By: Abhishek Vishwakarma 
Description: Calling of Transaction detail handler class to rollup the specific count and other field values in API call from Queueable class
*/

public class TransactionItemsDetailCalloutQueuable implements Queueable, Database.AllowsCallouts {

    private Set<Id> setTransIDs;
    
    
    public TransactionItemsDetailCalloutQueuable(Set<Id> setTransIDs) {
        this.setTransIDs = setTransIDs;
        
    }
    
    //Calling the custom metadata definitions which is storing value for  MEthod Name, End point, Keys and other attributes
    public static AuthCredentials__mdt getAllAuthData(String configName){
        
        AuthCredentials__mdt objAuthCredentials = AuthCredentials__mdt.getInstance(configName);
        System.debug('---Auth Code is-- '+objAuthCredentials.Endpoint__c);
        
        return objAuthCredentials;
    }
    
    //Method for actualt REST API Callout for the the Request #1 & Request #2 respectively
    public static HttpResponse makeCallout(List<sObject> transactionItemsDetails, String configName){
        
        AuthCredentials__mdt objAuthCredentials = getAllAuthData(configName);
		
        HttpRequest request = new HttpRequest();
        request.setMethod(objAuthCredentials.Method__c);
        request.setEndpoint(objAuthCredentials.EndPoint__c);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(transactionItemsDetails));
        
        Http http = new Http();
        
        HttpResponse response = http.send(request);
        
        return response;
    }
    
    //Get all the trasactionItem details associated with each transactions 
    public List<TransactionItem__c> getTransactionItemDetails(List<Transaction__c> filteredTransactiontoRequest){
        
        return [select Id, NAme, Item_Cost__c, Transaction__c 
                FROM TransactionItem__c 
                WHERE Transaction__c IN: filteredTransactiontoRequest]; 
    }
    
    //PE-31543 JIRa ticket which is to get the transaction details and storing the results in map 
	//
    public List<Transaction__c> getTransactionDetails(Map<Id,Integer> mapTransItemsDetailsCount){
        
        return [select Id, Total_Cost__c, 
                Total_Discount__c, CreatedDate, 
                Transaction_Count__c 
                FROM Transaction__c 
                WHERE Id IN: mapTransItemsDetailsCount.keyset()];
    }
    
    
    //Queueable execute method to order the enqueue jobs from Queuable class 
    public void execute(QueueableContext context) {
    
        
        Map<Id,Integer> mapTransItemsDetailsCount = new Map<Id, Integer>();
        
        //Aggregate for loop to store the count value of each transactions items associated to its transactions. 
        for (AggregateResult aggResult: [select Transaction__c transID, 
                                        count(id) TransactionItemDetailCount 
                                        FROM TransactionItem__c 
                                        WHERE Transaction__c IN: setTransIDs 
                                        GROUP BY Transaction__c]) 
        {
            mapTransItemsDetailsCount.put((Id) aggResult.get('transID'), (Integer) aggResult.get('TransactionItemDetailCount'));
            System.debug('------mapTransItemsDetailsCount-----'+mapTransItemsDetailsCount);
        }
        
        //filter all transactions taken from transaction items count & its detail
        List < Transaction__c > filterAllTransactions = getTransactionDetails(mapTransItemsDetailsCount);
       
        List<Transaction__c> filteredTransactiontoRequest = new List <Transaction__c >();
        for (Transaction__c objTransactions: filterAllTransactions) {
           
            System.debug('------filterAllTransactions-----'+filterAllTransactions);
            if (objTransactions.Transaction_Count__c == mapTransItemsDetailsCount.get(objTransactions.Id)) {
                filteredTransactiontoRequest.add(objTransactions);
            }
        }
        
        List<TransactionItem__c> transactionItemsDetails = getTransactionItemDetails(filteredTransactiontoRequest);
        System.debug('---transactionItemsDetails-----'+transactionItemsDetails);
        HttpResponse response;
        
        //Checking the transaction items if the list is not empty 
        if(!transactionItemsDetails.isEmpty()){
            
            //try block
            try{
                response = makeCallout(transactionItemsDetails,'AuthCredentials');
                System.debug('---httpResponsehttpResponse-----');
            }
            //catch block
            catch(Exception ex){
                System.debug('---Exception message-----'+ex.getMessage());
            }
        }
        
        if (null != response && 200 == response.getStatusCode()) {
           
           //try block 
           try{
                
                response = makeCallout(filterAllTransactions,'AuthCredentialsPOST');
            }
            //catch block 
            Catch(Exception ex){
                System.debug('---Exception message-----'+ex.getMessage());
            }
         }
    }
}
