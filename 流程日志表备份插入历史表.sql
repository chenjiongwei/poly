-- 开启事件调度器（只需执行一次，或在配置文件中设置）
SET GLOBAL event_scheduler = ON;

-- 如果流程日志历史表不存在，则基于主表结构创建
CREATE TABLE IF NOT EXISTS wf_process_op_log_his LIKE wf_process_op_log;

-- 创建定时事件，每天凌晨2点执行，先备份再清理
DELIMITER $$

CREATE EVENT IF NOT EXISTS backup_and_clear_wf_process_op_log
ON SCHEDULE EVERY 1 DAY
STARTS DATE_ADD(CURDATE(), INTERVAL 2 HOUR)
DO
BEGIN
  -- 将wf_process_op_log的数据插入到wf_process_op_log_his表
  INSERT INTO wf_process_op_log_his
  SELECT * FROM wf_process_op_log;
  -- 删除wf_process_op_log表的数据
  DELETE FROM wf_process_op_log;
END$$

DELIMITER ;