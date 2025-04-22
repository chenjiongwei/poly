  SELECT '24年签约金额' AS 项目划分,
           SUM(CASE WHEN 项目划分 = '存量合计' THEN [24年签约金额] ELSE 0 END) AS [存量合计24年签约金额],
           SUM(CASE WHEN 项目划分 = '22～23年获取' THEN [24年签约金额] ELSE 0 END) AS [22～23年获取24年签约金额],
           SUM(CASE WHEN 项目划分 = '24～25年获取' THEN [24年签约金额] ELSE 0 END) AS [24～25年获取24年签约金额],
		     sum([24年签约金额]) as [24年签约金额],
           case when  sum([24年签约金额])  =0  then  0
              else   SUM(CASE WHEN 项目划分 = '存量合计' THEN [24年签约金额] ELSE 0 END) / sum([24年签约金额])  end  AS [存量合计24年签约占比],
           case when  sum([24年签约金额])  =0  then  0
              else   SUM(CASE WHEN 项目划分 = '22～23年获取' THEN [24年签约金额] ELSE 0 END) / sum([24年签约金额])  end  AS [22～23年获取24年签约占比],
           case when  sum([24年签约金额])  =0  then  0
              else   SUM(CASE WHEN 项目划分 = '24～25年获取' THEN [24年签约金额] ELSE 0 END) / sum([24年签约金额])  end  AS [24～25年获取24年签约占比],
           SUM(CASE WHEN 项目划分 = '存量合计' THEN [本月签约金额] ELSE 0 END) AS [存量合计本月签约金额],
           SUM(CASE WHEN 项目划分 = '22～23年获取' THEN [本月签约金额] ELSE 0 END) AS [22～23年获取本月签约金额],
           SUM(CASE WHEN 项目划分 = '24～25年获取' THEN [本月签约金额] ELSE 0 END) AS [24～25年获取本月签约金额],
           sum([本月签约金额]) as [本月签约金额],
           case when  sum([本月签约金额]) =0 then 0 
                else  SUM(CASE WHEN 项目划分 = '存量合计' THEN [本月签约金额] ELSE 0 END) / sum([本月签约金额])  end  AS [存量合计本月签约占比],
           case when  sum([本月签约金额]) =0 then 0 
                else  SUM(CASE WHEN 项目划分 = '22～23年获取' THEN [本月签约金额] ELSE 0 END) / sum([本月签约金额])  end  AS [22～23年获取本月签约占比],
           case when  sum([本月签约金额]) =0 then 0 
                else  SUM(CASE WHEN 项目划分 = '24～25年获取' THEN [本月签约金额] ELSE 0 END) / sum([本月签约金额])  end  AS [24～25年获取本月签约占比]  
    FROM 销净率打开
    WHERE DATEDIFF(day, qxdate, GETDATE()) = 0
    AND 项目类型 IN ('存量合计', '22～23年获取', '24～25年获取')



-- 存量项目统计
  SELECT '24年签约金额' AS 项目划分,
         SUM(CASE WHEN 项目类型 = '≥0%' THEN [24年签约金额] ELSE 0 END) AS [≥0%24年签约金额],
         SUM(CASE WHEN 项目类型 = '-10%～0%' THEN [24年签约金额] ELSE 0 END) AS [-10%～0%24年签约金额],
         SUM(CASE WHEN 项目类型 = '-20%～-10%' THEN [24年签约金额] ELSE 0 END) AS [-20%～-10%24年签约金额],
         SUM(CASE WHEN 项目类型 = '-30%～-20%' THEN [24年签约金额] ELSE 0 END) AS [-30%～-20%24年签约金额],
         SUM(CASE WHEN 项目类型 = '＜-30%' THEN [24年签约金额] ELSE 0 END) AS [＜-30%24年签约金额],
         sum([24年签约金额]) as [24年签约金额],
         case when sum([24年签约金额]) = 0 then 0 
              else SUM(CASE WHEN 项目类型 = '≥0%' THEN [24年签约金额] ELSE 0 END) / sum([24年签约金额]) 
         end AS [≥0%24年签约占比],
         case when sum([24年签约金额]) = 0 then 0
              else SUM(CASE WHEN 项目类型 = '-10%～0%' THEN [24年签约金额] ELSE 0 END) / sum([24年签约金额])
         end AS [-10%～0%24年签约占比],
         case when sum([24年签约金额]) = 0 then 0
              else SUM(CASE WHEN 项目类型 = '-20%～-10%' THEN [24年签约金额] ELSE 0 END) / sum([24年签约金额])
         end AS [-20%～-10%24年签约占比],
         case when sum([24年签约金额]) = 0 then 0
              else SUM(CASE WHEN 项目类型 = '-30%～-20%' THEN [24年签约金额] ELSE 0 END) / sum([24年签约金额])
         end AS [-30%～-20%24年签约占比],
         case when sum([24年签约金额]) = 0 then 0
              else SUM(CASE WHEN 项目类型 = '＜-30%' THEN [24年签约金额] ELSE 0 END) / sum([24年签约金额])
         end AS [＜-30%24年签约占比],
         SUM(CASE WHEN 项目类型 = '≥0%' THEN [本月签约金额] ELSE 0 END) AS [≥0%本月签约金额],
         SUM(CASE WHEN 项目类型 = '-10%～0%' THEN [本月签约金额] ELSE 0 END) AS [-10%～0%本月签约金额],
         SUM(CASE WHEN 项目类型 = '-20%～-10%' THEN [本月签约金额] ELSE 0 END) AS [-20%～-10%本月签约金额],
         SUM(CASE WHEN 项目类型 = '-30%～-20%' THEN [本月签约金额] ELSE 0 END) AS [-30%～-20%本月签约金额],
         SUM(CASE WHEN 项目类型 = '＜-30%' THEN [本月签约金额] ELSE 0 END) AS [＜-30%本月签约金额],
         sum([本月签约金额]) as [本月签约金额],
         case when sum([本月签约金额]) = 0 then 0
              else SUM(CASE WHEN 项目类型 = '≥0%' THEN [本月签约金额] ELSE 0 END) / sum([本月签约金额])
         end AS [≥0%本月签约占比],
         case when sum([本月签约金额]) = 0 then 0
              else SUM(CASE WHEN 项目类型 = '-10%～0%' THEN [本月签约金额] ELSE 0 END) / sum([本月签约金额])
         end AS [-10%～0%本月签约占比],
         case when sum([本月签约金额]) = 0 then 0
              else SUM(CASE WHEN 项目类型 = '-20%～-10%' THEN [本月签约金额] ELSE 0 END) / sum([本月签约金额])
         end AS [-20%～-10%本月签约占比],
         case when sum([本月签约金额]) = 0 then 0
              else SUM(CASE WHEN 项目类型 = '-30%～-20%' THEN [本月签约金额] ELSE 0 END) / sum([本月签约金额])
         end AS [-30%～-20%本月签约占比],
         case when sum([本月签约金额]) = 0 then 0
              else SUM(CASE WHEN 项目类型 = '＜-30%' THEN [本月签约金额] ELSE 0 END) / sum([本月签约金额])
         end AS [＜-30%本月签约占比]
    FROM 销净率打开
    WHERE DATEDIFF(day, qxdate, GETDATE()) = 0
    AND 项目类型 IN ('≥0%','-10%～0%','-20%～-10%','-30%～-20%','＜-30%')