USE ERP25;
GO

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
        INNER JOIN dqy_proj_20240613 t ON t.oldprojguid = mp.ProjGUID
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

        --SELECT  @TopProjGUID = STUFF((SELECT    ',' + CONVERT(VARCHAR(MAX), t1.projguid)
        --                              FROM  #t t1
        --                              WHERE t1.num = @i
        --                             FOR XML PATH('')), 1, 1, '');
        --EXEC usp_s_ProjectMove @oldBuname, @TopProjGUID, @newBuname;
		PRINT   'EXEC usp_s_ProjectMove '''+@oldBuname+''', '''+@TopProjGUID+''', '''+@newBuname+''';'
        SET @i = @i + 1;
    END;

--DROP TABLE #t;

EXEC usp_s_ProjectMove '保利里城', 'B8FA868C-7A36-E911-80B7-0A94EF7517DD', '海西公司';
EXEC usp_s_ProjectMove '保利里城', 'FE0372DE-F00F-E911-80BF-E61F13C57837', '重庆公司';
EXEC usp_s_ProjectMove '保利里城', '5E2053F6-F00F-E911-80BF-E61F13C57837', '江苏公司';
EXEC usp_s_ProjectMove '保利里城', '96593E08-F10F-E911-80BF-E61F13C57837', '江苏公司';
EXEC usp_s_ProjectMove '保利里城', 'B3602B20-F10F-E911-80BF-E61F13C57837', '江苏公司';
EXEC usp_s_ProjectMove '保利里城', '11D560DD-097C-EB11-B398-F40270D39969', '湖南公司';
EXEC usp_s_ProjectMove '保利里城', 'A169EA26-C70A-EC11-B398-F40270D39969', '陕西公司';
EXEC usp_s_ProjectMove '保利里城', '64D4173E-F10F-E911-80BF-E61F13C57837', '陕西公司';
EXEC usp_s_ProjectMove '保利里城', '07DE0456-F10F-E911-80BF-E61F13C57837', '海西公司';
EXEC usp_s_ProjectMove '保利里城', '154BDB79-F10F-E911-80BF-E61F13C57837', '海西公司';
EXEC usp_s_ProjectMove '保利里城', '49D1D48B-F10F-E911-80BF-E61F13C57837', '湖南公司';
EXEC usp_s_ProjectMove '保利里城', '7E13BDA3-F10F-E911-80BF-E61F13C57837', '云南公司';
EXEC usp_s_ProjectMove '保利里城', '2481A886-E71E-E911-80BF-E61F13C57837', '云南公司';
EXEC usp_s_ProjectMove '保利里城', '59056B73-FD65-EB11-B398-F40270D39969', '江苏公司';
EXEC usp_s_ProjectMove '保利里城', '9410E473-9AF4-E911-80B8-0A94EF7517DD', '江苏公司';
