SELECT
    [buguid],
    [projguid],
    [清洗日期],
    [税前成本利润率_动态版],
    [税前成本利润率_立项版],
    CASE 
        WHEN [税前成本利润率_动态版] IS NOT NULL AND [税前成本利润率_立项版] IS NOT NULL
        THEN ISNULL([税前成本利润率_立项版], 0) - ISNULL([税前成本利润率_动态版], 0)
    END AS [税前成本利润率偏差], 

    [税前利润_动态版],
    [税前利润_立项版],
    CASE 
        WHEN [税前利润_动态版] IS NOT NULL AND [税前利润_立项版] IS NOT NULL
        THEN ISNULL([税前利润_立项版], 0) - ISNULL([税前利润_动态版], 0)
    END AS [税前利润偏差],

    [销售净利率_动态版],
    [销售净利率_立项版],
    CASE 
        WHEN [销售净利率_动态版] IS NOT NULL AND [销售净利率_立项版] IS NOT NULL
        THEN ISNULL([销售净利率_立项版], 0) - ISNULL([销售净利率_动态版], 0)
    END AS [销售净利率偏差],

    [税后利润_动态版],
    [税后利润_立项版],
    CASE 
        WHEN [税后利润_动态版] IS NOT NULL AND [税后利润_立项版] IS NOT NULL
        THEN ISNULL([税后利润_立项版], 0) - ISNULL([税后利润_动态版], 0)
    END AS [税后利润偏差],

    [留存资产_动态版],
    [留存资产_立项版],
    [税后现金利润_动态版],
    [税后现金利润_立项版],
    CASE 
        WHEN [税后现金利润_动态版] IS NOT NULL AND [税后现金利润_立项版] IS NOT NULL
        THEN ISNULL([税后现金利润_立项版], 0) - ISNULL([税后现金利润_动态版], 0)
    END AS [税后现金利润偏差],

    [已实现税后利润_动态版],
    [已实现销售净利率_动态版],
    [未实现税后利润_动态版]
FROM zb_jyjhtjkb_Profit
WHERE
    DATEDIFF(DAY, [清洗日期], ${qxDate} ) = 0




-- http://172.16.8.132/_controls/AppGridEx/AppGridEShow.aspx?time=638947614890159805&DataPath=0a1be9c3-3c6b-4625-b702-daee87cc4111.xml&Location=

SELECT
    dtl.Guid,
    dtl.ProjGUID,
    dtl.Year,
    dtl.SaleTarget / 10000 AS SaleTarget,
    ROUND(ISNULL(sale.FactAmount, 0) / 10000, 2) AS SaleFact,
    dtl.SaleRate,
    dtl.SaleFee / 10000 AS SaleFee,
    dtl.MngRate,
    dtl.MngFee / 10000 AS MngFee,
    dtl.CwRate,
    dtl.CwFee / 10000 AS CwFee,
    ROUND(isnull(dtl.FactAmount, 2) / 10000, 2) AS FactAmount
FROM
    fy_Proj_FeeTargetDtl dtl
    OUTER APPLY (
        SELECT
            SUM(FactAmount) AS FactAmount
        FROM
            (
                -- 一级项目 
                SELECT
                    fact.FactAmount
                FROM
                    fy_FactSaleSignDtl fact
                    INNER JOIN p_Project proj ON proj.ProjGUID = fact.ProjGUID
                    INNER JOIN p_Project par ON par.ProjCode = proj.ParentCode
                    AND par.BUGUID = proj.BUGUID
                WHERE
                    par.ProjGUID = dtl.ProjGUID
                    AND par.IfEnd = 0
                    AND LEFT(fact.YearMonth, 4) = dtl.Year
                UNION
                ALL -- 分期项目 
                SELECT
                    fact.FactAmount
                FROM
                    fy_FactSaleSignDtl fact
                    INNER JOIN p_Project proj ON proj.ProjGUID = fact.ProjGUID
                WHERE
                    proj.ProjGUID = dtl.ProjGUID
                    AND proj.IfEnd = 1
                    AND LEFT(fact.YearMonth, 4) = dtl.Year
            ) t
    ) sale
WHERE
    2 = 2
ORDER BY
    dtl.Year



双拼高级P22-mpbcy-1；双拼高级P23-mpbcy-1；双拼高级P9-mpbcy-1；双拼高级P19-mpbcy-1；双拼高级P20-mpbcy-1；双拼高级P16-mpbcy-1；双拼地下面积-2-mpbcy-1；双拼高级P15-mpbcy-1；双拼高级P17-mpbcy-1；联排L6-mpbcy-1；联排L7-mpbcy-1；双拼高级P14-mpbcy-1；双拼高级P13-mpbcy-1；双拼高级P24-mpbcy-1；双拼高级P8-mpbcy-1；叠拼D3-mpbcy-1；联排L5-mpbcy-1；联排L8-zxbcy-1；双拼高级P18-mpbcy-1；双拼高级P21-mpbcy-1；双拼高级P11-mpbcy-1；双拼高级P10-mpbcy-1；双拼高级P12-mpbcy-1；双拼地下面积-1-mpbcy-1；



01e74ca9-2d93-4611-a9b3-3127a2532403；a25d5da3-8b16-4d8e-9d07-4bb566bb4cb8；7f93b37d-85fb-4def-b4da-7a2d89afbfa3；e2bcb0a4-eed1-4d2b-b800-f072c176e8fe；668a6f27-e81c-461e-b73c-1b71e6244e9c；72d52328-8785-46be-8872-23ccfe55fffc；a83c72c3-edf4-4f22-8aaf-17f8fdd1dfdf；96a1a6df-2cec-4041-affb-4474f4ce6c98；70d9a839-b704-452d-8de7-7112ac3ce431；e22e03cc-037c-4f8b-aed8-a9494ba0c102；9b0750cc-3081-4a6a-b55a-808a366075e3；5aa08fc5-b3f7-46c0-b9b4-9316865573e6；208c50c1-431a-46b6-98b8-9507667b8f9e；68eaab92-321b-43da-83c4-885e61943781；cb8f90a0-90df-4674-b8ea-d3129f2f7252；8dca2c6a-d7cf-4364-b5df-f1c84670a7ac；cf1c47f1-9ab6-4eb7-a533-e8776874c39a；7deb09fa-43db-47b7-8c4f-48548c146164；73999a70-2e11-4124-8012-397c4c94fe19；206e0d16-f711-405a-9f83-308f6fbaa341；957744fc-9f4f-4219-a4c7-f1265b334b89；0147d50d-4fd9-47a0-a8db-08cfeda8d0e0；e7fd026e-e9ae-4614-b04b-ae65ba962d1d；5264538f-c8c5-44c7-87c6-de8973a9ff4a；
