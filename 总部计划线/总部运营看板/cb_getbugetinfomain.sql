USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_cb_GetBudgetInfoMain]    Script Date: 2025/2/26 16:54:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
ALTER  PROC [dbo].[usp_cb_GetBudgetInfoMain]       
(
      @ProjGUID UNIQUEIDENTIFIER ,     --项目      
      @State   VARCHAR(20),             --合同汇总，已签约、未签约  
	  @BudgetName  NVARCHAR(400)           --合约规划名称（合同名称）
)
AS	
BEGIN
  

	--已签约的合同
	SELECT 
	 c.ContractGUID
	,c.ContractName
	,c.bgxs 
	,b.ExecutingBudgetGUID
	,c.HtClass 
	,c.JsState
	,SUM(a.CfAmount) AS HtCfAmount
	,SUM(a.YgAlterAmount) AS  YgAlterAmount
	INTO  #HT
	FROM  dbo.cb_BudgetUse a
	INNER JOIN dbo.cb_Budget b ON b.BudgetGUID = a.BudgetGUID 
	INNER JOIN cb_Contract c ON c.ContractGUID=a.RefGUID
	INNER JOIN dbo.p_Project p ON a.ProjectCode=p.ProjCode
	WHERE a.IsApprove=1 AND	 c.IfDdhs=1
	AND p.ProjGUID=@ProjGUID
	GROUP BY  c.ContractGUID,c.ContractName,c.bgxs, b.ExecutingBudgetGUID,c.HtClass ,c.JsState


	--已结算合同-已定合同
	SELECT
	d.ExecutingBudgetGUID
	,SUM(c.JsAmount) AS JsAmount
	INTO  #JS
	FROM dbo.cb_HTBalance a
	INNER JOIN cb_HTAlter b ON a.HTBalanceGUID=b.RefGUID
	INNER JOIN dbo.cb_BudgetUse c ON c.RefGUID=b.HTAlterGUID
	INNER JOIN dbo.cb_Budget d ON d.BudgetGUID = c.BudgetGUID 
	INNER JOIN dbo.p_Project p ON c.ProjectCode=p.ProjCode
	WHERE c.IsApprove=1  	
	AND p.ProjGUID=@ProjGUID
	GROUP BY d.ExecutingBudgetGUID

	


	--非现金变更
	SELECT
	d.ExecutingBudgetGUID
	,SUM(c.CfAmount) AS fxjAmount
	INTO  #FXJ
	FROM cb_HTAlter b 
	INNER JOIN dbo.cb_BudgetUse c ON c.RefGUID=b.HTAlterGUID
	INNER JOIN dbo.cb_Budget d ON d.BudgetGUID = c.BudgetGUID 
	INNER JOIN dbo.p_Project p ON c.ProjectCode=p.ProjCode
	WHERE c.IsApprove=1  AND b.IsFromXyl=1
	AND p.ProjGUID=@ProjGUID
	GROUP BY d.ExecutingBudgetGUID


	
	--合约规划关联采购方案
	SELECT ExecutingBudgetGUID,CgPlanAmount
	INTO #CgPlan FROM (
		SELECT
		 a.ExecutingBudgetGUID
		,a.Amount  AS  CgPlanAmount
		,ROW_NUMBER() OVER (PARTITION BY a.ExecutingBudgetGUID ORDER BY a.createdate desc) rowno
		FROM dbo.cb_BudgetCgPlanAmount a
		INNER JOIN  dbo.cb_Budget_Executing b ON b.ExecutingBudgetGUID = a.ExecutingBudgetGUID
		WHERE b.ProjectGUID=@ProjGUID
	)  aa WHERE aa.rowno=1


	--预呈批
	SELECT  
	 ExecutingBudgetGUID
	,PreAmount
	,BudgetAmount
	INTO #Pre
	FROM (
		SELECT  
			 ExecutingBudgetGUID
			,PreAmount
			,BudgetAmount
			,ROW_NUMBER() OVER (PARTITION BY ExecutingBudgetGUID ORDER BY SignDate DESC,PreContractGUID) rowno
		FROM (
			SELECT 
			 d.ExecutingBudgetGUID
			,SUM(c.CfAmount) AS  PreAmount
			,SUM(c.BudgetAmount) AS  BudgetAmount
			,a.PreContractGUID
			,a.SignDate
			FROM dbo.cb_Contract_Pre a
			INNER JOIN dbo.cb_BudgetUse c ON c.RefGUID=a.PreContractGUID
			INNER JOIN dbo.cb_Budget d ON d.BudgetGUID = c.BudgetGUID 
			INNER JOIN dbo.p_Project p ON c.ProjectCode=p.ProjCode
			WHERE a.ApproveState IN ('审核中','已审核')
			AND p.ProjGUID=@ProjGUID 
			GROUP BY d.ExecutingBudgetGUID,a.PreContractGUID,a.SignDate
		) aa 
	)aaa WHERE aaa.rowno=1

	--已发生
	SELECT b.ExecutingBudgetGUID
	,SUM(ISNULL(f.CfAmount,0) )   AS YfsCost
	,SUM(CASE WHEN c.HTAlterGUID IS NOT NULL THEN  ISNULL(f.CfAmount,0) ELSE 0 END) ylj_yfs
	INTO #yfs
	FROM  cb_BudgetUse f  
	INNER JOIN dbo.cb_Budget b ON b.BudgetGUID = f.BudgetGUID
	INNER JOIN dbo.p_Project p ON p.ProjCode=f.ProjectCode
	LEFT JOIN  dbo.cb_HTAlter c ON c.HTAlterGUID=f.RefGUID AND c.isUseYgAmount=1
	WHERE  f.IsApprove = 1 
	AND ISNULL(f.IsFromXyl,0)=0
	AND p.ProjGUID=@ProjGUID  
	GROUP  BY b.ExecutingBudgetGUID

	--预留金额
	SELECT b.ExecutingBudgetGUID 
	,ISNULL(SUM(a.CfAmount),0)  AS YgYeAmount
	,ISNULL(SUM(a.ygAlterAdj),0) AS ygAlterAdj
	INTO #ylj
	FROM cb_YgAlter2Budget a
	INNER JOIN dbo.cb_Budget b ON b.BudgetGUID = a.BudgetGUID
	where b.ProjectGUID=@ProjGUID  
	GROUP  BY b.ExecutingBudgetGUID


	--上一版合约规划
	SELECT ex.ExecutingBudgetGUID,
	CASE WHEN aa.ExecutingBudgetGUID IS NULL THEN  ex.BudgetAmount ELSE ISNULL(aa.BudgetAmount,0) END  AS UpBudgetAmount
	INTO #UpBudget
	FROM  dbo.cb_Budget_Executing ex
	LEFT JOIN (
		SELECT a.ExecutingBudgetGUID
		,a.BudgetAmount
		,ROW_NUMBER() OVER(PARTITION BY a.ExecutingBudgetGUID ORDER BY a.UpdateDate DESC) AS rowno 
		FROM  cb_BudgetAmountVer a
		LEFT JOIN cb_Budget_Executing b ON a.ExecutingBudgetGUID=b.ExecutingBudgetGUID
		WHERE b.ProjectGUID=@ProjGUID
	) aa on aa.rowno=2 AND ex.ExecutingBudgetGUID=aa.ExecutingBudgetGUID
	WHERE ex.ProjectGUID=@ProjGUID


	
	--负数补协 负数补协(不含暂转固）
	SELECT b.ExecutingBudgetGUID, 
	ISNULL(SUM(f.CfAmount),0)  FsBxAmount
	INTO  #fsBx
	FROM  cb_BudgetUse f  
	INNER JOIN dbo.cb_Budget b ON b.BudgetGUID = f.BudgetGUID
	INNER JOIN cb_HTAlter g ON f.RefGUID = g.HTAlterGUID  
	INNER JOIN dbo.cb_Contract ct ON  g.RefGUID=ct.ContractGUID 
	INNER JOIN dbo.p_Project p ON p.ProjCode=f.ProjectCode
	WHERE f.CfSource = '变更' 
		  AND f.IsApprove = 1  
		  AND g.AlterType='附属合同'
		  AND ct.ZzgHTBalanceGUID IS NULL
		  AND g.AlterAmount<0
		  AND p.ProjGUID=@ProjGUID  
	GROUP BY	b.ExecutingBudgetGUID


	--暂转固
	--项目下所有的转固变更
	SELECT DISTINCT  b.ContractGUID,b.HTAlterGUID ,a.ApproveDate
	INTO #ZZGBG
	FROM dbo.cb_Contract a
	INNER JOIN dbo.cb_HTAlter b ON a.ContractGUID=b.RefGUID
	INNER JOIN  dbo.cb_BudgetUse bu ON bu.RefGUID=b.HTAlterGUID 
	INNER JOIN dbo.p_Project p ON p.ProjCode=bu.ProjectCode
	WHERE  p.ProjGUID=@ProjGUID and   b.AlterType='附属合同' AND a.ZzgHTBalanceGUID IS NOT NULL 

	--获取合同最新的暂转固合约规划金额 
	SELECT d.ExecutingBudgetGUID,ISNULL(SUM(c.ZzgAmount),0) AS ZzgAmount
	INTO #ZZG
	FROM dbo.cb_BudgetUse c
	INNER JOIN dbo.cb_Budget d ON d.BudgetGUID =c.BudgetGUID
	INNER JOIN dbo.p_Project p ON p.ProjCode=c.ProjectCode
	INNER JOIN  (
		SELECT ContractGUID
		,HTAlterGUID 
		,ROW_NUMBER() OVER(PARTITION BY ContractGUID ORDER BY ApproveDate desc) rowno 
		FROM #ZZGBG
	) aa  ON c.RefGUID=aa.HTAlterGUID AND  aa.rowno=1
	WHERE p.ProjGUID=@ProjGUID  
	GROUP BY d.ExecutingBudgetGUID


	--------------------------

	SELECT 
	b.HtTypeCode,
	c.ParentCode+'.'+'#'+REPLACE( c.ParentCode,'.','_') code
	,c.BudgetCode as  hykCode
	,a.WorkingBudgetGUID
	,CASE WHEN js.ExecutingBudgetGUID IS NOT NULL OR (ht.HtClass='已定非合同' AND  ht.JsState='结算')  THEN '已结算'  
		  WHEN ht.ExecutingBudgetGUID IS NOT NULL THEN '未结算'		  
		  WHEN pre.ExecutingBudgetGUID IS NOT NULL THEN '预呈批'
		  WHEN cg.ExecutingBudgetGUID IS NOT NULL THEN '采购方案'
		  ELSE '未签约'
	      END AS StateName
	,a.BigHTTypeGUID 
	,b.HtTypeName AS  BigHTTypename
	,a.BudgetLibraryGUID 
	,c.BudgetName AS BudgetLibraryName
	,CASE WHEN ht.ContractGUID IS NOT NULL THEN ht.ContractName ELSE a.BudgetName END  AS  BudgetName
	,a.BudgetCode
	,CASE WHEN pre.ExecutingBudgetGUID IS NOT NULL THEN ISNULL(pre.BudgetAmount,isnull(ex.BudgetAmount,0))
		  WHEN cg.ExecutingBudgetGUID IS NOT NULL THEN  ISNULL(cg.CgPlanAmount,isnull(ex.BudgetAmount,0))
		  ELSE ISNULL(up.UpBudgetAmount,isnull(ex.BudgetAmount,0)) 
	      END AS BudgetAmount 
	,CASE WHEN ht.ExecutingBudgetGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0) +ISNULL(ylj.YgYeAmount,0)
		  ELSE a.BudgetAmount  
		  END  AS  NewBudgetAmount
	,CASE WHEN js.ExecutingBudgetGUID IS NOT NULL OR (ht.HtClass='已定非合同' AND  ht.JsState='结算')  THEN ''  
	      WHEN  ht.ExecutingBudgetGUID IS NOT NULL  AND js.ExecutingBudgetGUID IS  NULL THEN  '<span style="color:#35A6F2;cursor:pointer;margin-left:15px;" onclick = "parent.YGAlter(''' + CONVERT(VARCHAR(50), a.WorkingBudgetGUID) + ''');">调整预留金</span>'  
		  WHEN ht.ExecutingBudgetGUID IS NULL THEN  '<span style="color:#35A6F2;cursor:pointer;"  onclick = "parent.editBudget('''+ CONVERT(VARCHAR(50), a.WorkingBudgetGUID)+ ''');" >编辑</span><span style="color:#35A6F2;cursor:pointer;margin-left:15px;"  onclick = "parent.CF('''+ CONVERT(VARCHAR(50), a.WorkingBudgetGUID)+ ''');" >拆分</span><span style="color:#35A6F2;cursor:pointer;margin-left:15px;" onclick = "parent.DelBudget(''' + CONVERT(VARCHAR(50), a.WorkingBudgetGUID) + ''');">删除</span>'
	      END AS  cz
	,ISNULL(ht.HtCfAmount,0) AS HtAmount
	,zzg.ZzgAmount AS ZzgAmount
	,ISNULL(fs.FsBxAmount,0) AS fsbxAmount
	, CASE WHEN  (ht.HtClass='已定非合同' AND  ht.JsState='结算') THEN ht.HtCfAmount ELSE(  CASE WHEN js.ExecutingBudgetGUID IS NOT NULL   THEN ISNULL(js.JsAmount,0) - ISNULL(fxj.fxjAmount,0) ELSE ISNULL(js.JsAmount,0) END) END	 AS JsAmount
	,ISNULL(CASE WHEN  zzg.ExecutingBudgetGUID IS NULL THEN  
			  CASE WHEN ht.bgxs IS  NULL THEN 0  
			  WHEN ht.bgxs='总价包干' THEN ul.TotalPriceUL 
			  ELSE ul.PriceUL END
		    ELSE ul.TotalPriceUL  END,0) AS ckrate
	,ISNULL(CASE WHEN  zzg.ExecutingBudgetGUID IS NULL THEN  
				CASE WHEN ht.bgxs IS  NULL THEN 0  
				WHEN ht.bgxs='总价包干' THEN ex.YGTotalPriceULAdjust 
				ELSE ex.YGPriceULAdjust END
	        ELSE ex.YGTotalPriceULAdjust END ,0)  AS yljRate
	,ISNULL(ht.YgAlterAmount,0) +ISNULL(ylj.ygAlterAdj,0) AS  YljAmount
	,ISNULL(yfs.ylj_yfs,0) AS  YljAmount_Yfs
	,CASE WHEN ht.ContractGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0)+ISNULL(ylj.YgYeAmount,0)
		ELSE ex.BudgetAmount END	
	AS  DTCost
	,ISNULL(fxj.fxjAmount,0) AS  FxjAmount
	,ISNULL(CASE WHEN ht.ContractGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0)+ISNULL(ylj.YgYeAmount,0)
		ELSE ex.BudgetAmount END,0) + ISNULL(fxj.fxjAmount,0)	 AS  FxjDTCost
	,ISNULL(CASE WHEN pre.ExecutingBudgetGUID IS NOT NULL THEN ISNULL(pre.BudgetAmount,isnull(ex.BudgetAmount,0))
		  WHEN cg.ExecutingBudgetGUID IS NOT NULL THEN  ISNULL(cg.CgPlanAmount,isnull(ex.BudgetAmount,0))
		  ELSE ISNULL(up.UpBudgetAmount,isnull(ex.BudgetAmount,0)) 
	      END,0)- ISNULL(CASE WHEN ht.ContractGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0)+ISNULL(ylj.YgYeAmount,0)
		ELSE ex.BudgetAmount END,0)  AS  YL,
		0  AS isedite,
		CASE WHEN ht.ContractGUID IS NOT NULL THEN 'Green'    
		ELSE
		 CASE a.ApproveState
              WHEN '未审核'
              THEN CASE a.ModifyType
                     WHEN 0 THEN ( CASE WHEN (CASE WHEN	  l.WorkingBudgetGUID IS null THEN 0 ELSE 1 END)  = 1 THEN '√'
                                        ELSE 'Blue'
                                   END )--未修改                          
                     WHEN 1 THEN ( CASE WHEN (CASE WHEN	 l.WorkingBudgetGUID IS null THEN 0 ELSE 1 END) = 1 THEN '√'
                                        ELSE 'Blue'
                                   END )--新增                          
                     WHEN 2
                     THEN ( CASE WHEN (CASE WHEN	 l.WorkingBudgetGUID IS null THEN 0 ELSE 1 END) = 1 THEN '√'--修改                           
                                 ELSE 'Blue'
                            END )
                     WHEN 3 THEN '×'--删除                          
                     ELSE ''
                   END
              WHEN '已审核'
              THEN CASE a.ModifyType
                     WHEN 0
                     THEN ( CASE WHEN (CASE WHEN	 l.WorkingBudgetGUID IS null THEN 0 ELSE 1 END) = 1 THEN '√'
                                 ELSE CASE WHEN IsUseable = 0 THEN ''--√                          
                                           ELSE CASE WHEN a.IfEnd = 0 THEN '√'
                                                     ELSE 'Blue'
                                                END
                                      END
                            END )--未修改                          
                     WHEN 1
                     THEN ( CASE WHEN (CASE WHEN	 l.WorkingBudgetGUID IS null THEN 0 ELSE 1 END) = 1 THEN '√'--修改                           
                                 ELSE 'Blue'
                            END )--新增                          
                     WHEN 2
                     THEN ( CASE WHEN (CASE WHEN	l.WorkingBudgetGUID IS null THEN 0 ELSE 1 END) = 1 THEN '√'--修改                           
                                 ELSE 'Blue'
                            END )
                     WHEN 3 THEN '×'--删除                          
                     ELSE ''
                   END
              WHEN '审核中' THEN 'Lock' END              
        END flag      

		 
	INTO #budget
	FROM dbo.cb_Budget_Working a
	LEFT JOIN dbo.cb_Budget_Executing ex ON ex.ExecutingBudgetGUID=a.WorkingBudgetGUID
	LEFT JOIN #UpBudget up ON up.ExecutingBudgetGUID = ex.ExecutingBudgetGUID
	LEFT JOIN dbo.cb_HtType b ON a.BigHTTypeGUID=b.HtTypeGUID
	LEFT JOIN dbo.cb_BudgetLibrary c ON c.BudgetLibraryGUID=a.BudgetLibraryGUID
	LEFT JOIN dbo.cb_YLAmountUpperLimit ul ON ul.BudgetLibraryGUID=a.BudgetLibraryGUID
	LEFT JOIN #JS js ON js.ExecutingBudgetGUID=a.WorkingBudgetGUID
	LEFT JOIN #HT ht ON ht.ExecutingBudgetGUID = a.WorkingBudgetGUID
	LEFT JOIN #Pre pre ON pre.ExecutingBudgetGUID = a.WorkingBudgetGUID
	LEFT JOIN #CgPlan cg ON cg.ExecutingBudgetGUID = a.WorkingBudgetGUID
	LEFT JOIN #yfs yfs ON yfs.ExecutingBudgetGUID=a.WorkingBudgetGUID
	LEFT JOIN #ylj ylj ON ylj.ExecutingBudgetGUID=a.WorkingBudgetGUID
	LEFT JOIN #Fxj fxj ON fxj.ExecutingBudgetGUID=a.WorkingBudgetGUID
	LEFT JOIN #fsBx  fs ON fs.ExecutingBudgetGUID=a.WorkingBudgetGUID
	LEFT JOIN #ZZG zzg ON zzg.ExecutingBudgetGUID = a.WorkingBudgetGUID
	LEFT JOIN cb_Budget_Working_UserLock l ON l.WorkingBudgetGUID = a.WorkingBudgetGUID
	WHERE  a.ProjectGUID=@ProjGUID
    

	DECLARE @Sql NVARCHAR(600)=''
	DECLARE @SqlWhere NVARCHAR(500)=''
	IF	(@State='已签约')
	BEGIN
		SET @SqlWhere= ' AND StateName IN (''未结算'',''已结算'')  '
	END
	ELSE IF	(@State='未签约')
	BEGIN
	SET @SqlWhere= ' AND StateName NOT IN (''未结算'',''已结算'')  '
	END

	IF	(@BudgetName IS NOT NULL  AND  @BudgetName <>'')
	BEGIN
		SET @SqlWhere=@SqlWhere+ ' AND BudgetName like ''%'+@BudgetName+'%''  '
	END
	SET	@Sql= 'SELECT * FROM  #budget WHERE 1=1 '+ @SqlWhere +  ' ORDER BY HtTypeCode,code,hykcode  '
	PRINT	 @Sql
	EXEC (@Sql)
END

