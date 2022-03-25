/*
Class Name: TransactionItemsDetailTrigger 
Created By: Abhishek Vishwakarma
Description: Calling of Transaction detail handler class to rollup the specific count and other field values in API call
*/

trigger TransactionItemsDetailTrigger on TransactionItem__c (After Insert, After Update) {

    
     Set<Id> setTransIDs = new set<Id>();
     
     for(TransactionItem__c objTransItems : Trigger.New){
         setTransIDs.add(objTransItems.Transaction__c);
     }
     if(Trigger.isAfter){
         if(Trigger.isInsert || Trigger.isUpdate){
         
          //Calling API handler class
          TransactionItemsDetailCalloutQueuable updateTransactionJob = new TransactionItemsDetailCalloutQueuable(setTransIDs);
         
         //enquing the job
         ID jobID = System.enqueueJob(updateTransactionJob);
         }
     }
     
}