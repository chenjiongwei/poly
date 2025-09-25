
-- 停止触发器
ALTER TABLE p_provider DISABLE TRIGGER ALL;

-- 停止CT
ALTER TABLE p_provider disable CHANGE_TRACKING

-- 更新数据
UPDATE a
SET 
    a.TaxpayerIdentificationNumber = b.TaxpayerIdentificationNumber,
    a.WorkAddress = b.WorkAddress,
    a.CompanyTel = b.CompanyTel
FROM p_provider a
INNER JOIN p_ProviderOperLognew b ON a.providerguid = b.providerguid
WHERE b.OperDate = '2025-08-26 13:01:04.160'

-- 启用CT
ALTER TABLE p_provider ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON)