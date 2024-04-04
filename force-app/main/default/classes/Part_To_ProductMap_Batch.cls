/**
* @Author: Abhinash D.
* @Created Date: 04-04-2024
* @LastModified Date : 04-04-2024
* @Description: Associate the Product records with Part records if the Product records does't exsist 
* based on Part records Name & compliancequest__Part_Number__c than created new Product based on part data and assign that to Product to Part.
* @TestClass: Part_To_ProductMap_BatchTest
**/

global with sharing class Part_To_ProductMap_Batch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id,Name,compliancequest__Part_Number__c,compliancequest__Active__c,compliancequest_SQX_Product__c FROM compliancequest__SQX_Part__c Where compliancequest__Active__c = true AND compliancequest_SQX_Product__c = Null';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<compliancequest__SQX_Part__c> partsList){
        Set<String> partName = new Set<String>(); //set of string to store the compliancequest__SQX_Part__c's Name
        Set<String> partNumber = new Set<String>(); //set of string to store the compliancequest__SQX_Part__c's compliancequest__Part_Number__c
        Map<String,String> partName_PartNumber_Map = new Map<String,String>(); // Map to store the Product2 Name & Product2 code as a Key & Product2 Id as a Value of the Product2
        String partName_partNumber_Key; // String to store the concatining the value of partRec.Name & partRec.compliancequest__Part_Number__c
        List<Product2> newProductList = new List<Product2>(); // new Product List to insert
        List<compliancequest__SQX_Part__c> partListToUpdate = new List<compliancequest__SQX_Part__c>(); // Part List used to update the parts with Product assignment
        
        for(compliancequest__SQX_Part__c partRec : partsList){
            if(partRec.Name != null && partRec.compliancequest__Part_Number__c != null){
                partName.add(partRec.Name);
                partNumber.add(partRec.compliancequest__Part_Number__c);
            }
        }
        
        List<Product2> ProdList = [Select Id,Name,ProductCode FROM Product2 WHERE Name In :partName AND ProductCode In :partNumber];
        
        if(ProdList.size()>0){
            for(Product2 prodRec : ProdList){
                if(prodRec.Name != null && prodRec.ProductCode != null){
                    partName_PartNumber_Map.put(prodRec.Name+'-'+prodRec.ProductCode,prodRec.Id);
                }
            }
        }
        
        for(compliancequest__SQX_Part__c partRec : partsList){
            if(partRec.Name != null && partRec.compliancequest__Part_Number__c != null){
                partName_partNumber_Key = partRec.Name+'-'+partRec.compliancequest__Part_Number__c;
            }
            
            if(!partName_PartNumber_Map.containsKey(partName_partNumber_Key)){
                Product2 newProduct = new Product2(Name = partRec.Name,
                                                   ProductCode = partRec.compliancequest__Part_Number__c,
                                                   IsActive = true);
                newProductList.add(newProduct);
            }
        }
        
        if(newProductList.Size()>0){
            insert newProductList;
            for(Product2 prodRec : newProductList){
                if(prodRec.Name != null && prodRec.ProductCode != null){
                    partName_PartNumber_Map.put(prodRec.Name+'-'+prodRec.ProductCode,prodRec.Id);
                }
            }
        }
        
        for(compliancequest__SQX_Part__c partRec : partsList){
            if(partRec.Name != null && partRec.compliancequest__Part_Number__c != null){
                partName_partNumber_Key = partRec.Name+'-'+partRec.compliancequest__Part_Number__c;
            }
            if(partName_PartNumber_Map.containsKey(partName_partNumber_Key)){
                partRec.compliancequest_SQX_Product__c = partName_PartNumber_Map.get(partName_partNumber_Key);
            }
            partListToUpdate.add(partRec);
        }
        update partListToUpdate;
    }
    
    global void finish (Database.BatchableContext BC){
        
    }
    
}