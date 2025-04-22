USE ERP25_test
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
        INNER JOIN dqy_proj_20250422 t ON t.oldprojguid = mp.ProjGUID
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


EXEC usp_s_ProjectMove '淮海公司', '4C2CD96B-15EB-EE11-B3A4-F40270D39969', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', 'DFE1DD0B-043E-E711-80BA-E61F13C57837', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', '6EB03C5C-F24A-E811-80BA-E61F13C57837', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', '7F9EEA25-F24A-E811-80BA-E61F13C57837', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', '4BE2EB2E-A9FA-E711-80BA-E61F13C57837', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', 'A4DBA98F-8E46-EB11-B398-F40270D39969', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', 'E81DECD4-7F46-EB11-B398-F40270D39969', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', 'F58F1AA3-0FFF-EB11-B398-F40270D39969', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', 'CAD9E1A3-0A3A-EB11-B398-F40270D39969', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', 'E95E458C-F339-EB11-B398-F40270D39969', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', 'C0D7AF14-5399-E911-80B7-0A94EF7517DD', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', 'EC64E753-FEFE-EB11-B398-F40270D39969', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', 'B41363DA-92FE-EB11-B398-F40270D39969', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', '07EE07C1-10F4-EB11-B398-F40270D39969', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', 'DFB5066E-4249-E811-80BA-E61F13C57837', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', 'E2B7EB0C-4249-E811-80BA-E61F13C57837', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', '8EBEC7B7-4149-E811-80BA-E61F13C57837', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', 'C50B794A-4149-E811-80BA-E61F13C57837', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', '20F99BDB-DD86-E711-80BA-E61F13C57837', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', '730BAE17-3021-EA11-80B8-0A94EF7517DD', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', 'B4958473-344F-EA11-80B8-0A94EF7517DD', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', '511B340B-831D-EA11-80B8-0A94EF7517DD', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', '1CEDF708-5C1D-EA11-80B8-0A94EF7517DD', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', '2ECA0DD4-2C2B-EB11-B398-F40270D39969', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', 'E79353EE-6991-E711-80BA-E61F13C57837', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', '9B37F481-81E1-ED11-B3A3-F40270D39969', '江苏公司';
EXEC usp_s_ProjectMove '淮海公司', 'C93FBCC0-083E-E711-80BA-E61F13C57837', '江苏公司';






/*查询最近创建的业务表中——s_前缀且包含BUGUID字段*/

SELECT sys.objects.name 表名 ,
       sys.columns.name  字段名称,
       sys.types.name 数据类型,
       sys.columns.max_length 长度,
	   sys.objects.create_date 创建日期
FROM   sys.objects
       LEFT JOIN sys.columns ON sys.objects.object_id = sys.columns.object_id
       LEFT JOIN sys.types ON sys.types.system_type_id = sys.columns.system_type_id
WHERE sys.columns.name = 'buguid' AND
       sys.objects.type = 'U'
       AND sys.objects.name LIKE 's_yj%'
          ORDER BY sys.objects.name,sys.columns.column_id

-- 影响变更的表
-- s_BajlrPlan	备案价录入申请表
-- s_BizParamAdjustApplyProduct	业务参数申请产品类型
-- s_CelProjectSaleInfo	
-- s_CelProjectSaleInfo_Msg	
-- s_CelProjectSaleInfo_User	业绩简讯的发送用户设置表
-- s_Contract_Pre	
-- s_HTExtendedFieldData	合同拓展字段表

