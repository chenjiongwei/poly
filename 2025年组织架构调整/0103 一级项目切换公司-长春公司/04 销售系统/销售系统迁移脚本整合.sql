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


EXEC usp_s_ProjectMove '长春公司', '07093FFF-4E7E-EF11-B3A5-F40270D39969', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', 'A4A6F5F1-7289-E811-80BF-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '181F4E52-7389-E811-80BF-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '62978BAB-5619-E911-80BF-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', 'FA3EE5CE-77AF-E911-80B7-0A94EF7517DD', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', 'A3FCB536-A1DD-E911-80B7-0A94EF7517DD', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '33C8CB0A-A14B-EA11-80B8-0A94EF7517DD', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '436CEFD2-7896-EA11-80B8-0A94EF7517DD', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', 'ABCDA98A-C2D7-EA11-80B8-0A94EF7517DD', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '3E2D8D99-5F25-EB11-B398-F40270D39969', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '3116FD05-3940-EB11-B398-F40270D39969', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '1189E4B3-177E-EB11-B398-F40270D39969', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', 'B8B1E066-91BA-EB11-B398-F40270D39969', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '4D9B8281-58D6-EB11-B398-F40270D39969', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', 'E84BB626-1A72-EE11-B3A4-F40270D39969', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '87AB3712-7456-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '27FB2AB4-28A4-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '668A9CD4-7456-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '6341E924-1AA3-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', 'C9C9695A-7456-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '41548F02-29A4-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '8545F40A-7156-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', 'EA3FED75-82A2-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', 'C19C6248-7556-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '8280F0FE-7456-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '9E4D8F0E-FBA3-E711-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', 'DC92E528-D83A-E811-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '1BD7DA4C-D83A-E811-80BA-E61F13C57837', '辽宁公司';
EXEC usp_s_ProjectMove '长春公司', '967014C6-B987-EA11-80B8-0A94EF7517DD', '辽宁公司';



