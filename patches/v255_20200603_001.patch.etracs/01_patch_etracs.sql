
-- 
-- fixed bankaccount to mapped with cash-in-bank item account 
-- 
insert into itemaccount ( 
  objid, state, code, title, description, type, 
  fund_objid, fund_code, fund_title, defaultvalue, valuetype, 
  generic, sortorder, hidefromlookup 
) 
select * 
from ( 
  select 
    concat('CIB-', fund.objid) as objid, 'ACTIVE' as state, '-' as code, 
    concat('CASH IN BANK - ', fund.title) as title, null as description, 'CASH_IN_BANK' as type, 
    fund.objid as fund_objid, fund.code as fund_code, fund.title as fund_title, 
    0.0 as defaultvalue, 'ANY' as valuetype, 0 as generic, 0 as sortorder, 0 as hidefromlookup
  from ( select distinct depositoryfundid as fundid from fund )t1 
    inner join fund on fund.objid = t1.fundid 
)t1 
where t1.objid not in (select objid from itemaccount where objid = t1.objid) 
; 

update 
  bankaccount aa, ( 
    select 
      ba.objid, ba.fund_objid, ba.acctid, 
      (select objid from itemaccount where type = 'CASH_IN_BANK' and fund_objid = ba.fund_objid limit 1) as newacctid 
    from bankaccount ba 
    where ba.acctid is null 
  )bb 
set aa.acctid = bb.newacctid 
where aa.objid = bb.objid 
  and bb.newacctid is not null 
;

update 
  bankaccount aa, ( 
    select 
      ba.objid, ba.fund_objid, ba.acctid, 
      (select objid from itemaccount where type = 'CASH_IN_BANK' and objid = concat('CIB-', ba.fund_objid)) as newacctid 
    from bankaccount ba 
    where ba.acctid is null 
  )bb 
set aa.acctid = bb.newacctid 
where aa.objid = bb.objid 
  and bb.newacctid is not null 
;


-- 
-- forcely POST depositvoucher transactions dated before June-01-2020
-- 
update 
  depositvoucher aa, ( 
    select 
      objid, 'POSTED' as state, 'system' as postedby_objid, 
      'system' as postedby_name, now() as dtposted  
    from depositvoucher 
    where controldate <= '2020-06-01' 
      and state = 'OPEN' 
  )bb 
set 
  aa.state = bb.state, 
  aa.dtposted = bb.dtposted, 
  aa.postedby_objid = bb.postedby_objid, 
  aa.postedby_name = bb.postedby_name 
where aa.objid = bb.objid 
; 
