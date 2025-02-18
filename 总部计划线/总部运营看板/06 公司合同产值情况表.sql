-- 06 公司合同产值情况表
--缓存停工记录
SELECT DISTINCT
       zk.投管代码
INTO #tjxm
FROM dbo.jd_PlanTaskExecuteObjectForReport zk
WHERE zk.[是否停工] IN ( '停工', '缓建' );

SELECT flag.ProjGUID
INTO #tjxmguid
FROM erp25.dbo.vmdm_projectFlag flag
     INNER JOIN #tjxm tjxm ON flag.[投管代码] = tjxm.[投管代码]
WHERE tjxm.[投管代码] IS NOT NULL;

SELECT DISTINCT
       ContractGUID
INTO #zz
FROM
(
    SELECT cf.ContractGUID
    FROM cb_CfDtl cf
         LEFT JOIN vcb_contract vc ON cf.ContractGUID = vc.ContractGUID
    WHERE (
              cf.costcode LIKE '5001.02%'
              OR cf.costcode LIKE '5001.03%'
              OR cf.costcode LIKE '5001.04%'
              OR cf.costcode LIKE '5001.05%'
              OR cf.costcode LIKE '5001.07%'
              OR cf.costcode LIKE '5001.08%'
          )
    UNION
    SELECT vc.ContractGUID
    FROM vcb_contract vc
         LEFT JOIN cb_HtType v ON vc.HtTypeGUID = v.HtTypeGUID
    WHERE (
              v.HtTypeCode LIKE '02%'
              OR v.HtTypeCode LIKE '03%'
              OR v.HtTypeCode LIKE '04%'
              OR v.HtTypeCode LIKE '05%'
              OR v.HtTypeCode LIKE '06%'
          )
) zz;



SELECT DISTINCT
       a.ContractGUID,
       a.BUName 公司名称,
       a.ProjName AS '所属项目',
       pjfg.[项目状态],
       pjfg.[项目股权比例],
       CASE
           WHEN tjxm.ProjGUID IS NOT NULL THEN
                '是'
           ELSE '否'
       END AS '是否停工缓建',
       mp1.ProjStatus AS '项目状态_一级项目',
       mp1.ManageModeName AS '管理方式_一级项目',
       mp1.TradersWay AS '操盘方式_一级项目',
       pjfg.[工程操盘方],
       pjfg.[成本操盘方],
       pjfg.[工程状态],
       mp1.BbWay AS '并表方式_一级项目',
       mp.ProjCode 明源系统代码,
       lb.LbProjectValue 投管代码,
       a.JfProviderName AS '甲方单位',
       a.YfProviderName AS '乙方单位',
       a.ContractCode AS '合同编号',
       a.ContractName AS '合同名称',
       HtTypeName AS '合同类别',
       a.SignDate AS '签约日期',
       a.JsState AS '结算状态',
       CASE
           WHEN a.JsState = '结算' THEN
                a.JsAmount_Bz
           ELSE a.htamount + ISNULL(zz.htamount, 0)
       END AS '有效签约金额含补协',
       s.yspje AS '已审核的累计付款申请金额',
       s.spzje AS '审核中的累计付款申请金额',
       s.kkje AS '累计扣款金额',
       pay.je AS '累计已付金额',
       sd.applydate '最近一次付款申请日期',
       DATEDIFF(dd, sd.applydate, GETDATE()) AS '账龄_天',
    --    cz.ljywccz '施工单位申报现场累计产值',
    --    cz.jfljywccz AS '甲方审核现场累计产值',
    --    cz.htczljyfje AS '甲方审核合同累计应付款',
       sdsh.curljywccz as '施工单位申报现场累计产值', --施工单位申报-现场累计产值（含本次）
       sdsh.CurYfsbXcljqk as '施工单位申报现场累计应付款', -- 施工单位申报-合同累计请款（含本次）
       sdsh.curjfljywccz as '甲方审核现场累计产值',	-- 甲方审核-现场累计产值（含本次）
       sdsh.curhtczljyfje as '甲方审核合同累计应付款',	-- 甲方审核-合同累计应付款（含本次）
       czhg.Xmpdljwccz as '项目盘点累计已完成产值',
       js.BalanceDate 结算日期,
	   app.yzfcz as 已支付产值金额,
	   app.yspwzfcz as 已审核未支付产值金额,
	   app.spzcz as 审核中产值金额,
	   app.wfqcz as 未发起产值金额
FROM vcb_Contract a
     LEFT JOIN cb_HTBalance js ON a.contractguid = js.contractguid
                                  AND js.BalanceType = '结算'
     LEFT JOIN
     (
         SELECT ContractGUID,
                SUM(PayAmount) je
         FROM cb_pay
         GROUP BY ContractGUID
     ) pay ON a.contractguid = pay.contractguid
     LEFT JOIN
     (
         SELECT ContractGUID,
                SUM(ApplyAmount) sqje,
                SUM(ISNULL(ApplyAmount, 0) - ISNULL(YfAmount, 0)) AS kkje,
                SUM(   CASE
                           WHEN ApplyState IN ( '已审批', '已审核' ) THEN
                                ApplyAmount
                           ELSE 0
                       END
                   ) yspje,
                SUM(   CASE
                           WHEN ApplyState IN ( '审批中', '审核中' ) THEN
                                ApplyAmount
                           ELSE 0
                       END
                   ) spzje
         FROM dbo.cb_HTFKApply
         GROUP BY ContractGUID
     ) s ON a.ContractGUID = s.ContractGUID
     LEFT JOIN
     (
         SELECT ContractGUID,
                applydate,
                curljywccz, --施工单位申报-现场累计产值（含本次）
                CurYfsbXcljqk, -- 施工单位申报-合同累计请款（含本次）
                curjfljywccz,	-- 甲方审核-现场累计产值（含本次）
                curhtczljyfje,	-- 甲方审核-合同累计应付款（含本次）
                ROW_NUMBER() OVER (PARTITION BY ContractGUID ORDER BY applydate DESC) rownum
         FROM dbo.cb_HTFKApply
         WHERE ApplyState IN ( '已审批', '已审核', '审批中', '审核中' )
     ) sd ON a.ContractGUID = sd.ContractGUID AND sd.rownum = 1
     LEFT JOIN
     (
         SELECT ContractGUID,
                applydate,
                curljywccz, --施工单位申报-现场累计产值（含本次）
                CurYfsbXcljqk, -- 施工单位申报-合同累计请款（含本次）
                curjfljywccz,	-- 甲方审核-现场累计产值（含本次）
                curhtczljyfje,	-- 甲方审核-合同累计应付款（含本次）
                ROW_NUMBER() OVER (PARTITION BY ContractGUID ORDER BY applydate DESC) rownum
         FROM dbo.cb_HTFKApply
         WHERE ApplyState IN ( '已审批', '已审核' )
     ) sdsh ON a.ContractGUID = sdsh.ContractGUID AND sdsh.rownum = 1
     left join (
        select b.OutputValueMonthReviewGUID,
               b.ReviewDate,
               a.BusinessGUID as ContractGUID,
			   a.BusinessName,a.BusinessType,  
               Xmpdljwccz, -- 项目盘点累计完成产值
        ROW_NUMBER() OVER (PARTITION BY a.BusinessGUID ORDER BY ReviewDate DESC) rownum
        from  cb_OutputValueReviewDetail a
        inner join  cb_OutputValueMonthReview b on a.OutputValueMonthReviewGUID =b.OutputValueMonthReviewGUID
     -- where a.BusinessName ='苏州市姑苏区金门路北项目桩基工程'
     ) czhg ON a.ContractGUID = czhg.ContractGUID AND czhg.rownum = 1
     LEFT JOIN p_Project p ON p.ProjCode = CASE
                                               WHEN LEN(a.ProjectCode) > 1
                                                    AND CHARINDEX(';', a.ProjectCode) < 1 THEN
                                                    a.ProjectCode
                                               WHEN LEN(a.ProjectCode) > 1
                                                    AND CHARINDEX(';', a.ProjectCode) >= 1 THEN
                                                    LEFT(a.ProjectCode, CHARINDEX(';', a.ProjectCode) - 1)
                                               ELSE NULL
                                           END
     LEFT JOIN ERP25.dbo.mdm_Project mp ON mp.ProjGUID = p.ProjGUID
     LEFT JOIN ERP25.dbo.mdm_Project mp1 ON mp.ParentProjGUID = mp1.ProjGUID
     LEFT JOIN ERP25.dbo.mdm_LbProject lb ON lb.projGUID = ISNULL(mp.ParentProjGUID, mp.ProjGUID)
                                             AND lb.LbProject = 'tgid'
     LEFT JOIN ERP25.dbo.vmdm_projectFlag pjfg ON mp1.ProjGUID = pjfg.ProjGUID
     LEFT JOIN
     (
         SELECT z.MasterContractGUID,
                SUM(z.HtAmount) htamount
         FROM cb_Contract z
         WHERE z.MasterContractGUID IS NOT NULL
               AND z.ApproveState IN ( '审核中', '已审核' )
               AND z.HtProperty = '补充合同'
               AND z.IfDdhs = 0
         GROUP BY z.MasterContractGUID
     ) zz ON a.ContractGUID = zz.MasterContractGUID
     LEFT JOIN cb_Contract y ON a.ContractGUID = y.ContractGUID
     LEFT JOIN cb_contractCZ cz ON a.ContractGUID = cz.ContractGUID
     LEFT JOIN #tjxmguid tjxm ON mp1.ProjGUID = tjxm.ProjGUID
	 LEFT JOIN (
	    select a.contractguid,
		sum(a.jfljywccz) as jfljywccz,
		SUM(ISNULL(b.sumpayamount,0)) as yzfcz, 
		isnull( (select sum(app.applyamount) from cb_htfkapply app where app.contractguid =a.contractguid and app.applystate='已审核') ,0) - SUM(ISNULL(b.sumpayamount,0)) -isnull( ( select isnull(sum(isnull(kkamount,0)),0) from cb_kkmx k where k.htfkplanguid in (select htfkapplyguid from cb_htfkapply app where app.applystate='已审核' and app.contractguid = a.contractguid) ),0) yspwzfcz, 
		isnull(( select sum(app.curjfljywccz)-sum(a.jfljywccz) from cb_htfkapply app where app.contractguid=a.contractguid and app.applystate='审核中' ),0) spzcz ,
		SUM(isnull(b.htamount,0)) + SUM(isnull(b.sumalteramount,0))- SUM(isnull(a.jfljywccz,0)) wfqcz 
		from cb_contractcz a 
		left join dbo.cb_contract b on b.contractguid = a.contractguid
		group by a.contractguid
	 ) app on app.contractguid= a.contractguid
WHERE (1 = 1)
      AND a.IsFyControl = 0
      --AND YEAR(a.SignDate) >= 2020
      AND a.HtClass = '已定合同'
      AND HtTypeName NOT LIKE '%土地类%'
      AND a.ContractGUID IN (
                                SELECT ContractGUID FROM #zz
                            )
      --AND a.HtAmount+ isnull(zz.HtAmount,0) > pay.je 
      AND
      (
          a.HtProperty IN ( '多方合同', '三方合同', '直接合同' )
          OR y.IfDdhs = 1
      )
     AND a.buguid IN ( @var_buguid )
     AND a.signdate   BETWEEN @var_begindate AND @var_enddate
ORDER BY a.BUName,
         a.ProjName;

DROP TABLE #zz;
DROP TABLE #tjxm;
DROP TABLE #tjxmguid;
