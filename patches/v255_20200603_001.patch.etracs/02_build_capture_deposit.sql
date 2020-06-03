-- 
-- build capture deposit transactions
-- 
create table ztmpdev_capture_deposit 
select distinct 
  concat('DEPCAP-', MD5(convert(cv.controldate, char(10)))) AS objid, 
  convert((concat(convert(cv.controldate, char(10)), ' 23:59:59')), datetime) as dtcreated, 
  cv.controldate, 'CAPTURE' as state, 'system' as createdby_objid, 'system' as createdby_title, 'system' as createdby_name 
from collectionvoucher cv 
where cv.depositvoucherid is null 
  and cv.controldate < '2020-05-01' 
order by cv.controldate 
;
alter table ztmpdev_capture_deposit add ( 
  controlno varchar(50) null, 
  amount decimal(16,4) not null default 0.0, 
  totalcash decimal(16,4) not null default 0.0, 
  totalcheck decimal(16,4) not null default 0.0, 
  totalcr decimal(16,4) not null default 0.0, 
  dtposted datetime null, 
  postedby_objid varchar(50) null, 
  postedby_name varchar(255) null 
)
;
alter table ztmpdev_capture_deposit modify objid varchar(50) not null 
;
alter table ztmpdev_capture_deposit add primary key (objid) 
;
update 
  ztmpdev_capture_deposit aa, ( 
    select t1.*, 
      concat('DEPCAP-CAP', repeat('0', 5-length(convert(t1.txncount+t1.rownum, char))), convert(t1.txncount+t1.rownum, char)) as controlno 
    from ( 
      select z.objid, z.controldate, (@rownum:=@rownum+1) as rownum, 
          (select count(*) from depositvoucher where controlno like 'DEPCAP-%') as txncount 
      from ztmpdev_capture_deposit z, (select @rownum:=0)rn  
    )t1 
  )bb 
set aa.controlno = rtrim(bb.controlno) 
where aa.objid = bb.objid 
;
create table ztmpdev_capture_deposit_liquidation 
select cv.objid, z.objid as depositvoucherid 
from ztmpdev_capture_deposit z 
  inner join collectionvoucher cv on cv.controldate = z.controldate 
where cv.depositvoucherid is null 
;
create table ztmpdev_capture_depositfund 
select 
  concat(z.objid, '|', fund.objid) as objid, z.objid as parentid, 
  'CAPTURE' as state, fund.objid as fundid, 
  sum(cvf.amount) as amount, sum(cvf.amount) as amountdeposited, 
  0.0 as totaldr, 0.0 as totalcr 
from ztmpdev_capture_deposit z 
  inner join ztmpdev_capture_deposit_liquidation lr on lr.depositvoucherid = z.objid 
  inner join collectionvoucher cv on cv.objid = lr.objid 
  inner join collectionvoucher_fund cvf on cvf.parentid = cv.objid 
  inner join fund on fund.objid = cvf.fund_objid 
where cv.depositvoucherid is null 
group by 
  concat(z.objid, '|', fund.objid), z.objid, fund.objid 
;
insert into depositvoucher (
  objid, state, controlno, controldate, amount, 
  dtcreated, createdby_objid, createdby_name, 
  dtposted, postedby_objid, postedby_name 
) 
select 
  objid, state, controlno, controldate, amount, 
  dtcreated, createdby_objid, createdby_name, 
  dtcreated, createdby_objid, createdby_name  
from ztmpdev_capture_deposit 
;
insert into depositvoucher_fund (
  objid, state, parentid, fundid, amount, amountdeposited, totaldr, totalcr 
) 
select  
  objid, state, parentid, fundid, amount, amountdeposited, totaldr, totalcr 
from ztmpdev_capture_depositfund 
;
update collectionvoucher aa, ztmpdev_capture_deposit_liquidation bb 
set aa.depositvoucherid = bb.depositvoucherid 
where aa.objid = bb.objid 
;
drop table if exists ztmpdev_capture_depositfund
;
drop table if exists ztmpdev_capture_deposit_liquidation
;
drop table if exists ztmpdev_capture_deposit 
;
