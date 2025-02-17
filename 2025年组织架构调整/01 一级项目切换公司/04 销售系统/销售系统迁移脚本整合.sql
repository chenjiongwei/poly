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
        INNER JOIN dqy_proj_20250121 t ON t.oldprojguid = mp.ProjGUID
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

EXEC usp_s_ProjectMove '浙南公司', '6E54378F-CFA1-E711-80BA-E61F13C57837', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', 'C7D1C505-65F9-E911-80B8-0A94EF7517DD', '浙江公司';


EXEC usp_s_ProjectMove '浙南公司', '7640ECEE-9071-EE11-B3A4-F40270D39969', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', 'CD197585-FA65-EB11-B398-F40270D39969', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', '65201843-F956-EB11-B398-F40270D39969', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', 'C1C816FC-E748-EB11-B398-F40270D39969', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', 'E2E39B24-18D0-EB11-B398-F40270D39969', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', '456BA33F-64CE-EB11-B398-F40270D39969', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', '11391CFA-18A4-EB11-B398-F40270D39969', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', 'EFB3BAAC-81A1-EB11-B398-F40270D39969', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', '6DAA9E3C-3B9F-EB11-B398-F40270D39969', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', '351C8116-A9F7-EC11-B39C-F40270D39969', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', '1D9B8A51-8269-E811-80BF-E61F13C57837', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', 'FBFEB86D-6144-E811-80BA-E61F13C57837', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', 'F6176ACF-3A2E-E811-80BA-E61F13C57837', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', '1B573663-3A2E-E811-80BA-E61F13C57837', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', 'D054F9F6-1AF5-E711-80BA-E61F13C57837', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', '1B6DB4DE-1AF5-E711-80BA-E61F13C57837', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', 'C84ABDBA-1AF5-E711-80BA-E61F13C57837', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', '761850FE-CBB1-EA11-80B8-0A94EF7517DD', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', 'C0BEC8A0-1FBB-E711-80BA-E61F13C57837', '浙江公司';

EXEC usp_s_ProjectMove '浙南公司', '641BC11F-768E-E911-80B7-0A94EF7517DD', '浙江公司';
EXEC usp_s_ProjectMove '浙南公司', '93BC73CD-216A-E911-80B7-0A94EF7517DD', '浙江公司';





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

