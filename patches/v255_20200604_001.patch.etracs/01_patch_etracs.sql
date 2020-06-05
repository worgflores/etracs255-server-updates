
alter table checkpayment add constraint fk_checkpayment_bankid 
  foreign key (bankid) references bank (objid) 
;

alter table checkpayment_deadchecks add constraint fk_checkpayment_deadchecks_bankid 
  foreign key (bankid) references bank (objid) 
;

