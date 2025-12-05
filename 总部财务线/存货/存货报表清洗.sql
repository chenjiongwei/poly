
    -- 定义变量：存放所有符合条件的开发公司GUID（以逗号分隔）
    DECLARE @buguid VARCHAR(MAX);
    SELECT
        @buguid = STUFF((
            SELECT RTRIM(',' + CONVERT(VARCHAR(MAX), devCom.DevelopmentCompanyGUID))
            FROM erp25.dbo.myBusinessUnit unit
            LEFT JOIN erp25.dbo.companyjoin comJoin
                ON unit.BUGUID = comJoin.BUGUID
            LEFT JOIN erp25.dbo.p_DevelopmentCompany devCom
                ON devCom.DevelopmentCompanyGUID = comJoin.DevelopmentCompanyGUID
            INNER JOIN (
                SELECT DISTINCT DevelopmentCompanyGUID
                FROM erp25.dbo.mdm_Project
            ) p ON p.DevelopmentCompanyGUID = devCom.DevelopmentCompanyGUID
            WHERE
                IsEndCompany = 1
                AND IsCompany = 1
                -- 排除特殊BU业务单元
                AND unit.BUGUID <> '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715'
                AND unit.BUGUID NOT IN (
                    -- 以下为需要排除的业务单元GUID清单
                    'bbd25c3a-209d-4f67-8ff2-d7f7ba39d0db',
                    '32560bca-d251-4f93-bfe1-3809f94d5183',
                    '669afb34-13e4-e411-b873-e41f13c51836',
                    'dfe03264-02f8-41a0-9d06-7b03582f7cf2',
                    'bc5ba7b5-c677-43d7-ae24-3645b9482394',
                    'b35cdda9-43ac-40ae-8e1b-2711b960bf39',
                    '8412A5B2-0147-4AA3-813B-CC41D5D3D55B',  -- 福州公司、营口公司、丹东公司、通化公司
                    'B0F2292B-95B5-47DE-B50D-F1E61BDF4692',
                    '75B65764-C79A-429B-9086-427BB923294F',
                    '7220E82B-A68D-4444-8B4D-1BD5FB8C1996',
                    '1A0D7025-356E-4344-9074-C9BC416E6E66'
                )
            FOR XML PATH('')
        ), 1, 1, '');
    EXEC  dbo.usp_cb_存货分析报表 @buguid;
  