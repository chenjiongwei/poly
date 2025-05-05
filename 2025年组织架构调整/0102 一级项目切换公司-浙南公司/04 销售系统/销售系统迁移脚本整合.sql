USE ERP25
GO

/*
-- 2025年组织架构调整，4家平台公司的项目及业务数据合并处理
1、浙南合并进浙江，
2、齐鲁合并进山东，
3、大连合并进辽宁，
4、淮海合并进江苏

*/

DECLARE @i INT = 1;
DECLARE @j INT;
DECLARE @oldBuname VARCHAR(MAX);
DECLARE @TopProjGUID VARCHAR(MAX);
DECLARE @newBuname VARCHAR(MAX);

SELECT  bu.buname AS OldBuName ,
        p.ProjGUID ,
        t.NewBuName ,
        -- DENSE_RANK() OVER (ORDER BY bu.buname) num
		ROW_NUMBER() OVER (ORDER BY bu.buname) num
INTO    #t
FROM    p_project p
        INNER JOIN mdm_project mp ON mp.ProjGUID = p.ProjGUID
        INNER JOIN dqy_proj_20250421 t ON t.oldprojguid = mp.ProjGUID
        INNER JOIN mybusinessunit bu ON bu.BUGUID = p.BUGUID
WHERE   p.level = 2;

PRINT '项目数量：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

SELECT  @j = COUNT(DISTINCT projguid)FROM   #t;

WHILE @i <= @j
    BEGIN

        --  SELECT     @oldBuname = t1.OldBuName ,
        --                  @newBuname = t1.NewBuName,
        --@TopProjGUID = t1.ProjGUID
        --  FROM    #t t1
        --  WHERE   t1.num = @i 
        SELECT  @oldBuname = t1.OldBuName ,
                @newBuname = t1.NewBuName ,
                @TopProjGUID = t1.ProjGUID
        FROM    #t t1
        WHERE   t1.num = @i;

        --PRINT '@oldBuname' + @oldBuname;
        --PRINT '@newBuname' + @newBuname;
        --PRINT '@TopProjGUID' + @TopProjGUID;

        -- SELECT  @TopProjGUID = STUFF((SELECT    ',' + CONVERT(VARCHAR(MAX), t1.projguid)
        --                              FROM  #t t1
        --                              WHERE t1.num = @i
        --                             FOR XML PATH('')), 1, 1, '');
        --EXEC usp_s_ProjectMove @oldBuname, @TopProjGUID, @newBuname;
		PRINT   'EXEC usp_s_ProjectMove '''+@oldBuname+''', '''+@TopProjGUID+''', '''+@newBuname+''';'
        SET @i = @i + 1;
    END;

--DROP TABLE #t;


-- EXEC usp_s_ProjectMove '淮海公司', '4C2CD96B-15EB-EE11-B3A4-F40270D39969', '江苏公司';







/*查询最近创建的业务表中——s_前缀且包含BUGUID字段*/

-- SELECT sys.objects.name 表名 ,
--        sys.columns.name  字段名称,
--        sys.types.name 数据类型,
--        sys.columns.max_length 长度,
-- 	   sys.objects.create_date 创建日期
-- FROM   sys.objects
--        LEFT JOIN sys.columns ON sys.objects.object_id = sys.columns.object_id
--        LEFT JOIN sys.types ON sys.types.system_type_id = sys.columns.system_type_id
-- WHERE sys.columns.name = 'buguid' AND
--        sys.objects.type = 'U'
--        AND sys.objects.name LIKE 's_yj%'
--           ORDER BY sys.objects.name,sys.columns.column_id

-- 影响变更的表
-- s_BajlrPlan	备案价录入申请表
-- s_BizParamAdjustApplyProduct	业务参数申请产品类型
-- s_CelProjectSaleInfo	
-- s_CelProjectSaleInfo_Msg	
-- s_CelProjectSaleInfo_User	业绩简讯的发送用户设置表
-- s_Contract_Pre	
-- s_HTExtendedFieldData	合同拓展字段表

