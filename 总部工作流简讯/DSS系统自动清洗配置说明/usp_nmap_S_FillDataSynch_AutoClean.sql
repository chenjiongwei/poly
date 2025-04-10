
/************************************************************************
* 功能：数据填报清洗-批次自动清洗
* 参数：
*		@CleanDate 清洗日期（精确到天）
*		@FillName,@FillHistoryGUID	可选参数，如果传入这两个参数，则只清洗@FillName填报数据集下的@FillHistoryGUID填报批次（若批次已审核则不执行清洗，目前用于选择指定批次进行重新取值
* 返回值：
*		本次执行清洗的个数（如：指定批次进行清洗时，如果批次已审核，则返回值为0）
* * 
*************************************************************************/
ALTER PROC [dbo].[usp_nmap_S_FillDataSynch_AutoClean]
(
	@CleanDate DATETIME
	,@FillName VARCHAR(100)=NULL
	,@FillHistoryGUID UNIQUEIDENTIFIER=NULL
)
AS
BEGIN
	--0.准备参数
	--0.1 数据库名称（跨库清洗表前缀）
	SELECT ApplicationCode
		,CASE WHEN ipaddress IS NULL OR ipaddress = '.' THEN ''
              ELSE '[' + ipaddress + '].'
              END 
		 + CASE WHEN dbname IS NULL OR dbname = '' THEN ''
			  ELSE '[' + dbname + '].dbo.'
              END AS DatabaseName
	INTO #DBNameDict
	FROM dbo.nmap_S_DataBaseSetting
	
	--1.准备清洗规则清单表		
	SELECT ROW_NUMBER() OVER(ORDER BY NSFDSR.SynchOrder) AS ID,NSFDSR.FillName
		,NSFDSR.SynchStorName
		,ISNULL(DND.DatabaseName,'') AS DatabaseName
	INTO #ToDoFillData
	FROM dbo.nmap_S_FillDataSynchRule AS NSFDSR
		LEFT JOIN #DBNameDict AS DND ON NSFDSR.SystemType=DND.ApplicationCode
	WHERE ISNULL(@FillName,'') ='' OR ( @FillName=NSFDSR.FillName AND  NSFDSR.FillName<>'价格填报')

	--2.找到每个填报集当前需要执行清洗的批次
	--	TIP：当前执行批次的条件
	--		1、填报批次：状态为“未审核”
	--		2、填报批次：“当前清洗日期”在批次的统计开始日期和统计结束日期范围内
	--	TIP：判断是否当前批次的规则
	--		1、如果填报集填报周期为“月度”，如当前批次的统计日期在清洗日期所在月则为当前批次
	--		2、如果填报集填报周期为“季度”，如当前批次的统计日期在清洗日期所在季则为当前批次
	--		3、如果填报集填报周期为“年度”，如当前批次的统计日期在清洗日期所在年则为当前批次
	SELECT  ROW_NUMBER() OVER(ORDER BY TDFD.ID) AS ID
	       ,TDFD.SynchStorName
	       ,TDFD.DatabaseName
		   ,NFFH.FillHistoryGUID
		   ,CASE 
				WHEN NFFD.GeneratePeriodType='月度' AND @CleanDate BETWEEN DATEADD(month,DATEDIFF(month,0,NFFH.BeginDate),0) AND DATEADD(DAY,-1,DATEADD(month,DATEDIFF(month,0,NFFH.EndDate)+1,0))  THEN 1
				WHEN NFFD.GeneratePeriodType='季度' AND @CleanDate BETWEEN DATEADD(quarter,DATEDIFF(quarter,0,NFFH.BeginDate),0) AND DATEADD(DAY,-1,DATEADD(quarter,DATEDIFF(quarter,0,NFFH.EndDate)+1,0)) THEN 1
				WHEN NFFD.GeneratePeriodType='年度' AND @CleanDate BETWEEN DATEADD(year,DATEDIFF(year,0,NFFH.BeginDate),0) AND DATEADD(DAY,-1,DATEADD(year,DATEDIFF(year,0,NFFH.EndDate)+1,0)) THEN 1
				ELSE 0          
			END AS IsCurrFillHistory
	INTO #ToDoFillHistory
	FROM #ToDoFillData AS TDFD
		INNER JOIN dbo.nmap_F_FillData AS NFFD ON TDFD.FillName = NFFD.FillName
		INNER JOIN dbo.nmap_F_FillHistory AS NFFH ON NFFD.FillDataGUID = NFFH.FillDataGUID
	WHERE NFFH.ApproveStatus='未审核' AND (NFFH.FillHistoryGUID=@FillHistoryGUID OR (@FillHistoryGUID IS NULL AND @CleanDate BETWEEN NFFH.BeginDate AND NFFH.EndDate))
	
	--3.循环执行清洗
	--TIP：存储过程参数说明
	--		1、清洗日期（精确到天）
	--		2、数据库名称（跨数据库清洗使用）
	--		3、填报批次GUID
	--		4、是否当前批次
	DECLARE @i INT,@RowCount INT,@SQL varchar(1000),@TempErrorProcedure VARCHAR(200)
	SELECT @i=1,@RowCount=@@ROWCOUNT

	WHILE(@i<=@RowCount)
	BEGIN
		SELECT @SQL='EXEC [' +TDFH.SynchStorName +'] '
				+'@CleanDate='''+CONVERT(VARCHAR(50),@CleanDate,120) +''''
				+',@DataBaseName='''+REPLACE(TDFH.DatabaseName,'''','''''') +''''
				+',@FillHistoryGUID='''+CONVERT(VARCHAR(36),TDFH.FillHistoryGUID) +''''
				+',@IsCurrFillHistory='+CONVERT(VARCHAR(1),TDFH.IsCurrFillHistory)
		FROM #ToDoFillHistory AS TDFH
		WHERE TDFH.ID=@i

		BEGIN TRANSACTION
		BEGIN TRY	
			EXEC(@SQL)

			IF (XACT_STATE()) = -1
			BEGIN
				
				ROLLBACK TRANSACTION;
			END
			IF (XACT_STATE()) = 1
			BEGIN
				COMMIT TRANSACTION;   
			END
		END TRY
		
		BEGIN CATCH
			--统一错误处理（抛出异常）,并指定异常存储过程名称（将清洗存储过程内部错误都视为该存储过程错误，便于排查）
			SELECT @TempErrorProcedure='[' +TDFH.SynchStorName +']' FROM #ToDoFillHistory AS TDFH WHERE TDFH.ID=@i      
			EXEC dbo.usp_nmap_S_FillDataSynch_ErrHandle @ErrorProcedure=@TempErrorProcedure			
        
			IF XACT_STATE() <> 0
			BEGIN
				ROLLBACK TRANSACTION;
			END
		END CATCH     
        
		SET @i=@i+1
	END
  
	--删除临时表
	DROP TABLE #DBNameDict  
	DROP TABLE #ToDoFillData
	DROP TABLE #ToDoFillHistory
	
	--返回值
	RETURN @RowCount  
END
