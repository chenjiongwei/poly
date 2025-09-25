SELECT [项目经营计划统计看板填报GUID]
      ,a.[FillHistoryGUID]
      ,a.[BusinessGUID]
      ,[RowID]
      ,[投管代码]
      ,[项目GUID]
      ,[项目代码]
      ,b.FillHistoryName
      ,b.FillDate
      ,b.BeginDate
      ,b.EndDate

      ,[最后导入人]
      ,[最后导入时间]
      ,[公司简称]
      ,[项目名称]

      ,NULLIF(NULLIF([首开去化套数_立项版],''),NULL) as [首开去化套数_立项版]
      ,NULLIF(NULLIF([续销流速累计套数_立项版],''),NULL) as [续销流速累计套数_立项版]
      ,NULLIF(NULLIF([续销流速累计本月套数_立项版],''),NULL) as [续销流速累计本月套数_立项版]
      ,CASE 
          WHEN ISNUMERIC([续销流速累计本月金额_立项版]) = 1 AND NULLIF([续销流速累计本月金额_立项版],'') IS NOT NULL
              THEN CAST([续销流速累计本月金额_立项版] AS FLOAT) / 10000.0
          ELSE NULL
       END as [续销流速累计本月金额_立项版]  -- 亿元
      ,NULLIF(NULLIF([住宅总可售单方成本(真实版)],''),NULL) as [住宅总可售单方成本_真实版]
      ,NULLIF(NULLIF([住宅已签约销净率(真实版）],''),NULL) as 住宅已签约销净率_真实版
      ,NULLIF(NULLIF([商办总可售单方成本(真实版)],''),NULL) as [商办总可售单方成本_真实版]
      ,NULLIF(NULLIF([商办已签约销净率(真实版)],''),NULL) as [商办已签约销净率_真实版]
      ,NULLIF(NULLIF([车位总可售单方成本(真实版)],''),NULL) as [车位总可售单方成本_真实版]
      ,NULLIF(NULLIF([车位已签约销净率(真实版)],''),NULL) as [车位已签约销净率_真实版]
      ,CASE 
          WHEN ISNUMERIC([财务费用(复利）截止本月]) = 1 AND NULLIF([财务费用(复利）截止本月],'') IS NOT NULL
              THEN CAST([财务费用(复利）截止本月] AS FLOAT) / 10000.0
          ELSE NULL
       END as [财务费用_复利_截止本月]  -- 亿元
      ,CASE 
          WHEN ISNUMERIC([财务费用(复利）截止上月]) = 1 AND NULLIF([财务费用(复利）截止上月],'') IS NOT NULL
              THEN CAST([财务费用(复利）截止上月] AS FLOAT) / 10000.0
          ELSE NULL
       END as [财务费用_复利_截止上月]  -- 亿元
      ,CASE 
          WHEN ISNUMERIC([已发生财务费用（单利）]) = 1 AND NULLIF([已发生财务费用（单利）],'') IS NOT NULL
              THEN CAST([已发生财务费用（单利）] AS FLOAT) / 10000.0
          ELSE NULL
       END as 已发生财务费用_单利  -- 亿元
      ,NULLIF(NULLIF([股东投资峰值_立项版],''),NULL)  as [股东投资峰值_立项版]
      ,NULLIF(NULLIF([股东投资峰值_动态版],''),NULL) as [股东投资峰值_动态版]
      ,NULLIF(NULLIF([机会成本损失],''),NULL) as [机会成本损失]
      ,NULLIF(NULLIF([机会成本损失对应单方成本],''),NULL) as [机会成本损失对应单方成本]
      ,NULLIF(NULLIF([原始股东投入],''),NULL) as [原始股东投入]
      ,NULLIF(NULLIF([贷款还款计划],''),NULL) as [贷款还款计划]
      ,NULLIF(NULLIF([财务费用(复利)-立项版],''),NULL) as [财务费用_复利_立项版]
      ,NULLIF(NULLIF([财务费用(复利)可售单方-截止本月],''),NULL) as [财务费用_复利_可售单方_截止本月]
      ,NULLIF(NULLIF([财务费用(复利)可售单方-立项版],''),NULL) as [财务费用_复利_可售单方_立项版]
      ,NULLIF(NULLIF([财务费用(单利)可售单方_截止本月],''),NULL) as [财务费用_单利_可售单方_截止本月]
  FROM [dbo].[nmap_F_项目经营计划统计看板填报] a
  inner join  [nmap_F_FillHistory] b on a.[FillHistoryGUID] =b.[FillHistoryGUID]


