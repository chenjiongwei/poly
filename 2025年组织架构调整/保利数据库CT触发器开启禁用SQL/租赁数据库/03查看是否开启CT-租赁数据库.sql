--租赁数据库
--查看是否开启 
IF((SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_Room')),0))=0 ) BEGIN  SELECT  'p_Room'+'CT未开启'  END; 