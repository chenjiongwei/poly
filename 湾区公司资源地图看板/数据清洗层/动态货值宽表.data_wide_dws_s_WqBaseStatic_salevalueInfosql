--获取产品楼栋层级数据
select 
  hz.组织架构ID as 组织架构ID
, hz.组织架构父级ID as 组织架构父级ID
, hz.组织架构名称 as 组织架构名称
, 7 as 组织架构类型
, hz.组织架构编码 as 组织架构编码
, hz.总货值金额 as 动态总资源
, hz.总货值面积 as 总货值面积

, hz.已售货量金额 as 累计签约货值
, hz.已售货量面积 as 累计签约面积
, hz.累计签约套数
, hz.剩余货值金额 as 剩余货值金额
, hz.剩余货值面积 as 剩余货值面积
, case when hz.剩余货值面积 = 0 then 0 else  hz.剩余货值金额/hz.剩余货值面积 end as 剩余货值单价 
,停工缓建剩余货值金额
,停工缓建剩余货值面积
,停工缓建剩余货值套数
, hz.剩余货值预估去化面积
, hz.剩余货值预估去化金额
, hz.剩余货值金额_三年内不开工
, hz.剩余货值面积_三年内不开工
, hz.未开工剩余货值面积
, hz.未开工剩余货值金额
, hz.在途剩余货值面积
, hz.在途剩余货值金额
, ISNULL(剩余可售货值金额, 0) as 当前可售货值金额
, ISNULL(剩余可售货值面积, 0) as 当前可售货值面积
, ISNULL(已推未售货值金额, 0) as 已推未售金额
, ISNULL(已推未售货值面积, 0) as 已推未售面积
, ISNULL(已推未售产成品货值金额含车位, 0) as 产成品已推未售金额
, ISNULL(已推未售准产成品货值金额含车位, 0) as 准产成品已推未售金额
, ISNULL(已推未售货值金额, 0) -ISNULL(已推未售产成品货值金额含车位, 0)- ISNULL(已推未售准产成品货值金额含车位, 0)  as 正常已推未售金额
, ISNULL(获证未推货值金额, 0) as 获证待推金额
, ISNULL(获证未推货值面积, 0) as 获证待推面积
, ISNULL(获证未推产成品货值金额含车位, 0) as 产成品获证待推金额
, ISNULL(获证未推准产成品货值金额含车位, 0) as 准产成品获证待推金额
, ISNULL(获证未推货值金额, 0)-ISNULL(获证未推产成品货值金额含车位, 0)-ISNULL(获证未推准产成品货值金额含车位, 0) as 正常获证待推金额
, ISNULL(工程达到可售未拿证货值金额, 0) as 具备条件未领证金额
, ISNULL(工程达到可售未拿证货值面积, 0) as 具备条件未领证面积
, ISNULL(年初动态货值, 0) as 年初动态货值
, ISNULL(年初动态货值面积, 0) as 年初动态货值面积
, ISNULL(年初剩余货值, 0) as 年初剩余货值
, ISNULL(年初剩余货值面积, 0) as 年初剩余货值面积
, ISNULL(本年可售货量金额, 0)  as 本年可售货值金额
, ISNULL(本年可售货量面积, 0) as 本年可售货值面积
, ISNULL(年初工程达到可售未拿证货值金额, 0)+ ISNULL(年初获证未推货值金额, 0) + ISNULL(年初已推未售货值金额, 0) as 年初可售货值金额
, ISNULL(年初工程达到可售未拿证货值面积, 0)+ ISNULL(年初获证未推货值面积, 0) + ISNULL(年初已推未售货值面积, 0) as 年初可售货值面积
, ISNULL(年初已推未售货值金额, 0) as 年初已推未售金额
, ISNULL(年初已推未售货值面积, 0) as 年初已推未售面积
, ISNULL(年初已推未售产成品货值金额含车位, 0)  as 年初产成品已推未售金额
, ISNULL(年初已推未售准产成品货值金额含车位, 0) as 年初准产成品已推未售金额
, ISNULL(年初已推未售货值金额, 0) - ISNULL(年初已推未售产成品货值金额含车位, 0)-ISNULL(年初已推未售准产成品货值金额含车位, 0) as 年初正常已推未售金额
, ISNULL(年初获证未推货值金额, 0) as 年初获证待推金额
, ISNULL(年初获证未推货值面积, 0) as 年初获证待推面积
, ISNULL(年初获证未推产成品货值金额含车位, 0) as 年初产成品获证待推金额
, ISNULL(年初获证未推准产成品货值金额含车位, 0) as 年初准产成品获证待推金额
, ISNULL(年初获证未推货值金额, 0) -ISNULL(年初获证未推产成品货值金额含车位, 0) -ISNULL(年初获证未推准产成品货值金额含车位, 0) as 年初正常获证待推金额
, ISNULL(年初工程达到可售未拿证货值金额, 0) as 年初具备条件未领证金额
, ISNULL(年初工程达到可售未拿证货值面积, 0) as 年初具备条件未领证面积 , 
--本年
ISNULL(本年新增货量, 0)  AS 本年新增货量,

ISNULL(Jan实际货量金额, 0)  AS Jan实际货量金额,
ISNULL(Feb实际货量金额, 0)  AS Feb实际货量金额,
ISNULL(Mar实际货量金额, 0)  AS Mar实际货量金额,
ISNULL(Apr实际货量金额, 0)  AS Apr实际货量金额,
ISNULL(May实际货量金额, 0)  AS May实际货量金额,
ISNULL(Jun实际货量金额, 0)  AS Jun实际货量金额,
ISNULL(July实际货量金额, 0)  AS July实际货量金额,
ISNULL(Aug实际货量金额, 0)  AS Aug实际货量金额,
ISNULL(Sep实际货量金额, 0)  AS Sep实际货量金额,
ISNULL(Oct实际货量金额, 0)  AS Oct实际货量金额,
ISNULL(Nov实际货量金额, 0)  AS Nov实际货量金额,
ISNULL(Dec实际货量金额, 0)  AS Dec实际货量金额,

ISNULL(Jan预计货量金额, 0)  AS Jan预计货量金额,
ISNULL(Feb预计货量金额, 0)  AS Feb预计货量金额,
ISNULL(Mar预计货量金额, 0)  AS Mar预计货量金额,
ISNULL(Apr预计货量金额, 0)  AS Apr预计货量金额,
ISNULL(May预计货量金额, 0)  AS May预计货量金额,
ISNULL(Jun预计货量金额, 0)  AS Jun预计货量金额,
ISNULL(July预计货量金额, 0)  AS July预计货量金额,
ISNULL(Aug预计货量金额, 0)  AS Aug预计货量金额,
ISNULL(Sep预计货量金额, 0)  AS Sep预计货量金额,
ISNULL(Oct预计货量金额, 0)  AS Oct预计货量金额,
ISNULL(Nov预计货量金额, 0)  AS Nov预计货量金额,
ISNULL(Dec预计货量金额, 0)  AS Dec预计货量金额,
--明年
(ISNULL(明年Jan预计货量金额, 0) + ISNULL(明年Feb预计货量金额, 0) + ISNULL(明年Mar预计货量金额, 0) + ISNULL(明年Apr预计货量金额, 0)
        + ISNULL(明年May预计货量金额, 0) + ISNULL(明年Jun预计货量金额, 0) + ISNULL(明年July预计货量金额, 0) + ISNULL(明年Aug预计货量金额, 0)
        + ISNULL(明年Sep预计货量金额, 0) + ISNULL(明年Oct预计货量金额, 0) + ISNULL(明年Nov预计货量金额, 0) + ISNULL(明年Dec预计货量金额, 0)
)  明年新增货量,
ISNULL(明年Jan预计货量金额, 0)  AS 明年Jan预计货量金额,
ISNULL(明年Feb预计货量金额, 0)  AS 明年Feb预计货量金额,
ISNULL(明年Mar预计货量金额, 0)  AS 明年Mar预计货量金额,
ISNULL(明年Apr预计货量金额, 0)  AS 明年Apr预计货量金额,
ISNULL(明年May预计货量金额, 0)  AS 明年May预计货量金额,
ISNULL(明年Jun预计货量金额, 0)  AS 明年Jun预计货量金额,
ISNULL(明年July预计货量金额, 0)  AS 明年July预计货量金额,
ISNULL(明年Aug预计货量金额, 0)  AS 明年Aug预计货量金额,
ISNULL(明年Sep预计货量金额, 0)  AS 明年Sep预计货量金额,
ISNULL(明年Oct预计货量金额, 0)  AS 明年Oct预计货量金额,
ISNULL(明年Nov预计货量金额, 0)  AS 明年Nov预计货量金额,
ISNULL(明年Dec预计货量金额, 0)  AS 明年Dec预计货量金额,
--后年
(ISNULL(后年Jan预计货量金额, 0) + ISNULL(后年Feb预计货量金额, 0) + ISNULL(后年Mar预计货量金额, 0) + ISNULL(后年Apr预计货量金额, 0)
        + ISNULL(后年May预计货量金额, 0) + ISNULL(后年Jun预计货量金额, 0) + ISNULL(后年July预计货量金额, 0) + ISNULL(后年Aug预计货量金额, 0)
        + ISNULL(后年Sep预计货量金额, 0) + ISNULL(后年Oct预计货量金额, 0) + ISNULL(后年Nov预计货量金额, 0) + ISNULL(后年Dec预计货量金额, 0)
)  AS 后年新增货量,
ISNULL(后年Jan预计货量金额, 0)  AS 后年Jan预计货量金额,
ISNULL(后年Feb预计货量金额, 0)  AS 后年Feb预计货量金额,
ISNULL(后年Mar预计货量金额, 0)  AS 后年Mar预计货量金额,
ISNULL(后年Apr预计货量金额, 0)  AS 后年Apr预计货量金额,
ISNULL(后年May预计货量金额, 0)  AS 后年May预计货量金额,
ISNULL(后年Jun预计货量金额, 0)  AS 后年Jun预计货量金额,
ISNULL(后年July预计货量金额, 0)  AS 后年July预计货量金额,
ISNULL(后年Aug预计货量金额, 0)  AS 后年Aug预计货量金额,
ISNULL(后年Sep预计货量金额, 0)  AS 后年Sep预计货量金额,
ISNULL(后年Oct预计货量金额, 0)  AS 后年Oct预计货量金额,
ISNULL(后年Nov预计货量金额, 0)  AS 后年Nov预计货量金额,
ISNULL(后年Dec预计货量金额, 0)  AS 后年Dec预计货量金额,
isnull(剩余货值预估去化面积_按月份差,0) as 剩余货值预估去化面积_按月份差,	
isnull(剩余货值预估去化金额_按月份差,0) as 剩余货值预估去化金额_按月份差,
isnull(年初剩余货值_年初清洗版,0) as 年初剩余货值_年初清洗版,	
isnull(年初剩余货值面积_年初清洗版,0) as 年初剩余货值面积_年初清洗版,	
isnull(年初取证未售货值_年初清洗版,0) as 年初取证未售货值_年初清洗版,	
isnull(年初取证未售面积_年初清洗版,0) as 年初取证未售面积_年初清洗版,	
isnull(本年已售货值_截止上月底清洗版,0) as 本年已售货值_截止上月底清洗版,	
isnull(本年已售面积_截止上月底清洗版,0) as 本年已售面积_截止上月底清洗版,	
isnull(本年取证剩余货值_截止上月底清洗版,0) as 本年取证剩余货值_截止上月底清洗版,
isnull(本年取证剩余面积_截止上月底清洗版,0) as 本年取证剩余面积_截止上月底清洗版,
isnull(预估本年取证新增货值,0) as 预估本年取证新增货值,	
isnull(预估本年取证新增面积,0) as 预估本年取证新增面积,
--停工缓建
isnull(停工缓建工程达到可售未拿证货值金额,0) as 停工缓建工程达到可售未拿证货值金额, 
isnull(停工缓建工程达到可售未拿证货值面积,0) as 停工缓建工程达到可售未拿证货值面积,
isnull(停工缓建获证未推货值金额,0) as 停工缓建获证未推货值金额, 
isnull(停工缓建获证未推货值面积,0) as 停工缓建获证未推货值面积,
isnull(停工缓建已推未售货值金额,0) as 停工缓建已推未售货值金额, 
isnull(停工缓建已推未售货值面积,0) as 停工缓建已推未售货值面积,
isnull(停工缓建剩余可售货值金额,0) as 停工缓建剩余可售货值金额, 
isnull(停工缓建剩余可售货值面积,0) as 停工缓建剩余可售货值面积,
isnull(停工缓建在途剩余货值金额,0) as 停工缓建在途剩余货值金额, 
isnull(停工缓建在途剩余货值面积,0) as 停工缓建在途剩余货值面积,

--增加套数
isnull(hz.总货值套数,0) as 总货值套数, 
isnull(hz.剩余货值套数,0) as 剩余货值套数,   
isnull(hz.剩余货值套数_三年内不开工,0) as 剩余货值套数_三年内不开工 , 
isnull(hz.未开工剩余货值套数,0) as 未开工剩余货值套数,
isnull(hz.在途剩余货值套数,0) as 在途剩余货值套数, 
isnull(hz.停工缓建在途剩余货值套数,0) as 停工缓建在途剩余货值套数 ,
isnull(hz.剩余可售货值套数,0) as 剩余可售货值套数,  
isnull(hz.停工缓建剩余可售货值套数,0) as 停工缓建剩余可售货值套数 ,          
isnull(hz.工程达到可售未拿证货值套数,0) as 工程达到可售未拿证货值套数 ,      
isnull(hz.停工缓建工程达到可售未拿证货值套数,0) as 停工缓建工程达到可售未拿证货值套数 , 
isnull(hz.获证未推货值套数,0) as 获证未推货值套数 ,   
isnull(hz.停工缓建获证未推货值套数,0) as 停工缓建获证未推货值套数 ,      
isnull(hz.已推未售货值套数,0) as 已推未售货值套数, 
isnull(hz.停工缓建已推未售货值套数,0) as 停工缓建已推未售货值套数  
into #baseinfo
from ydkb_dthz_wq_deal_salevalueinfo hz
where 组织架构类型=6
 

--获取业态层级的数据,将业态层级的组织架构id替换为数仓这边的组织架构id
insert into #baseinfo
select 
  bi.组织架构ID as 组织架构ID
, bi.组织架构父级ID as 组织架构父级ID
, bi.组织架构名称 as 组织架构名称
, 4 as 组织架构类型
, bi.组织架构编码 as 组织架构编码
, sum(isnull(hz.总货值金额,0)) as 动态总资源
, sum(isnull(hz.总货值面积,0)) as 总货值面积
, sum(isnull(hz.已售货量金额,0)) as 累计签约货值
, sum(isnull(hz.已售货量面积,0))  as 累计签约面积
, sum(isnull(hz.累计签约套数,0)) as 累计签约套数
, sum(isnull(hz.剩余货值金额,0)) as 剩余货值金额
, sum(isnull(hz.剩余货值面积,0)) as 剩余货值面积
, case when sum(isnull(hz.剩余货值面积,0)) = 0 then 0 else sum(isnull(hz.剩余货值金额,0))/sum(isnull(hz.剩余货值面积,0)) end as 剩余货值单价 
,sum(isnull(hz.停工缓建剩余货值金额,0)) 停工缓建剩余货值金额
,sum(isnull(hz.停工缓建剩余货值面积,0)) 停工缓建剩余货值面积
,sum(isnull(hz.停工缓建剩余货值套数,0)) 停工缓建剩余货值套数
, sum(isnull(hz.剩余货值预估去化面积,0)) as 剩余货值预估去化面积
, sum(isnull(hz.剩余货值预估去化金额,0)) as 剩余货值预估去化金额
, sum(ISNULL(hz.剩余货值金额_三年内不开工,0)) as 剩余货值金额_三年内不开工
, sum(ISNULL(hz.剩余货值面积_三年内不开工,0)) as 剩余货值面积_三年内不开工
, sum(ISNULL(hz.未开工剩余货值面积,0)) as 未开工剩余货值面积
, sum(ISNULL(hz.未开工剩余货值金额,0)) as 未开工剩余货值金额
, sum(ISNULL(hz.在途剩余货值面积,0)) as 在途剩余货值面积
, sum(ISNULL(hz.在途剩余货值金额,0)) as 在途剩余货值金额
, sum(ISNULL(剩余可售货值金额, 0)) as 当前可售货值金额
, sum(ISNULL(剩余可售货值面积, 0)) as 当前可售货值面积
, sum(ISNULL(已推未售货值金额, 0)) as 已推未售金额
, sum(ISNULL(已推未售货值面积, 0)) as 已推未售面积
, sum(ISNULL(已推未售产成品货值金额含车位, 0)) as 产成品已推未售金额
, sum(ISNULL(已推未售准产成品货值金额含车位, 0)) as 准产成品已推未售金额
, sum(ISNULL(已推未售货值金额, 0) -ISNULL(已推未售产成品货值金额含车位, 0)- ISNULL(已推未售准产成品货值金额含车位, 0))  as 正常已推未售金额
, sum(ISNULL(获证未推货值金额, 0)) as 获证待推金额
, sum(ISNULL(获证未推货值面积, 0)) as 获证待推面积
, sum(ISNULL(获证未推产成品货值金额含车位, 0)) as 产成品获证待推金额
, sum(ISNULL(获证未推准产成品货值金额含车位, 0)) as 准产成品获证待推金额
, sum(ISNULL(获证未推货值金额, 0)-ISNULL(获证未推产成品货值金额含车位, 0)-ISNULL(获证未推准产成品货值金额含车位, 0)) as 正常获证待推金额
, sum(ISNULL(工程达到可售未拿证货值金额, 0)) as 具备条件未领证金额
, sum(ISNULL(工程达到可售未拿证货值面积, 0)) as 具备条件未领证面积
, sum(ISNULL(年初动态货值, 0)) as 年初动态货值
, sum(ISNULL(年初动态货值面积, 0)) as 年初动态货值面积
, sum(ISNULL(年初剩余货值, 0)) as 年初剩余货值
, sum(ISNULL(年初剩余货值面积, 0)) as 年初剩余货值面积
, sum(ISNULL(本年可售货量金额, 0))  as 本年可售货值金额
, sum(ISNULL(本年可售货量面积, 0)) as 本年可售货值面积
, sum(ISNULL(年初工程达到可售未拿证货值金额, 0)+ ISNULL(年初获证未推货值金额, 0) + ISNULL(年初已推未售货值金额, 0)) as 年初可售货值金额
, sum(ISNULL(年初工程达到可售未拿证货值面积, 0)+ ISNULL(年初获证未推货值面积, 0) + ISNULL(年初已推未售货值面积, 0)) as 年初可售货值面积
, sum(ISNULL(年初已推未售货值金额, 0)) as 年初已推未售金额
, sum(ISNULL(年初已推未售货值面积, 0)) as 年初已推未售面积
, sum(ISNULL(年初已推未售产成品货值金额含车位, 0))  as 年初产成品已推未售金额
, sum(ISNULL(年初已推未售准产成品货值金额含车位, 0)) as 年初准产成品已推未售金额
, sum(ISNULL(年初已推未售货值金额, 0) - ISNULL(年初已推未售产成品货值金额含车位, 0)-ISNULL(年初已推未售准产成品货值金额含车位, 0)) as 年初正常已推未售金额
, sum(ISNULL(年初获证未推货值金额, 0)) as 年初获证待推金额
, sum(ISNULL(年初获证未推货值面积, 0)) as 年初获证待推面积
, sum(ISNULL(年初获证未推产成品货值金额含车位, 0)) as 年初产成品获证待推金额
, sum(ISNULL(年初获证未推准产成品货值金额含车位, 0)) as 年初准产成品获证待推金额
, sum(ISNULL(年初获证未推货值金额, 0) -ISNULL(年初获证未推产成品货值金额含车位, 0) -ISNULL(年初获证未推准产成品货值金额含车位, 0)) as 年初正常获证待推金额
, sum(ISNULL(年初工程达到可售未拿证货值金额, 0)) as 年初具备条件未领证金额
, sum(ISNULL(年初工程达到可售未拿证货值面积, 0)) as 年初具备条件未领证面积,
--本年
sum(ISNULL(本年新增货量, 0))  AS 本年新增货量,
sum(ISNULL(Jan实际货量金额, 0))  AS Jan实际货量金额,
sum(ISNULL(Feb实际货量金额, 0))  AS Feb实际货量金额,
sum(ISNULL(Mar实际货量金额, 0))  AS Mar实际货量金额,
sum(ISNULL(Apr实际货量金额, 0))  AS Apr实际货量金额,
sum(ISNULL(May实际货量金额, 0))  AS May实际货量金额,
sum(ISNULL(Jun实际货量金额, 0))  AS Jun实际货量金额,
sum(ISNULL(July实际货量金额, 0))  AS July实际货量金额,
sum(ISNULL(Aug实际货量金额, 0))  AS Aug实际货量金额,
sum(ISNULL(Sep实际货量金额, 0))  AS Sep实际货量金额,
sum(ISNULL(Oct实际货量金额, 0))  AS Oct实际货量金额,
sum(ISNULL(Nov实际货量金额, 0))  AS Nov实际货量金额,
sum(ISNULL(Dec实际货量金额, 0))  AS Dec实际货量金额,

sum(ISNULL(Jan预计货量金额, 0))  AS Jan预计货量金额,
sum(ISNULL(Feb预计货量金额, 0))  AS Feb预计货量金额,
sum(ISNULL(Mar预计货量金额, 0))  AS Mar预计货量金额,
sum(ISNULL(Apr预计货量金额, 0))  AS Apr预计货量金额,
sum(ISNULL(May预计货量金额, 0))  AS May预计货量金额,
sum(ISNULL(Jun预计货量金额, 0))  AS Jun预计货量金额,
sum(ISNULL(July预计货量金额, 0))  AS July预计货量金额,
sum(ISNULL(Aug预计货量金额, 0))  AS Aug预计货量金额,
sum(ISNULL(Sep预计货量金额, 0))  AS Sep预计货量金额,
sum(ISNULL(Oct预计货量金额, 0))  AS Oct预计货量金额,
sum(ISNULL(Nov预计货量金额, 0))  AS Nov预计货量金额,
sum(ISNULL(Dec预计货量金额, 0))  AS Dec预计货量金额,
--明年
sum(ISNULL(明年Jan预计货量金额, 0) + ISNULL(明年Feb预计货量金额, 0) + ISNULL(明年Mar预计货量金额, 0) + ISNULL(明年Apr预计货量金额, 0)
        + ISNULL(明年May预计货量金额, 0) + ISNULL(明年Jun预计货量金额, 0) + ISNULL(明年July预计货量金额, 0) + ISNULL(明年Aug预计货量金额, 0)
        + ISNULL(明年Sep预计货量金额, 0) + ISNULL(明年Oct预计货量金额, 0) + ISNULL(明年Nov预计货量金额, 0) + ISNULL(明年Dec预计货量金额, 0)
)  明年新增货量,
sum(ISNULL(明年Jan预计货量金额, 0))  AS 明年Jan预计货量金额,
sum(ISNULL(明年Feb预计货量金额, 0))  AS 明年Feb预计货量金额,
sum(ISNULL(明年Mar预计货量金额, 0))  AS 明年Mar预计货量金额,
sum(ISNULL(明年Apr预计货量金额, 0))  AS 明年Apr预计货量金额,
sum(ISNULL(明年May预计货量金额, 0))  AS 明年May预计货量金额,
sum(ISNULL(明年Jun预计货量金额, 0))  AS 明年Jun预计货量金额,
sum(ISNULL(明年July预计货量金额, 0))  AS 明年July预计货量金额,
sum(ISNULL(明年Aug预计货量金额, 0))  AS 明年Aug预计货量金额,
sum(ISNULL(明年Sep预计货量金额, 0))  AS 明年Sep预计货量金额,
sum(ISNULL(明年Oct预计货量金额, 0))  AS 明年Oct预计货量金额,
sum(ISNULL(明年Nov预计货量金额, 0))  AS 明年Nov预计货量金额,
sum(ISNULL(明年Dec预计货量金额, 0))  AS 明年Dec预计货量金额,
--后年
sum(ISNULL(后年Jan预计货量金额, 0) + ISNULL(后年Feb预计货量金额, 0) + ISNULL(后年Mar预计货量金额, 0) + ISNULL(后年Apr预计货量金额, 0)
        + ISNULL(后年May预计货量金额, 0) + ISNULL(后年Jun预计货量金额, 0) + ISNULL(后年July预计货量金额, 0) + ISNULL(后年Aug预计货量金额, 0)
        + ISNULL(后年Sep预计货量金额, 0) + ISNULL(后年Oct预计货量金额, 0) + ISNULL(后年Nov预计货量金额, 0) + ISNULL(后年Dec预计货量金额, 0)
)  AS 后年新增货量,
sum(ISNULL(后年Jan预计货量金额, 0))  AS 后年Jan预计货量金额,
sum(ISNULL(后年Feb预计货量金额, 0))  AS 后年Feb预计货量金额,
sum(ISNULL(后年Mar预计货量金额, 0))  AS 后年Mar预计货量金额,
sum(ISNULL(后年Apr预计货量金额, 0))  AS 后年Apr预计货量金额,
sum(ISNULL(后年May预计货量金额, 0))  AS 后年May预计货量金额,
sum(ISNULL(后年Jun预计货量金额, 0))  AS 后年Jun预计货量金额,
sum(ISNULL(后年July预计货量金额, 0))  AS 后年July预计货量金额,
sum(ISNULL(后年Aug预计货量金额, 0))  AS 后年Aug预计货量金额,
sum(ISNULL(后年Sep预计货量金额, 0))  AS 后年Sep预计货量金额,
sum(ISNULL(后年Oct预计货量金额, 0))  AS 后年Oct预计货量金额,
sum(ISNULL(后年Nov预计货量金额, 0))  AS 后年Nov预计货量金额,
sum(ISNULL(后年Dec预计货量金额, 0))  AS 后年Dec预计货量金额,
sum(isnull(剩余货值预估去化面积_按月份差,0)) as 剩余货值预估去化面积_按月份差,	
sum(isnull(剩余货值预估去化金额_按月份差,0)) as 剩余货值预估去化金额_按月份差,
sum(isnull(年初剩余货值_年初清洗版,0)) as 年初剩余货值_年初清洗版,	
sum(isnull(年初剩余货值面积_年初清洗版,0)) as 年初剩余货值面积_年初清洗版,	
sum(isnull(年初取证未售货值_年初清洗版,0)) as 年初取证未售货值_年初清洗版,	
sum(isnull(年初取证未售面积_年初清洗版,0)) as 年初取证未售面积_年初清洗版,	
sum(isnull(本年已售货值_截止上月底清洗版,0)) as 本年已售货值_截止上月底清洗版,	
sum(isnull(本年已售面积_截止上月底清洗版,0)) as 本年已售面积_截止上月底清洗版,	
sum(isnull(本年取证剩余货值_截止上月底清洗版,0)) as 本年取证剩余货值_截止上月底清洗版,
sum(isnull(本年取证剩余面积_截止上月底清洗版,0)) as 本年取证剩余面积_截止上月底清洗版,
sum(isnull(预估本年取证新增货值,0)) as 预估本年取证新增货值,	
sum(isnull(预估本年取证新增面积,0)) as 预估本年取证新增面积,
--停工缓建
sum(isnull(停工缓建工程达到可售未拿证货值金额,0)) as 停工缓建工程达到可售未拿证货值金额, 
sum(isnull(停工缓建工程达到可售未拿证货值面积,0)) as 停工缓建工程达到可售未拿证货值面积,
sum(isnull(停工缓建获证未推货值金额,0)) as 停工缓建获证未推货值金额, 
sum(isnull(停工缓建获证未推货值面积,0)) as 停工缓建获证未推货值面积,
sum(isnull(停工缓建已推未售货值金额,0)) as 停工缓建已推未售货值金额, 
sum(isnull(停工缓建已推未售货值面积,0)) as 停工缓建已推未售货值面积,
sum(isnull(停工缓建剩余可售货值金额,0)) as 停工缓建剩余可售货值金额, 
sum(isnull(停工缓建剩余可售货值面积,0)) as 停工缓建剩余可售货值面积,
sum(isnull(停工缓建在途剩余货值金额,0)) as 停工缓建在途剩余货值金额, 
sum(isnull(停工缓建在途剩余货值面积,0)) as 停工缓建在途剩余货值面积 ,
sum(isnull(hz.总货值套数,0)) as 总货值套数, 
sum(isnull(hz.剩余货值套数,0)) as 剩余货值套数,   
sum(isnull(hz.剩余货值套数_三年内不开工,0)) as 剩余货值套数_三年内不开工 , 
sum(isnull(hz.未开工剩余货值套数,0)) as 未开工剩余货值套数,
sum(isnull(hz.在途剩余货值套数,0)) as 在途剩余货值套数, 
sum(isnull(hz.停工缓建在途剩余货值套数,0)) as 停工缓建在途剩余货值套数 ,
sum(isnull(hz.剩余可售货值套数,0)) as 剩余可售货值套数,  
sum(isnull(hz.停工缓建剩余可售货值套数,0)) as 停工缓建剩余可售货值套数 ,          
sum(isnull(hz.工程达到可售未拿证货值套数,0)) as 工程达到可售未拿证货值套数 ,      
sum(isnull(hz.停工缓建工程达到可售未拿证货值套数,0)) as 停工缓建工程达到可售未拿证货值套数 , 
sum(isnull(hz.获证未推货值套数,0)) as 获证未推货值套数 ,   
sum(isnull(hz.停工缓建获证未推货值套数,0)) as 停工缓建获证未推货值套数 ,      
sum(isnull(hz.已推未售货值套数,0)) as 已推未售货值套数, 
sum(isnull(hz.停工缓建已推未售货值套数,0)) as 停工缓建已推未售货值套数  
from ydkb_dthz_wq_deal_salevalueinfo hz
inner join [172.16.4.161].highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_Organization bi on hz.组织架构名称 = bi.组织架构名称
and hz.组织架构父级id = bi.组织架构父级id 
where hz.组织架构类型 =4 and bi.组织架构类型 = 4
group by  bi.组织架构ID ,bi.组织架构父级ID 
, bi.组织架构名称 
, bi.组织架构编码

--循环更新:通过产品楼栋层级数据，循环更新工程楼栋、产品组合的数据 ;通过业态层级数据，循环更新项目、区域、公司的数据 
DECLARE @baseinfo int;
set @baseinfo = 7
while (@baseinfo >1)
BEGIN

--判断是否要生成业态层级的，如果是的话，就跳过
if(@baseinfo = 5) 
begin set @baseinfo = @baseinfo - 1; CONTINUE end;

insert into #baseinfo
select 
  bi2.组织架构ID as 组织架构ID
, bi2.组织架构父级ID as 组织架构父级ID  
, bi2.组织架构名称 as 组织架构名称
, bi2.组织架构类型
, bi2.组织架构编码 as 组织架构编码
, sum(isnull(hz.动态总资源,0)) as 动态总资源
, sum(isnull(hz.总货值面积,0)) as 总货值面积
, sum(isnull(hz.累计签约货值,0)) as 累计签约货值
, sum(isnull(hz.累计签约面积,0))  as 累计签约面积
, sum(isnull(hz.累计签约套数,0)) as 累计签约套数
, sum(isnull(hz.剩余货值金额,0)) as 剩余货值金额
, sum(isnull(hz.剩余货值面积,0)) as 剩余货值面积
, case when sum(isnull(hz.剩余货值面积,0)) = 0 then 0 else sum(isnull(hz.剩余货值金额,0))/sum(isnull(hz.剩余货值面积,0)) end as 剩余货值单价 
,sum(isnull(hz.停工缓建剩余货值金额,0)) 停工缓建剩余货值金额
,sum(isnull(hz.停工缓建剩余货值面积,0)) 停工缓建剩余货值面积
,sum(isnull(hz.停工缓建剩余货值套数,0)) 停工缓建剩余货值套数
, sum(isnull(hz.剩余货值预估去化面积,0)) as 剩余货值预估去化面积
, sum(isnull(hz.剩余货值预估去化金额,0)) as 剩余货值预估去化金额
, sum(ISNULL(hz.剩余货值金额_三年内不开工,0)) as 剩余货值金额_三年内不开工
, sum(ISNULL(hz.剩余货值面积_三年内不开工,0)) as 剩余货值面积_三年内不开工
, sum(ISNULL(hz.未开工剩余货值面积,0)) as 未开工剩余货值面积
, sum(ISNULL(hz.未开工剩余货值金额,0)) as 未开工剩余货值金额
, sum(ISNULL(hz.在途剩余货值面积,0)) as 在途剩余货值面积
, sum(ISNULL(hz.在途剩余货值金额,0)) as 在途剩余货值金额
, sum(ISNULL(当前可售货值金额, 0)) as 当前可售货值金额
, sum(ISNULL(当前可售货值面积, 0)) as 当前可售货值面积
, sum(ISNULL(已推未售金额, 0)) as 已推未售金额
, sum(ISNULL(已推未售面积, 0)) as 已推未售面积
, sum(ISNULL(产成品已推未售金额, 0)) as 产成品已推未售金额
, sum(ISNULL(准产成品已推未售金额, 0)) as 准产成品已推未售金额
, sum(ISNULL(正常已推未售金额, 0))  as 正常已推未售金额
, sum(ISNULL(获证待推金额, 0)) as 获证待推金额
, sum(ISNULL(获证待推面积, 0)) as 获证待推面积
, sum(ISNULL(产成品获证待推金额, 0)) as 产成品获证待推金额
, sum(ISNULL(准产成品获证待推金额, 0)) as 准产成品获证待推金额
, sum(ISNULL(正常获证待推金额, 0)) as 正常获证待推金额
, sum(ISNULL(具备条件未领证金额, 0)) as 具备条件未领证金额
, sum(ISNULL(具备条件未领证面积, 0)) as 具备条件未领证面积
, sum(ISNULL(年初动态货值, 0)) as 年初动态货值
, sum(ISNULL(年初动态货值面积, 0)) as 年初动态货值面积
, sum(ISNULL(年初剩余货值, 0)) as 年初剩余货值
, sum(ISNULL(年初剩余货值面积, 0)) as 年初剩余货值面积
, sum(ISNULL(本年可售货值金额, 0))  as 本年可售货值金额
, sum(ISNULL(本年可售货值面积, 0)) as 本年可售货值面积
, sum(ISNULL(年初可售货值金额, 0)) as 年初可售货值金额
, sum(ISNULL(年初可售货值面积, 0)) as 年初可售货值面积
, sum(ISNULL(年初已推未售金额, 0)) as 年初已推未售金额
, sum(ISNULL(年初已推未售面积, 0)) as 年初已推未售面积
, sum(ISNULL(年初产成品已推未售金额, 0))  as 年初产成品已推未售金额
, sum(ISNULL(年初准产成品已推未售金额, 0)) as 年初准产成品已推未售金额
, sum(ISNULL(年初正常已推未售金额, 0) ) as 年初正常已推未售金额
, sum(ISNULL(年初获证待推金额, 0)) as 年初获证待推金额
, sum(ISNULL(年初获证待推面积, 0)) as 年初获证待推面积
, sum(ISNULL(年初产成品获证待推金额, 0)) as 年初产成品获证待推金额
, sum(ISNULL(年初准产成品获证待推金额, 0)) as 年初准产成品获证待推金额
, sum(ISNULL(年初正常获证待推金额, 0)) as 年初正常获证待推金额
, sum(ISNULL(年初具备条件未领证金额, 0)) as 年初具备条件未领证金额
, sum(ISNULL(年初具备条件未领证面积, 0)) as 年初具备条件未领证面积,
--本年
sum(ISNULL(本年新增货量, 0))  AS 本年新增货量,

sum(ISNULL(Jan实际货量金额, 0))  AS Jan实际货量金额,
sum(ISNULL(Feb实际货量金额, 0))  AS Feb实际货量金额,
sum(ISNULL(Mar实际货量金额, 0))  AS Mar实际货量金额,
sum(ISNULL(Apr实际货量金额, 0))  AS Apr实际货量金额,
sum(ISNULL(May实际货量金额, 0))  AS May实际货量金额,
sum(ISNULL(Jun实际货量金额, 0))  AS Jun实际货量金额,
sum(ISNULL(July实际货量金额, 0))  AS July实际货量金额,
sum(ISNULL(Aug实际货量金额, 0))  AS Aug实际货量金额,
sum(ISNULL(Sep实际货量金额, 0))  AS Sep实际货量金额,
sum(ISNULL(Oct实际货量金额, 0))  AS Oct实际货量金额,
sum(ISNULL(Nov实际货量金额, 0))  AS Nov实际货量金额,
sum(ISNULL(Dec实际货量金额, 0))  AS Dec实际货量金额,

sum(ISNULL(Jan预计货量金额, 0))  AS Jan预计货量金额,
sum(ISNULL(Feb预计货量金额, 0))  AS Feb预计货量金额,
sum(ISNULL(Mar预计货量金额, 0))  AS Mar预计货量金额,
sum(ISNULL(Apr预计货量金额, 0))  AS Apr预计货量金额,
sum(ISNULL(May预计货量金额, 0))  AS May预计货量金额,
sum(ISNULL(Jun预计货量金额, 0))  AS Jun预计货量金额,
sum(ISNULL(July预计货量金额, 0))  AS July预计货量金额,
sum(ISNULL(Aug预计货量金额, 0))  AS Aug预计货量金额,
sum(ISNULL(Sep预计货量金额, 0))  AS Sep预计货量金额,
sum(ISNULL(Oct预计货量金额, 0))  AS Oct预计货量金额,
sum(ISNULL(Nov预计货量金额, 0))  AS Nov预计货量金额,
sum(ISNULL(Dec预计货量金额, 0))  AS Dec预计货量金额,
--明年
sum(ISNULL(明年Jan预计货量金额, 0) + ISNULL(明年Feb预计货量金额, 0) + ISNULL(明年Mar预计货量金额, 0) + ISNULL(明年Apr预计货量金额, 0)
        + ISNULL(明年May预计货量金额, 0) + ISNULL(明年Jun预计货量金额, 0) + ISNULL(明年July预计货量金额, 0) + ISNULL(明年Aug预计货量金额, 0)
        + ISNULL(明年Sep预计货量金额, 0) + ISNULL(明年Oct预计货量金额, 0) + ISNULL(明年Nov预计货量金额, 0) + ISNULL(明年Dec预计货量金额, 0)
)  明年新增货量,
sum(ISNULL(明年Jan预计货量金额, 0))  AS 明年Jan预计货量金额,
sum(ISNULL(明年Feb预计货量金额, 0))  AS 明年Feb预计货量金额,
sum(ISNULL(明年Mar预计货量金额, 0))  AS 明年Mar预计货量金额,
sum(ISNULL(明年Apr预计货量金额, 0))  AS 明年Apr预计货量金额,
sum(ISNULL(明年May预计货量金额, 0))  AS 明年May预计货量金额,
sum(ISNULL(明年Jun预计货量金额, 0))  AS 明年Jun预计货量金额,
sum(ISNULL(明年July预计货量金额, 0))  AS 明年July预计货量金额,
sum(ISNULL(明年Aug预计货量金额, 0))  AS 明年Aug预计货量金额,
sum(ISNULL(明年Sep预计货量金额, 0))  AS 明年Sep预计货量金额,
sum(ISNULL(明年Oct预计货量金额, 0))  AS 明年Oct预计货量金额,
sum(ISNULL(明年Nov预计货量金额, 0))  AS 明年Nov预计货量金额,
sum(ISNULL(明年Dec预计货量金额, 0))  AS 明年Dec预计货量金额,
--后年
sum(isnull(后年新增货量,0))  AS 后年新增货量,
sum(ISNULL(后年Jan预计货量金额, 0))  AS 后年Jan预计货量金额,
sum(ISNULL(后年Feb预计货量金额, 0))  AS 后年Feb预计货量金额,
sum(ISNULL(后年Mar预计货量金额, 0))  AS 后年Mar预计货量金额,
sum(ISNULL(后年Apr预计货量金额, 0))  AS 后年Apr预计货量金额,
sum(ISNULL(后年May预计货量金额, 0))  AS 后年May预计货量金额,
sum(ISNULL(后年Jun预计货量金额, 0))  AS 后年Jun预计货量金额,
sum(ISNULL(后年July预计货量金额, 0))  AS 后年July预计货量金额,
sum(ISNULL(后年Aug预计货量金额, 0))  AS 后年Aug预计货量金额,
sum(ISNULL(后年Sep预计货量金额, 0))  AS 后年Sep预计货量金额,
sum(ISNULL(后年Oct预计货量金额, 0))  AS 后年Oct预计货量金额,
sum(ISNULL(后年Nov预计货量金额, 0))  AS 后年Nov预计货量金额,
sum(ISNULL(后年Dec预计货量金额, 0))  AS 后年Dec预计货量金额,
sum(isnull(剩余货值预估去化面积_按月份差,0)) as 剩余货值预估去化面积_按月份差,	
sum(isnull(剩余货值预估去化金额_按月份差,0)) as 剩余货值预估去化金额_按月份差,
sum(isnull(年初剩余货值_年初清洗版,0)) as 年初剩余货值_年初清洗版,	
sum(isnull(年初剩余货值面积_年初清洗版,0)) as 年初剩余货值面积_年初清洗版,	
sum(isnull(年初取证未售货值_年初清洗版,0)) as 年初取证未售货值_年初清洗版,	
sum(isnull(年初取证未售面积_年初清洗版,0)) as 年初取证未售面积_年初清洗版,	
sum(isnull(本年已售货值_截止上月底清洗版,0)) as 本年已售货值_截止上月底清洗版,	
sum(isnull(本年已售面积_截止上月底清洗版,0)) as 本年已售面积_截止上月底清洗版,	
sum(isnull(本年取证剩余货值_截止上月底清洗版,0)) as 本年取证剩余货值_截止上月底清洗版,
sum(isnull(本年取证剩余面积_截止上月底清洗版,0)) as 本年取证剩余面积_截止上月底清洗版,
sum(isnull(预估本年取证新增货值,0)) as 预估本年取证新增货值,	
sum(isnull(预估本年取证新增面积,0)) as 预估本年取证新增面积,
--停工缓建
sum(isnull(停工缓建工程达到可售未拿证货值金额,0)) as 停工缓建工程达到可售未拿证货值金额, 
sum(isnull(停工缓建工程达到可售未拿证货值面积,0)) as 停工缓建工程达到可售未拿证货值面积,
sum(isnull(停工缓建获证未推货值金额,0)) as 停工缓建获证未推货值金额, 
sum(isnull(停工缓建获证未推货值面积,0)) as 停工缓建获证未推货值面积,
sum(isnull(停工缓建已推未售货值金额,0)) as 停工缓建已推未售货值金额, 
sum(isnull(停工缓建已推未售货值面积,0)) as 停工缓建已推未售货值面积,
sum(isnull(停工缓建剩余可售货值金额,0)) as 停工缓建剩余可售货值金额, 
sum(isnull(停工缓建剩余可售货值面积,0)) as 停工缓建剩余可售货值面积,
sum(isnull(停工缓建在途剩余货值金额,0)) as 停工缓建在途剩余货值金额, 
sum(isnull(停工缓建在途剩余货值面积,0)) as 停工缓建在途剩余货值面积,
sum(isnull(hz.总货值套数,0)) as 总货值套数, 
sum(isnull(hz.剩余货值套数,0)) as 剩余货值套数,   
sum(isnull(hz.剩余货值套数_三年内不开工,0)) as 剩余货值套数_三年内不开工 , 
sum(isnull(hz.未开工剩余货值套数,0)) as 未开工剩余货值套数,
sum(isnull(hz.在途剩余货值套数,0)) as 在途剩余货值套数, 
sum(isnull(hz.停工缓建在途剩余货值套数,0)) as 停工缓建在途剩余货值套数 ,
sum(isnull(hz.剩余可售货值套数,0)) as 剩余可售货值套数,  
sum(isnull(hz.停工缓建剩余可售货值套数,0)) as 停工缓建剩余可售货值套数 ,          
sum(isnull(hz.工程达到可售未拿证货值套数,0)) as 工程达到可售未拿证货值套数 ,      
sum(isnull(hz.停工缓建工程达到可售未拿证货值套数,0)) as 停工缓建工程达到可售未拿证货值套数 , 
sum(isnull(hz.获证未推货值套数,0)) as 获证未推货值套数 ,   
sum(isnull(hz.停工缓建获证未推货值套数,0)) as 停工缓建获证未推货值套数 ,      
sum(isnull(hz.已推未售货值套数,0)) as 已推未售货值套数, 
sum(isnull(hz.停工缓建已推未售货值套数,0)) as 停工缓建已推未售货值套数    
from #baseinfo hz
inner join [172.16.4.161].highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_Organization bi on hz.组织架构id = bi.组织架构id
inner join [172.16.4.161].highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_Organization bi2 on bi.组织架构父级id = bi2.组织架构id
where hz.组织架构类型 = @baseinfo
group by  bi2.组织架构ID ,bi2.组织架构父级ID 
, bi2.组织架构名称 
, bi2.组织架构编码,
bi2.组织架构类型

set @baseinfo = @baseinfo - 1
END

select * from #baseinfo 

drop table #baseinfo 
