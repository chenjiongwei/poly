DECLARE @zenddate DATETIME;
DECLARE @zbdate DATETIME;
DECLARE @lzdate DATETIME;
DECLARE @newzbdate DATETIME;
DECLARE @newzenddate DATETIME;

--本周是上周日到本周六晚，上周日就是上上周六对应的清洗数据差
SET @zbdate = '2025-07-07';
SET @zenddate = '2025-07-13';
SET @lzdate = '2025-06-30';
SET @newzbdate = '2025-07-07';
SET @newzenddate = '2025-07-13';



CREATE TABLE #t
(
    city VARCHAR(20),
    ctype VARCHAR(20)
);
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('广州', '一线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('长沙', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('北京', '一线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('武汉', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('重庆', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('上海', '一线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('沈阳', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('岳阳', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('佛山', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('包头', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('成都', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('杭州', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('南昌', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('天津', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('丹东', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('青岛', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('长春', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('大连', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('黄冈', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('南京', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('无锡', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('阳江', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('常州', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('东莞', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('福州', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('嘉兴', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('连云港', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('南通', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('厦门', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('绍兴', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('营口', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('中山', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('珠海', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('德阳', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('合肥', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('石家庄', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('通化', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('郑州', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('宁波', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('郴州', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('江门', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('三亚', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('西安', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('遂宁', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('清远', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('太原', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('韶关', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('湛江', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('海口', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('林芝', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('肇庆', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('莆田', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('惠州', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('洛阳', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('兰州', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('汕尾', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('茂名', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('乌鲁木齐', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('泉州', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('宜昌', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('晋中', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('沧州', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('常德', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('赣州', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('临沂', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('汕头', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('深圳', '一线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('九江', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('徐州', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('梅州', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('益阳', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('芜湖', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('眉山', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('盐城', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('衡水', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('昆明', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('镇江', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('苏州', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('湖州', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('漳州', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('济南', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('天水', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('台州', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('揭阳', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('温州', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('潍坊', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('邢台', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('金华', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('开封', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('邯郸', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('荆州', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('德州', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('许昌', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('襄阳', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('烟台', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('秦皇岛', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('张家口', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('河源', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('孝感', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('贵阳', '二线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('抚州', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('渭南', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('济宁', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('淮安', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('阜阳', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('库尔勒', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('舟山', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('湘潭', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('西双版纳', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('琼海', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('临汾', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('大同', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('廊坊', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('扬州', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('长治', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('儋州', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('宜宾', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('龙岩', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('宜春', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('宁德', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('晋城', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('衡阳', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('墨尔本', '海外');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('悉尼', '海外');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('伦敦', '海外');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('洛杉矶', '海外');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('旧金山', '海外');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('布里斯班', '海外');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('黄石', '三四线');
INSERT INTO #t
(
    city,
    ctype
)
VALUES
('辽阳', '三四线');

--本周认购金额	本周签约环比	本月认购金额	本年认购金额

SELECT a.ctype,
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
         LEFT JOIN #t t ON f.城市 = t.city
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
         LEFT JOIN #t t ON f.城市 = t.city
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
         LEFT JOIN #t t ON f.城市 = t.city
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
         LEFT JOIN #t t ON f.城市 = t.city
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
         LEFT JOIN #t t ON f.城市 = t.city
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
         LEFT JOIN #t t ON f.城市 = t.city
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
         LEFT JOIN #t t ON f.城市 = t.city
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
         LEFT JOIN #t t ON f.城市 = t.city
    WHERE DATEDIFF(dd, qxdate, '2025-04-30') = 0
    GROUP BY t.ctype
) g ON a.ctype = g.ctype


DROP TABLE #t;