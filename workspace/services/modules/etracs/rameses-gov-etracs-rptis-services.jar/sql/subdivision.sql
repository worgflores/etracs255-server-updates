[getNodes]
select n.name, n.title as caption
from sys_wf_node n
where n.processname = 'subdivision'
and n.name not like 'assign%'
and n.name not in ('start', 'provapprover')
and n.name not like 'for%'
and exists(select * from sys_wf_transition where processname='subdivision' and parentid = n.name)
order by n.idx


[getList]
SELECT 
	s.*,
	(select trackingno from rpttracking where objid = s.objid) as trackingno,
	tsk.objid AS taskid,
	tsk.state AS taskstate,
	tsk.assignee_objid 
FROM subdivision s
	LEFT JOIN subdivision_task tsk ON s.objid = tsk.refid AND tsk.enddate IS NULL
WHERE s.lguid LIKE $P{lguid} 
   and s.state LIKE $P{state}
   and s.objid in (
   		select objid from subdivision where txnno LIKE $P{searchtext}
   		union
   		select objid from subdivision where mothertdnos LIKE $P{searchtext}
   		union 
   		select objid from subdivision where motherpins LIKE $P{searchtext}
   		union 
   		select s.objid from subdivision s, rpttracking t where s.objid = t.objid and t.trackingno like $P{searchtext}
   	)
   ${filters}
order by s.txnno desc 	


[findSubdivisionById]
SELECT s.*,
	tsk.objid AS taskid,
	tsk.state AS taskstate,
	tsk.assignee_objid 
FROM subdivision s
	LEFT JOIN subdivision_task tsk ON s.objid = tsk.refid AND tsk.enddate IS NULL
WHERE s.objid = $P{objid}	


[deletePreviousFaas]
DELETE FROM previousfaas WHERE faasid = $P{faasid}

[deleteFaas]
DELETE FROM faas WHERE objid = $P{objid}


[deleteTasks]
DELETE FROM subdivision_task WHERE refid = $P{objid}

[deleteSubdividedLandFaasTasks]
delete from faas_task 
where refid in (
	select newfaasid from subdividedland where subdivisionid = $P{objid}
)

[deleteAffectedRpuFaasTasks]
delete from faas_task 
where refid in (
	select newfaasid from subdivisionaffectedrpu where subdivisionid = $P{objid}
)


[getSubdividedLands]
SELECT sl.*
FROM subdividedland sl
WHERE sl.subdivisionid = $P{subdivisionid}
ORDER BY sl.newpin 
	

[getApprovedLandFaases]	
select f.objid, f.tdno, f.dtapproved 
from faas f 
inner join subdividedland sl on f.objid = sl.newfaasid 
where sl.subdivisionid = $P{objid}


[getAffectedRpus]
SELECT 
	sar.*, 
	f.owner_name, 
	f.owner_address,
	f.state AS prevstate,
	f.owner_name,
	f.owner_address,
	f.lguid 
FROM subdivisionaffectedrpu sar 
	left join faas f on sar.prevfaasid = f.objid 
WHERE sar.subdivisionid = $P{subdivisionid}	
ORDER BY sar.prevpin



[getAffectedRpusForCreate]
select distinct 
	f.objid AS objid,
	f.state, 
	f.tdno as prevtdno,
	f.fullpin as prevpin,
	$P{subdivisionid} AS subdivisionid,
	f.objid AS prevfaasid,
	r.objid AS prevrpuid, 
	r.rputype,
	rl.state AS ledgerstate
from faas mf 
	inner join realproperty mrp on mf.realpropertyid = mrp.objid,
	faas f 
	inner join realproperty rp on f.realpropertyid = rp.objid 
	inner join rpu r on f.rpuid = r.objid
	LEFT JOIN rptledger rl ON f.objid = rl.faasid 
where mf.realpropertyid = $P{realpropertyid}
and mrp.pin = rp.pin 
and r.rputype <> 'land' 
AND f.state NOT IN ('CANCELLED', 'PENDING')
  AND NOT EXISTS(SELECT * FROM subdivisionaffectedrpu WHERE prevfaasid = f.objid )
  AND NOT EXISTS(SELECT * FROM subdivision_cancelledimprovement WHERE faasid = f.objid )
ORDER BY r.rputype 


  
[clearAffectedRpuNewFaasId]
UPDATE subdivisionaffectedrpu SET newfaasid = null WHERE objid = $P{objid}

[clearSubdividedLandNewFaasId]
UPDATE subdividedland SET newfaasid = null WHERE objid = $P{objid}


[deleteAffectedRpuByPrevFaasId]
DELETE FROM subdivisionaffectedrpu WHERE prevfaasid = $P{prevfaasid}


[updateAffectedRpuRealPropertyId]
UPDATE rpu SET realpropertyid = $P{realpropertyid} WHERE objid = $P{rpuid}



#--------------------------------------------------------------------------------------------------
#
# APPROVED SUPPORT
#
#--------------------------------------------------------------------------------------------------
[approveSubdivision]
UPDATE subdivision SET state = 'APPROVED' WHERE objid = $P{objid}

[submitToProvince]
UPDATE subdivision SET state = 'FORAPPROVAL' WHERE objid = $P{objid}

[cancelRealProperty]
UPDATE realproperty SET state = 'CANCELLED' WHERE objid = $P{objid}

[cancelMotherLandLedger]
UPDATE rptledger SET state = 'CANCELLED' WHERE faasid = $P{faasid}



[updateSubdividedLandNewTdNo]
UPDATE sl SET
	sl.newtdno =	f.tdno 	
FROM subdividedland sl
	inner join faas f on sl.newfaasid = f.objid  
where subdivisionid = $P{subdivisionid}


[updateAffectedRpuNewTdNo]
UPDATE srpu SET
	srpu.newtdno =	f.tdno 	
FROM subdivisionaffectedrpu srpu
	inner join faas f on srpu.newfaasid = f.objid  
where subdivisionid = $P{subdivisionid}


[updateRpuFullPin]
UPDATE rpu SET fullpin = $P{fullpin} WHERE objid = $P{objid}





#===============================================================
#
#  ASYNCHRONOUS APPROVAL SUPPORT 
#
#================================================================

[findFaasById]
SELECT 
	f.objid AS newfaasid, 
	f.state,
	f.tdno, 
	f.utdno, 
	r.ry AS rpu_ry, 
	rp.barangayid AS rp_barangay_objid
FROM faas f 
	inner join rpu r on f.rpuid = r.objid 
	INNER JOIN realproperty rp ON f.realpropertyid = rp.objid 
WHERE f.objid =  $P{newfaasid}	


[updateFaasNewTdNo]
UPDATE faas SET 
	tdno = $P{newtdno}, utdno = $P{newtdno}
WHERE objid = $P{newfaasid}	


[updateAffectedNewTdNo]
UPDATE subdivisionaffectedrpu SET 
	newtdno = $P{newtdno}, newutdno = $P{newutdno}
WHERE objid =$P{objid}	





[getAffectedRpuWithNoPin]
SELECT sr.newpin, sr.newsuffix, pf.tdno
FROM subdivisionaffectedrpu sr
	inner JOIN faas pf ON sr.prevfaasid = pf.objid 
WHERE sr.subdivisionid = $P{objid}	
and sr.newfaasid is null 


[clearAffectedNewRpuRealPropertyId]
UPDATE rpu r, subdivisionaffectedrpu sr SET 
	r.realpropertyid = null 
 WHERE sr.newrpuid = r.objid  
   AND sr.subdividedlandid = $P{objid}


[clearAffectedRpuNewRealPropertyInfo]
UPDATE subdivisionaffectedrpu SET subdividedlandid = null, newrpid = null, newpin = null WHERE subdividedlandid = $P{objid}



[getFaasListing]
SELECT 
	f.objid, 
	CASE WHEN f.tdno IS NULL THEN f.utdno ELSE f.tdno END AS tdno, 
	r.rputype,
	r.fullpin 
FROM faas f 
	INNER JOIN rpu r ON f.rpuid = r.objid 
WHERE f.objid in (	
	SELECT sl.newfaasid
	FROM subdivision s
		INNER JOIN subdividedland sl ON s.objid = sl.subdivisionid
	WHERE s.objid = $P{objid}

	UNION ALL

	SELECT arpu.newfaasid
	FROM subdivision s
		INNER JOIN subdivisionaffectedrpu arpu ON s.objid = arpu.subdivisionid
	WHERE s.objid = $P{objid}
)
ORDER BY f.tdno 


[getMotherLands]
SELECT cl.*,
	cl.rpid as realpropertyid, 
	f.objid as faasid, 
	f.tdno,
	f.taxpayer_objid, 
	f.owner_name,
	f.owner_address,
	f.administrator_name,
	f.administrator_address,
	r.fullpin,
	r.totalmv,
	r.totalav,
	r.totalareaha,
	r.totalareasqm,
	rp.barangayid,
	rp.lguid,
	rp.lgutype,
	f.effectivityyear
FROM subdivision_motherland cl
	INNER JOIN faas f ON cl.landfaasid = f.objid 
	INNER JOIN rpu r ON f.rpuid = r.objid 
	INNER JOIN realproperty rp ON f.realpropertyid = rp.objid 
WHERE cl.subdivisionid = $P{objid }
ORDER BY f.tdno 





[getSignatories]
SELECT state AS type, max(enddate) AS assignee_dtsigned, actor_name as assignee_name, actor_title as assignee_title 
FROM subdivision_task 
WHERE refid = $P{objid}
  AND actor_name IS NOT NULL
GROUP BY state, actor_name, actor_title



[deleteTasks]
DELETE FROM subdivision_task WHERE refid = $P{objid}

[insertTask]
INSERT INTO subdivision_task 
	(objid, refid, state, startdate, enddate, assignee_objid, assignee_name, assignee_title)
VALUES 
	($P{objid}, $P{refid}, $P{state}, $P{startdate}, $P{enddate}, 
		$P{assigneeid}, $P{assigneename}, $P{assigneetitle})	



[getSubdividedLandsForApproval]
SELECT sl.*
FROM subdivision s 
	INNER JOIN subdividedland sl ON s.objid = sl.subdivisionid 
	INNER JOIN faas f ON sl.newfaasid = f.objid 
WHERE s.objid = $P{subdivisionid}
  AND s.state IN ('DRAFT','FORAPPROVAL')
  AND f.state = 'PENDING' 


[getAffectedRpusForApproval]
SELECT ar.*
FROM subdivision s 
	INNER JOIN subdivisionaffectedrpu ar ON s.objid = ar.subdivisionid 
	INNER JOIN faas f ON ar.newfaasid = f.objid 
WHERE s.objid = $P{subdivisionid}
  AND s.state IN ('DRAFT','FORAPPROVAL')
  AND f.state = 'PENDING' 



[findState]
SELECT state FROM subdivision WHERE objid = $P{objid}



[cancelSubledger]
UPDATE rptledger SET 
	state = 'CANCELLED' 
WHERE faasid = $P{faasid}

[getSubledgersForCancellation]
SELECT rls.faasid 
FROM rptledger_subledger rs
	INNER JOIN rptledger rl ON rs.parent_objid = rl.objid 
	INNER JOIN rptledger rls ON rs.objid = rls.objid 
WHERE rl.faasid = $P{faasid}



[insertSubdividedLandFaasSignatories]
INSERT INTO faas_task 
     (objid, refid, parentprocessid, state, startdate, enddate, 
      assignee_objid, assignee_name, assignee_title, 
      actor_objid, actor_name, actor_title, message, signature) 
select
    concat(st.objid, f.utdno) as objid, 
    sl.newfaasid, 
    st.parentprocessid, 
    st.state, 
    st.startdate, 
    st.enddate, 
    st.assignee_objid, 
    st.assignee_name, 
    st.assignee_title, 
    st.actor_objid, 
    st.actor_name, 
    st.actor_title, 
    st.message, 
    st.signature
from subdivision s
    inner join subdividedland sl on s.objid = sl.subdivisionid
	inner join faas f on sl.newfaasid = f.objid 
    inner join subdivision_task st on s.objid = st.refid 
where s.objid = $P{objid}
  and st.state not like 'assign%'
  and not exists(select * from faas_task where objid = concat(st.objid, f.utdno))


[insertAffectedRpuSignatories]
INSERT INTO faas_task 
     (objid, refid, parentprocessid, state, startdate, enddate, 
      assignee_objid, assignee_name, assignee_title, 
      actor_objid, actor_name, actor_title, message, signature) 
select
    concat(st.objid, f.utdno) as objid, 
    sl.newfaasid, 
    st.parentprocessid, 
    st.state, 
    st.startdate, 
    st.enddate, 
    st.assignee_objid, 
    st.assignee_name, 
    st.assignee_title, 
    st.actor_objid, 
    st.actor_name, 
    st.actor_title, 
    st.message, 
    st.signature
from subdivision s
    inner join subdivisionaffectedrpu sl on s.objid = sl.subdivisionid
    inner join faas f on sl.newfaasid = f.objid 
    inner join subdivision_task st on s.objid = st.refid 
where s.objid = $P{objid}
  and st.state not like 'assign%'
  and not exists(select * from faas_task where objid = concat(st.objid, f.utdno))


[getSubdividedLandInfoForValidation]
select 
	sl.newpin, 
	f.tdno,
	f.memoranda,
	r.totalareasqm,
	(select count(*) from landdetail where landrpuid = f.rpuid) as ldcount
from subdividedland sl 
	inner join faas f on sl.newfaasid = f.objid 
	inner join rpu r on f.rpuid = r.objid 
where sl.subdivisionid = $P{objid}


[getTasks]
select * from subdivision_task 
where refid = $P{objid}
and enddate is not null 


[findLandRpuBySubdividedLandId]
select newrpuid as landrpuid, newrpid as landrpid 
from subdividedland 
where objid = $P{subdividedlandid}




[findPendingSubdividedLandCount]
select count(*) as icount 
from subdividedland sl 
	inner join faas f on sl.newfaasid = f.objid 
where sl.subdivisionid = $P{objid}
and f.state = 'PENDING'


[findPendingAffectedRpuCount]
select count(*) AS icount 
from subdivisionaffectedrpu arpu
	inner join faas f on arpu.newfaasid = f.objid 
where arpu.subdivisionid = $P{objid}
and f.state = 'PENDING'


[deleteMotherLands]
delete from subdivision_motherland where subdivisionid = $P{objid}


[deleteMotherLandAffectedRpus]
delete from subdivisionaffectedrpu where prevfaasid = $P{landfaasid}


[updateSubdivisionByMotherLand]	
update subdivision set lguid = $P{lguid} where objid = $P{subdivisionid}


[updateSubdividedLandFaasTxnType]
update subdivision s, subdivision_motherland ml, faas mf, subdividedland sl, faas slf set 
	slf.txntype_objid = 'TR'
where s.objid = $P{objid}
 and s.objid = ml.subdivisionid
 and ml.landfaasid = mf.objid 
 and s.objid = sl.subdivisionid
 and sl.newfaasid = slf.objid 
 and mf.taxpayer_objid <> slf.taxpayer_objid 


[updateMotherLandsTxnType]
update subdivision_motherland ml, faas f set 
	f.txntype_objid = 'SD'
where ml.subdivisionid = $P{objid}
  and ml.landfaasid = f.objid 

  
[updateMotherLandsInfo]  
update subdivision set 
	mothertdnos = $P{mothertdnos},
	motherpins = $P{motherpins}
where objid = $P{objid}	


[findOpenTask]  
select * from subdivision_task where refid = $P{objid} and enddate is null


[findOpenTaskFromFaas]
select * from subdivision_task 
where refid in (
	select subdivisionid from subdividedland where newfaasid = $P{objid}
	union 
	select subdivisionid from subdivisionaffectedrpu where newfaasid = $P{objid}
)
and enddate is null



#--------------------------------------------------
# CANCELLED IMPROVEMENT SUPPORT 
#-------------------------------------------------

[getCancelledImprovements]
select cf.*, r.rputype, f.tdno, f.fullpin, f.owner_name, cr.name as reason_name
from subdivision_cancelledimprovement cf 
	inner join faas f on cf.faasid = f.objid 
	inner join rpu r on f.rpuid = r.objid 
	inner join realproperty rp on f.realpropertyid = rp.objid 
	inner join canceltdreason cr on cf.reason_objid = cr.objid 
where cf.parentid = $P{objid}
order by rp.pin, r.suffix 



[deleteAffectedRpu]
delete from subdivisionaffectedrpu where objid = $P{objid}


[findAffectedRpuById]	
SELECT 
	f.objid AS objid,
	f.state, 
	f.tdno as prevtdno,
	f.fullpin as prevpin,
	$P{parentid} AS subdivisionid,
	f.objid AS prevfaasid,
	r.objid AS prevrpuid, 
	r.rputype,
	rl.state AS ledgerstate
FROM faas f
	INNER JOIN rpu r ON f.rpuid = r.objid 
	LEFT JOIN rptledger rl ON f.objid = rl.faasid 
WHERE f.objid = $P{faasid}