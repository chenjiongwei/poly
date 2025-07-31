 -- 声明日期变量
DECLARE @zbdate DATETIME;     -- 本周开始日期
DECLARE @zenddate DATETIME;   -- 本周结束日期
DECLARE @lzdate DATETIME;     -- 上周开始日期
DECLARE @newzbdate DATETIME;  -- 新口径本周开始日期
DECLARE @newzenddate DATETIME; -- 新口径本周结束日期
DECLARE @szbdate DATETIME;  -- 上周开始日期
DECLARE @szedate DATETIME;  -- 上周结束日期

--本周是上周日到本周六晚，上周日就是上上周六对应的清洗数据差
SET @zbdate =  ${zbdate};     -- 设置本周开始日期为2025年3月30日(周日)
SET @zenddate =  ${zenddate};   -- 设置本周结束日期为2025年4月5日(周六)
SET @lzdate =  ${lzdate};     -- 设置上周开始日期为2025年3月23日(上上周日)
SET @newzbdate = ${newzbdate};  -- 设置本月开始日期为2025年4月1日
SET @newzenddate =  ${newzenddate}; -- 设置本月当前日期为2025年4月5日(周六)


-- CREATE TABLE #t(city VARCHAR(20),ctype VARCHAR(20));INSERT INTO #t(city,ctype)VALUES('广州','一线'),( '长沙','二线'),( '北京','一线'),( '武汉','二线'),( '重庆','二线'),( '上海','一线'),( '沈阳','二线'),( '岳阳','三四线'),( '佛山','二线'),( '包头','三四线'),( '成都','二线'),( '杭州','二线'),( '南昌','二线'),( '天津','二线'),( '丹东','三四线'),( '青岛','二线'),( '长春','二线'),( '大连','二线'),( '黄冈','三四线'),( '南京','二线'),( '无锡','二线'),( '阳江','三四线'),( '常州','三四线'),( '东莞','二线'),( '福州','二线'),( '嘉兴','三四线'),( '连云港','三四线'),( '南通','三四线'),( '厦门','二线'),( '绍兴','三四线'),( '营口','三四线'),( '中山','二线'),( '珠海','二线'),( '德阳','三四线'),( '合肥','二线'),( '石家庄','二线'),( '通化','三四线'),( '郑州','二线'),( '宁波','二线'),( '郴州','三四线'),( '江门','三四线'),( '三亚','三四线'),( '西安','二线'),( '遂宁','三四线'),( '清远','三四线'),( '太原','二线'),( '韶关','三四线'),( '湛江','三四线'),( '海口','二线'),( '林芝','三四线'),( '肇庆','三四线'),( '莆田','三四线'),( '惠州','二线'),( '洛阳','三四线'),( '兰州','二线'),( '汕尾','三四线'),( '茂名','三四线'),( '乌鲁木齐','二线'),( '泉州','三四线'),( '宜昌','三四线'),( '晋中','三四线'),( '沧州','三四线'),( '常德','三四线'),( '赣州','三四线'),( '临沂','三四线'),( '汕头','三四线'),( '深圳','一线'),( '九江','三四线'),( '徐州','二线'),( '梅州','三四线'),( '益阳','三四线'),( '芜湖','三四线'),( '眉山','三四线'),( '盐城','三四线'),( '衡水','三四线'),( '昆明','二线'),( '镇江','三四线'),( '苏州','二线'),( '湖州','三四线'),( '漳州','三四线'),( '济南','二极'),( '天水','三四线'),( '台州','三四线'),( '揭阳','三四线'),( '温州','二线'),( '潍坊','三四线'),( '邢台','三四线'),( '金华','三四线'),( '开封','三四线'),( '邯郸','三四线'),( '荆州','三四线'),( '德州','三四线'),( '许昌','三四线'),( '襄阳','三四线'),( '烟台','三四线'),( '秦皇岛','三四线'),( '张家口','三四线'),( '河源','三四线'),( '孝感','三四线'),( '贵阳','二线'),( '抚州','三四线'),( '渭南','三四线'),( '济宁','三四线'),( '淮安','三四线'),( '阜阳','三四线'),( '库尔勒','三四线'),( '舟山','三四线'),( '湘潭','三四线'),( '西双版纳','三四线'),( '琼海','三四线'),( '临汾','三四线'),( '大同','三四线'),( '廊坊','三四线'),( '扬州','三四线'),( '长治','三四线'),( '儋州','三四线'),( '宜宾','三四线'),( '龙岩','三四线'),( '宜春','三四线'),( '宁德','三四线'),( '晋城','三四线'),( '衡阳','三四线'),( '墨尔本','海外'),( '悉尼','海外'),( '伦敦','海外'),( '洛杉矶','海外'),( '旧金山','海外'),( '布里斯班','海外'),( '黄石','三四线'),( '辽阳','三四线');--本周认购金额	本周签约环比	本月认购金额	本年认购金额

SELECT
    a.ctype,
    (a.本年认购金额 - b.本年认购金额) / 10000 本周认购金额,
       (d.本年认购金额 - bb.本年认购金额) / 10000 新本周认购金额,
       (b.本年认购金额 - c.本年认购金额) / 10000 上周认购金额,
       CASE
           WHEN (b.本年认购金额 - c.本年认购金额) <> 0 THEN
       ((a.本年认购金额 - b.本年认购金额) - (b.本年认购金额 - c.本年认购金额)) / (b.本年认购金额 - c.本年认购金额)
           ELSE 0
       END 本周签约环比,
       CASE
           WHEN (b.本年认购金额 - c.本年认购金额) <> 0 THEN
       ((d.本年认购金额 - bb.本年认购金额) - (b.本年认购金额 - c.本年认购金额)) / (b.本年认购金额 - c.本年认购金额)
           ELSE 0
       END 新本周签约环比,
       g.本月签约金额 / 10000 四月签约金额,
       d.本月认购金额 / 10000 本月认购金额,
	   null 本月认购金额占比,
       a.本年认购金额 / 10000 本年认购金额,
       null 本年认购金额占比
FROM
--SET @zbdate = '2025-02-23';
--SET @zenddate = '2025-03-01';
--SET @lzdate = '2025-02-16';
--SET @newzenddate = '2025-02-28';
(
    SELECT t.ctype,
           SUM(本月认购金额) 本月认购金额,
           SUM(本年认购金额) 本年认购金额
    FROM S_08ZYXSQYJB_HHZTSYJ_daily a
         LEFT JOIN vmdm_projectFlag f ON a.projguid = f.projguid
         LEFT JOIN city t ON f.城市 = t.city
    WHERE DATEDIFF(dd, qxdate, @zenddate) = 0    
	    GROUP BY t.ctype
) a
LEFT JOIN
(
    SELECT t.ctype,
           SUM(本月认购金额) 本月认购金额,
           SUM(本年认购金额) 本年认购金额
    FROM S_08ZYXSQYJB_HHZTSYJ_daily a
         LEFT JOIN vmdm_projectFlag f ON a.projguid = f.projguid
         LEFT JOIN city t ON f.城市 = t.city
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1
    GROUP BY t.ctype
) b ON a.ctype = b.ctype ---本周是2/16，那就是截止2/15的数据

LEFT JOIN
(
    SELECT t.ctype,
           SUM(本月认购金额) 本月认购金额,
           SUM(本年认购金额) 本年认购金额
    FROM S_08ZYXSQYJB_HHZTSYJ_daily a
         LEFT JOIN vmdm_projectFlag f ON a.projguid = f.projguid
         LEFT JOIN city t ON f.城市 = t.city
    WHERE DATEDIFF(dd, qxdate, @lzdate) = 1
    GROUP BY t.ctype
) c ON a.ctype = c.ctype ---本周是2/9，那就是截止2/8的数据
LEFT JOIN
(
    SELECT t.ctype,
           SUM(本月认购金额) 本月认购金额,
           SUM(本年认购金额) 本年认购金额
    FROM S_08ZYXSQYJB_HHZTSYJ_daily a
         LEFT JOIN vmdm_projectFlag f ON a.projguid = f.projguid
         LEFT JOIN city t ON f.城市 = t.city
    WHERE DATEDIFF(dd, qxdate, @newzbdate) = 1
    GROUP BY t.ctype
) bb ON a.ctype = bb.ctype ---本周是2/16，那就是截止2/15的数据
LEFT JOIN 

(
    SELECT t.ctype,
           SUM(本月认购金额) 本月认购金额,
           SUM(本年认购金额) 本年认购金额
    FROM S_08ZYXSQYJB_HHZTSYJ_daily a
         LEFT JOIN vmdm_projectFlag f ON a.projguid = f.projguid
         LEFT JOIN city t ON f.城市 = t.city
    WHERE DATEDIFF(dd, qxdate, @newzenddate) = 0
    GROUP BY t.ctype
) d ON a.ctype = d.ctype
LEFT JOIN 
(
    SELECT t.ctype,
           SUM(本月认购金额) 本月认购金额,
           SUM(本年认购金额) 本年认购金额
    FROM S_08ZYXSQYJB_HHZTSYJ_daily a
         LEFT JOIN vmdm_projectFlag f ON a.projguid = f.projguid
         LEFT JOIN city t ON f.城市 = t.city
    WHERE DATEDIFF(mm, qxdate, @newzenddate) = 1
    GROUP BY t.ctype
) e ON a.ctype = e.ctype
LEFT JOIN 
(
    SELECT t.ctype,
           SUM(本月认购金额) 本月认购金额,
           SUM(本年认购金额) 本年认购金额
    FROM S_08ZYXSQYJB_HHZTSYJ_daily a
         LEFT JOIN vmdm_projectFlag f ON a.projguid = f.projguid
         LEFT JOIN city t ON f.城市 = t.city
    WHERE DATEDIFF(yy, qxdate, @newzenddate) = 1
    GROUP BY t.ctype
) f ON a.ctype = f.ctype
LEFT JOIN 

(
    SELECT t.ctype,
           SUM(本月签约金额) 本月签约金额,
           SUM(本年认购金额) 本年认购金额
    FROM S_08ZYXSQYJB_HHZTSYJ_daily a
         LEFT JOIN vmdm_projectFlag f ON a.projguid = f.projguid
         LEFT JOIN city t ON f.城市 = t.city
    WHERE DATEDIFF(dd, qxdate, '2025-04-30') = 0
    GROUP BY t.ctype
) g ON a.ctype = g.ctype


-- DROP TABLE #t;