--352¿â
--¸ú×Ù¼ì²é
IF((SELECT ISNULL(CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID('md_GCBuild')),0))=0) BEGIN  
    SELECT 'md_GCBuild'+'CTÎ´¿ªÆô'  
END;

IF((SELECT ISNULL(CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID('md_product')),0))=0) BEGIN  
    SELECT 'md_product'+'CTÎ´¿ªÆô'  
END;

IF((SELECT ISNULL(CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID('md_ProductDtl')),0))=0) BEGIN  
    SELECT 'md_ProductDtl'+'CTÎ´¿ªÆô'  
END;

IF((SELECT ISNULL(CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID('md_ProductBuild')),0))=0) BEGIN  
    SELECT 'md_ProductBuild'+'CTÎ´¿ªÆô'  
END;

IF((SELECT ISNULL(CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID('p_HkbBiddingBuilding2BuildingWork')),0))=0) BEGIN  
    SELECT 'p_HkbBiddingBuilding2BuildingWork'+'CTÎ´¿ªÆô'  
END;

IF((SELECT ISNULL(CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID('jd_ProjectPlanExecute')),0))=0) BEGIN  
    SELECT 'jd_ProjectPlanExecute'+'CTÎ´¿ªÆô'  
END;

IF((SELECT ISNULL(CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID('jd_ProjectPlanTaskExecute')),0))=0) BEGIN  
    SELECT 'jd_ProjectPlanTaskExecute'+'CTÎ´¿ªÆô'  
END;

IF((SELECT ISNULL(CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID('jd_TaskReport')),0))=0) BEGIN  
    SELECT 'jd_TaskReport'+'CTÎ´¿ªÆô'  
END;

IF((SELECT ISNULL(CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID('cb_Contract')),0))=0) BEGIN  
    SELECT 'cb_Contract'+'CTÎ´¿ªÆô'  
END;

IF((SELECT ISNULL(CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID('cb_HTFKApplyWFNodeEntity')),0))=0) BEGIN  
    SELECT 'cb_HTFKApplyWFNodeEntity'+'CTÎ´¿ªÆô'  
END;