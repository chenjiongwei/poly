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
        INNER JOIN dqy_proj_20250424 t ON t.oldprojguid = mp.ProjGUID
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

EXEC usp_s_ProjectMove '大连公司', '16A64B68-8FE3-EA11-80B8-0A94EF7517DD', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', 'C4C56907-2E57-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', '74799E46-1357-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', '4C8D94C7-1257-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', '98A7FDF1-1257-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', '360DB822-1357-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', '5CE67A0A-1357-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', 'EF4861A3-F333-E911-80B7-0A94EF7517DD', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', '12DDCAC5-146B-E911-80B7-0A94EF7517DD', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', 'C10B5B22-689C-E911-80B7-0A94EF7517DD', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', '5081C784-F2E0-E911-80B8-0A94EF7517DD', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', 'EA1B7AF6-82E3-E911-80B8-0A94EF7517DD', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', '1363317F-D63D-EB11-B398-F40270D39969', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', '0B2666B5-848C-EB11-B398-F40270D39969', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', 'EC93F036-09DB-EB11-B398-F40270D39969', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', 'E17B3E08-5D87-ED11-B3A2-F40270D39969', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', 'E49B4AB6-9E53-EE11-B3A4-F40270D39969', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', '1387C59F-CFBE-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', 'BC048B3F-15BE-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', 'EDBC5D28-64C3-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', 'DB4FA6B8-8144-E811-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', 'AD3AD5CA-8144-E811-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', '9F1D1CE3-8144-E811-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', 'A6314B13-8244-E811-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', 'D2F69537-8244-E811-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '大连公司', '53D6FFC2-8244-E811-80BA-E61F13C57837', '辽宁公司';