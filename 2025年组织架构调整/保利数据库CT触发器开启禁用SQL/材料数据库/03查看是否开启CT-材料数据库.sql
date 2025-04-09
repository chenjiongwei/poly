--材料数据库
--查看是否开启 
IF((SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('myWorkflowNodeEntity')),0))=0 ) BEGIN  SELECT  'myWorkflowNodeEntity'+'CT未开启'  END; 
IF((SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_TaskWake')),0))=0 ) BEGIN  SELECT  'p_TaskWake'+'CT未开启'  END; 
IF((SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('myWorkflowProcessEntity')),0))=0 ) BEGIN  SELECT  'myWorkflowProcessEntity'+'CT未开启'  END; 