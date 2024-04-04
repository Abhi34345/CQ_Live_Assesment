/**
* @Author: Abhinash D.
* @Created Date: 04-04-2024
* @LastModified Date : 04-04-2024
* @Description: Schedule the Part_To_ProductMap_Batch apex in this schedule class and by executing the batch based on 
* System Administrator Profile and CQ_Admin permission set assigned to that user.
* @TestClass: Part_To_ProductMap_BatchTest
**/

global class Part_To_ProductMap_BatchSchedule implements schedulable {
    global static String CQ_ADMIN = 'CQ_Admin';
    global static String PERMISSION_SET_NAME;
    global void execute(schedulableContext SC){
        //get current UserId
        String userId = userInfo.getUserId();
        
        //get permissionset
        List<permissionset> permissionSetList = [SELECT Id, Name FROM permissionset WHERE Name = :CQ_ADMIN];
        
        if(permissionSetList.Size()>0){
            PERMISSION_SET_NAME = permissionSetList[0].Name;
        }
        
        List<PermissionSetAssignment> userPermissionSetAssgnList = [SELECT Id, 
                                                                    PermissionSetId,
                                                                    PermissionSet.Name,
                                                                    PermissionSetGroupId, 
                                                                    AssigneeId 
                                                                    FROM PermissionSetAssignment
                                                                    WHERE AssigneeId = :userId
                                                                    AND PermissionSet.Name = :PERMISSION_SET_NAME];
        Set<String> exsistingPermissonSet = new Set<String>();
        
        for(PermissionSetAssignment PSA : userPermissionSetAssgnList){
            exsistingPermissonSet.add(PSA.PermissionSet.Name);
        }
        
        if(exsistingPermissonSet.contains(PERMISSION_SET_NAME)){
            Part_To_ProductMap_Batch scheduleBatch = new Part_To_ProductMap_Batch();
            Database.executeBatch(scheduleBatch,200);
        }
        
    }
}