/**
* @Author: Abhinash D.
* @Created Date: 04-04-2024
* @LastModified Date : 04-04-2024
* @Description: unit testing the Part_To_ProductMap_Batch batch apex & Part_To_ProductMap_BatchSchedule schedule apex in this test class.
**/

@isTest
public class Part_To_ProductMap_BatchTest {
    
    /**
* Description : Setuping the test data that need to be processed
**/
    
    @testSetUp
    static void testDataSetupMethod(){
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        User adminUser = new User(Alias = 'standr',
                                  Email = 'standardUser@gmail.com',
                                  LastName = 'Test',
                                  TimeZoneSidKey = 'America/Los_Angeles', 
                                  LocaleSidKey = 'en_US', 
                                  EmailEncodingKey = 'UTF-8', 
                                  LanguageLocaleKey = 'en_US',
                                  Username = 'adminUser@#org.com',
                                  ProfileId = standardProfile.Id);
        insert adminUser;
        
        permissionset permissionSetRec = [SELECT Id, Name FROM permissionset WHERE Name = 'CQ_ADMIN'];
        
        insert new PermissionSetAssignment(AssigneeId = adminUser.Id, PermissionSetId = permissionSetRec.Id);
        
        system.runAS(adminUser){
            
            compliancequest__SQX_Part_Family__c partFamily = new compliancequest__SQX_Part_Family__c(Name = 'Test Family');
            insert partFamily;
            
            compliancequest__SQX_Part__c part1Rec = new compliancequest__SQX_Part__c(Name = 'Part 1',
                                                                                     compliancequest__Part_Number__c = 'PN1',
                                                                                     compliancequest__Active__c = true,
                                                                                     compliancequest__Part_Family__c = partFamily.Id);
            insert part1Rec;
            
            compliancequest__SQX_Part__c part2Rec = new compliancequest__SQX_Part__c(Name = 'Part 2',
                                                                                     compliancequest__Part_Number__c = 'PN2',
                                                                                     compliancequest__Active__c = true,
                                                                                     compliancequest__Part_Family__c = partFamily.Id);
            insert part2Rec;
            
            Product2 prodRec = new Product2(Name = 'Part 1',
                                            ProductCode = 'PN1',
                                            IsActive = true);
            insert prodRec;
        }
    }
    
    /**
* Description : Checking the Products with Parts data asserting the Product Name equals to Part Name &
* Product Code equals to Part Number.
**/
    testmethod static void testPartWithProductMapping(){
        User adminUser = [Select Id,Name,ProfileId,Profile.Name FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        
        system.runAs(adminUser){
            compliancequest__SQX_Part__c part1Rec = [Select Id,
                                                     Name,
                                                     compliancequest__Part_Number__c,
                                                     compliancequest__Active__c 
                                                     FROM compliancequest__SQX_Part__c
                                                     WHERE compliancequest__Active__c = true 
                                                     AND Name = 'Part 1' LIMIT 1];
            
            List<Product2> prodRec = [SELECT Id,
                                      Name,
                                      ProductCode 
                                      FROM Product2 
                                      WHERE Name =: part1Rec.Name 
                                      AND ProductCode =:part1Rec.compliancequest__Part_Number__c 
                                      LIMIT 1];
            
            Test.startTest();
            
            Part_To_ProductMap_Batch batch = new Part_To_ProductMap_Batch();
            Database.executeBatch(batch);
            
            Part_To_ProductMap_BatchSchedule schdBatch = new Part_To_ProductMap_BatchSchedule();
            String sch = '0 0 6 * * ?'; //CRON Expression
            system.schedule('Schedule batch', sch, schdBatch);
            Test.stopTest();
            
            system.assertEquals(part1Rec.Name, prodRec[0].Name, 'Product shoule be created');
            system.assertEquals(part1Rec.compliancequest__Part_Number__c, prodRec[0].ProductCode, 'Product shoule be created');
        }
    }
    
    /**
* Description : Checking the Products with Parts data and if the Products does't present asserting the list of Product size.
**/
    testmethod static void testPartWithOutProductMapping(){
        
        User adminUser = [SELECT Id,Name,ProfileId,Profile.Name FROM User Where Profile.Name ='System Administrator' LIMIT 1];
        
        system.runAs(adminUser){
            compliancequest__SQX_Part__c part2Rec = [SELECT Id,
                                                     Name,
                                                     compliancequest__Part_Number__c,
                                                     compliancequest__Active__c
                                                     FROM compliancequest__SQX_Part__c
                                                     WHERE compliancequest__Active__c = true
                                                     AND Name = 'Part 2' LIMIT 1];
            
            List<Product2> prod2Rec = [SELECT Id,
                                       Name,
                                       ProductCode 
                                       FROM Product2 
                                       WHERE Name = :part2Rec.Name 
                                       AND ProductCode = :part2Rec.compliancequest__Part_Number__c 
                                       LIMIT 1];
            
            Test.startTest();
            Part_To_ProductMap_Batch batch = new Part_To_ProductMap_Batch();
            Database.executeBatch(batch);
            
            Part_To_ProductMap_BatchSchedule schBatch = new Part_To_ProductMap_BatchSchedule();
            String sch = '0 0 6 * * ?'; //CRON expression
            system.schedule('Schedule Batch',sch,schBatch);
            Test.stopTest();
            
            system.assert(prod2Rec.Size() <= 0, 'There is no Product realted to Part');
            
        }
    }
}