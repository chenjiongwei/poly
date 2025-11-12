SELECT *
FROM (
    SELECT
        s_PayForm.ProjGUID AS ProjGUID,
        PayformGUID,
        PayformName,
        PayFormType,
        DisCount,
        AjZero,
        GjjZero,
        (CASE WHEN IsDaiKuan IS NULL OR IsDaiKuan = 0 THEN '否' ELSE '是' END) AS IsDaiKuan,
        (CASE WHEN IsAj IS NULL OR IsAj = 0 THEN '否' ELSE '是' END) AS IsAj,
        (CASE WHEN IsGjj IS NULL OR IsGjj = 0 THEN '否' ELSE '是' END) AS IsGjj,
        AjBank,
        GjjBank,
        ProjName,
        BgnDate,
        s_PayForm.EndDate,
        (CASE WHEN Scope = '项目' THEN '所有楼栋' ELSE CONVERT(VARCHAR(8000), BldNameList) END) AS BldNameList,
        BldGUIDList,
        Scope
    FROM (
        SELECT
            a.*,
            b.buguid,
            b.projname
        FROM
            s_PayForm a,
            p_Project b
        WHERE
            a.ProjGUID = b.ProjGUID
            AND (
                (SELECT CONVERT(VARCHAR(10), a.EndDate, 120)) >= (SELECT CONVERT(VARCHAR(10), GETDATE(), 120))
                OR a.EndDate IS NULL
            )
    ) s_PayForm
) s_payform
WHERE
    (1 = 1)
    AND (2 = 2)
    AND s_PayForm.ProjGUID IN [项目过滤]